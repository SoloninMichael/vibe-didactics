import VibieKit
import Foundation
import Network

/// `vibie hook`: Claude Code runs this for each hook event and reads our stdout.
///
/// If the bridge isn't running, no phone is connected, or nobody decides in time,
/// we print nothing, so Claude Code falls back to its normal terminal prompt.
/// We never approve anything on our own.
enum HookCommand {
    static func run(agent: AgentKind, timeout: TimeInterval, controlPort: UInt16) -> Never {
        let input = FileHandle.standardInput.readDataToEndOfFile()
        guard let json = try? JSONSerialization.jsonObject(with: input) as? [String: Any] else { exit(0) }
        if let output = process(json, agent: agent, timeout: timeout, controlPort: controlPort) {
            print(output)
        }
        exit(0)
    }

    static func process(_ json: [String: Any], agent: AgentKind, timeout: TimeInterval, controlPort: UInt16) -> String? {
        guard let token = BridgeHome().existingControlToken() else { return nil }
        let event = json["hook_event_name"] as? String ?? ""

        switch event {
        case "PreToolUse":
            if json["tool_name"] as? String == "Bash",
               let command = (json["tool_input"] as? [String: Any])?["command"] as? String,
               ReadOnlyCommand.matches(command) {
                return nil // Looking around isn't worth a reel.
            }
            guard let card = CardBuilder.card(fromHook: json, agent: agent),
                  case .decision(let decision)? = ControlClient.exchange(.awaitDecision(token: token, card: card), port: controlPort, timeout: timeout)
            else { return nil }

            let approved = decision.verdict == .approve
            let reason: String
            if approved {
                reason = "Approved on iPhone via Vibie."
            } else if let note = decision.note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
                reason = "The user reviewed this on their phone and denied it, saying: \(note)"
            } else {
                reason = "The user reviewed this on their phone and denied it. Don't retry the same change; try a different approach or ask what they'd prefer."
            }
            return jsonString([
                "hookSpecificOutput": [
                    "hookEventName": "PreToolUse",
                    "permissionDecision": approved ? "allow" : "deny",
                    "permissionDecisionReason": reason,
                ]
            ])

        case "Stop":
            let card = CardBuilder.checkpoint(fromHook: json, agent: agent)
            let reply = ControlClient.exchange(.awaitDecision(token: token, card: card), port: controlPort, timeout: timeout)
            if case .decision(let decision)? = reply, decision.verdict == .approve,
               let note = decision.note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
                // Blocking the stop hands the user's follow-up straight back to the agent.
                return jsonString(["decision": "block", "reason": "The user sent a follow-up from their phone: \(note)"])
            }
            let idle = AgentStatus(state: .idle, detail: "Finished — waiting for your next idea", project: card.project, agent: agent)
            _ = ControlClient.exchange(.status(token: token, status: idle), port: controlPort, timeout: 2, expectReply: false)
            return nil

        default:
            if let status = StatusBuilder.status(fromHook: json, agent: agent) {
                _ = ControlClient.exchange(.status(token: token, status: status), port: controlPort, timeout: 2, expectReply: false)
            }
            return nil
        }
    }

    private static func jsonString(_ object: [String: Any]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]) else { return nil }
        return String(decoding: data, as: UTF8.self)
    }
}

private final class ReplyBox: @unchecked Sendable {
    var value: ControlMessage?
}

enum ControlClient {
    /// One request over 127.0.0.1, blocking until a reply, close, or timeout.
    static func exchange(_ message: ControlMessage, port: UInt16, timeout: TimeInterval, expectReply: Bool = true) -> ControlMessage? {
        guard let payload = try? WireCoding.encode(message), let nwPort = NWEndpoint.Port(rawValue: port) else { return nil }
        let queue = DispatchQueue(label: "vibie.hook")
        let frames = FrameConnection(connection: NWConnection(host: .ipv4(.loopback), port: nwPort, using: .tcp), queue: queue)
        let done = DispatchSemaphore(value: 0)
        let reply = ReplyBox()

        frames.onReady = {
            frames.send(payload) { if !expectReply { done.signal() } }
        }
        frames.onFrame = { data in
            reply.value = try? WireCoding.decode(ControlMessage.self, from: data)
            done.signal()
        }
        frames.onClose = { _ in done.signal() }
        frames.start()

        _ = done.wait(timeout: .now() + timeout)
        return queue.sync {
            frames.close()
            return reply.value
        }
    }
}

enum ReadOnlyCommand {
    private static let safe: Set<String> = [
        "ls", "cat", "pwd", "head", "tail", "wc", "grep", "rg", "which", "tree", "stat", "file", "du", "df", "echo", "find",
    ]
    private static let safeGit: Set<String> = ["status", "diff", "log", "show", "rev-parse", "ls-files", "blame"]

    static func matches(_ command: String) -> Bool {
        let trimmed = command.trimmingCharacters(in: .whitespaces)
        guard trimmed.rangeOfCharacter(from: CharacterSet(charactersIn: ";&|><`$\n")) == nil else { return false }
        let parts = trimmed.split(separator: " ").map(String.init)
        guard let first = parts.first else { return false }
        if first == "git" { return safeGit.contains(parts.dropFirst().first ?? "") }
        if first == "find" { return !parts.contains { ["-delete", "-exec", "-execdir", "-ok", "-fprint", "-fls"].contains($0) } }
        return safe.contains(first)
    }
}

enum StatusBuilder {
    static func status(fromHook json: [String: Any], agent: AgentKind) -> AgentStatus? {
        let cwd = json["cwd"] as? String ?? FileManager.default.currentDirectoryPath
        let project = CardBuilder.projectName(cwd)
        switch json["hook_event_name"] as? String {
        case "PostToolUse":
            let input = json["tool_input"] as? [String: Any] ?? [:]
            return AgentStatus(state: .working, detail: describe(tool: json["tool_name"] as? String ?? "", input: input), project: project, agent: agent)
        case "UserPromptSubmit":
            return AgentStatus(state: .working, detail: "Starting on your request", project: project, agent: agent)
        case "Notification":
            let message = Redactor.redact(json["message"] as? String ?? "Needs your attention").text
            return AgentStatus(state: .waiting, detail: message, project: project, agent: agent)
        case "SessionStart":
            return AgentStatus(state: .idle, detail: "Session started", project: project, agent: agent)
        default:
            return nil
        }
    }

    private static func describe(tool: String, input: [String: Any]) -> String {
        let file = (input["file_path"] as? String).map { ($0 as NSString).lastPathComponent }
        switch tool {
        case "Read": return "Reading \(file ?? "a file")"
        case "Edit", "MultiEdit", "Write", "NotebookEdit": return "Edited \(file ?? "a file")"
        case "Grep", "Glob": return "Searching the codebase"
        case "Bash":
            let command = Redactor.redact(input["command"] as? String ?? "").text
            return "Ran `\(command.prefix(40))`"
        case "WebFetch", "WebSearch": return "Researching on the web"
        case "Task", "Agent": return "Delegating to a helper agent"
        case "TodoWrite": return "Updating its plan"
        default: return "Used \(tool)"
        }
    }
}
