import VibieKit
import Foundation

/// Turns a hook payload into a `ChangeCard`, computing the real diff against the file on disk
/// and scrubbing secrets before anything leaves the Mac.
enum CardBuilder {
    static func card(fromHook json: [String: Any], agent: AgentKind) -> ChangeCard? {
        let tool = json["tool_name"] as? String ?? "Tool"
        let input = json["tool_input"] as? [String: Any] ?? [:]
        let cwd = json["cwd"] as? String ?? FileManager.default.currentDirectoryPath
        let intent = (json["transcript_path"] as? String).flatMap(Transcript.latestAgentText)
        var card = ChangeCard(agent: agent, project: projectName(cwd), kind: .tool, tool: tool, agentIntent: intent)

        switch tool {
        case "Edit":
            guard let path = input["file_path"] as? String,
                  let old = input["old_string"] as? String,
                  let new = input["new_string"] as? String else { return nil }
            let all = input["replace_all"] as? Bool ?? false
            applyFileChange(to: &card, path: path, cwd: cwd, fragment: (old, new)) { content in
                guard content.contains(old) else { return nil }
                return all ? content.replacingOccurrences(of: old, with: new) : content.replacingFirst(old, with: new)
            }

        case "MultiEdit":
            guard let path = input["file_path"] as? String,
                  let edits = input["edits"] as? [[String: Any]] else { return nil }
            let pairs = edits.compactMap { edit -> (String, String, Bool)? in
                guard let old = edit["old_string"] as? String, let new = edit["new_string"] as? String else { return nil }
                return (old, new, edit["replace_all"] as? Bool ?? false)
            }
            let fragment = (pairs.map(\.0).joined(separator: "\n"), pairs.map(\.1).joined(separator: "\n"))
            applyFileChange(to: &card, path: path, cwd: cwd, fragment: fragment) { content in
                var text = content
                for (old, new, all) in pairs {
                    guard text.contains(old) else { return nil }
                    text = all ? text.replacingOccurrences(of: old, with: new) : text.replacingFirst(old, with: new)
                }
                return text
            }

        case "Write":
            guard let path = input["file_path"] as? String,
                  let content = input["content"] as? String else { return nil }
            applyFileChange(to: &card, path: path, cwd: cwd, fragment: ("", content)) { _ in content }

        case "NotebookEdit":
            guard let path = input["notebook_path"] as? String else { return nil }
            let source = input["new_source"] as? String ?? ""
            let result = LineDiff.diff(old: "", new: source)
            card.kind = .edit
            card.filePath = relativePath(path, cwd: cwd)
            card.language = "Notebook"
            card.lines = result.lines
            card.additions = result.additions

        case "Bash":
            guard let command = input["command"] as? String else { return nil }
            card.kind = .command
            card.command = command
            card.language = "Shell"
            if let description = input["description"] as? String, !description.isEmpty {
                card.agentIntent = [description, intent].compactMap { $0 }.joined(separator: "\n\n")
            }

        default:
            let pretty = (try? JSONSerialization.data(withJSONObject: input, options: [.prettyPrinted, .sortedKeys]))
                .map { String(decoding: $0, as: UTF8.self) } ?? ""
            let result = LineDiff.diff(old: "", new: pretty)
            card.lines = result.lines
            card.additions = result.additions
        }

        scrub(&card)
        return card
    }

    static func checkpoint(fromHook json: [String: Any], agent: AgentKind) -> ChangeCard {
        let cwd = json["cwd"] as? String ?? FileManager.default.currentDirectoryPath
        let summary = (json["transcript_path"] as? String).flatMap(Transcript.latestAgentText)
        var card = ChangeCard(agent: agent, project: projectName(cwd), kind: .checkpoint, tool: "Stop", agentIntent: summary)
        scrub(&card)
        return card
    }

    /// The git repository's folder name, or the working directory's.
    static func projectName(_ cwd: String) -> String {
        var url = URL(fileURLWithPath: cwd)
        while url.path != "/" {
            if FileManager.default.fileExists(atPath: url.appendingPathComponent(".git").path) {
                return url.lastPathComponent
            }
            url.deleteLastPathComponent()
        }
        return URL(fileURLWithPath: cwd).lastPathComponent
    }

    private static func applyFileChange(
        to card: inout ChangeCard,
        path: String,
        cwd: String,
        fragment: (old: String, new: String),
        apply: (String) -> String?
    ) {
        card.filePath = relativePath(path, cwd: cwd)
        card.language = Language.name(forPath: path)
        let existing = try? String(contentsOfFile: path, encoding: .utf8)
        card.kind = existing == nil && !FileManager.default.fileExists(atPath: path) ? .create : .edit

        let result: LineDiff.Result
        if let existing, let updated = apply(existing) {
            result = LineDiff.diff(old: existing, new: updated)
        } else {
            result = LineDiff.diff(old: fragment.old, new: fragment.new)
        }
        card.additions = result.additions
        card.deletions = result.deletions
        card.truncated = result.truncated

        if Redactor.isSensitivePath(path) {
            card.lines = [DiffLine(kind: .gap, text: "Contents hidden — this file can hold secrets, so it never leaves your Mac")]
            card.redactions += 1
        } else {
            card.lines = result.lines
        }
    }

    private static func scrub(_ card: inout ChangeCard) {
        var total = 0
        func clean(_ text: String) -> String {
            let (scrubbed, count) = Redactor.redact(text)
            total += count
            return scrubbed
        }
        card.agentIntent = card.agentIntent.map(clean)
        card.command = card.command.map(clean)
        card.lines = card.lines.map { line in
            var copy = line
            copy.text = clean(line.text)
            return copy
        }
        card.redactions += total
    }

    private static func relativePath(_ path: String, cwd: String) -> String {
        if path.hasPrefix(cwd + "/") { return String(path.dropFirst(cwd.count + 1)) }
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home + "/") { return "~/" + path.dropFirst(home.count + 1) }
        return path
    }
}

enum Transcript {
    /// The agent's most recent prose in this turn: usually it says what it's about to do and why.
    static func latestAgentText(at path: String) -> String? {
        guard let handle = FileHandle(forReadingAtPath: path) else { return nil }
        defer { try? handle.close() }
        let maxBytes: UInt64 = 512 * 1024
        let size = (try? handle.seekToEnd()) ?? 0
        try? handle.seek(toOffset: size > maxBytes ? size - maxBytes : 0)
        guard let data = try? handle.readToEnd() else { return nil }

        for line in String(decoding: data, as: UTF8.self).split(separator: "\n").reversed().prefix(400) {
            guard let entry = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any],
                  let message = entry["message"] as? [String: Any] else { continue }
            let type = entry["type"] as? String

            if type == "user" {
                // A typed prompt (not a tool result) marks the start of this turn.
                if message["content"] is String { return nil }
                if let blocks = message["content"] as? [[String: Any]], blocks.contains(where: { $0["type"] as? String == "text" }) { return nil }
                continue
            }
            guard type == "assistant", let blocks = message["content"] as? [[String: Any]] else { continue }
            let text = blocks
                .compactMap { $0["type"] as? String == "text" ? $0["text"] as? String : nil }
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { return String(text.prefix(1_200)) }
        }
        return nil
    }
}

extension String {
    func replacingFirst(_ target: String, with replacement: String) -> String {
        guard let range = range(of: target) else { return self }
        return replacingCharacters(in: range, with: replacement)
    }
}
