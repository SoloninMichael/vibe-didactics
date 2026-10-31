import VibieKit
import Foundation

/// Adds Vibie to Claude Code's hook settings, replacing any older Vibie entries.
enum InstallHooks {
    static func run(projectDirectory: String?, global: Bool, agent: AgentKind, checkpoints: Bool) throws {
        let settingsURL: URL
        if global {
            settingsURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude/settings.json")
        } else {
            let project = URL(fileURLWithPath: projectDirectory ?? FileManager.default.currentDirectoryPath).standardizedFileURL
            // settings.local.json is git-ignored by Claude Code, so your machine's path stays out of the repo.
            settingsURL = project.appendingPathComponent(".claude/settings.local.json")
        }

        let executable = Bundle.main.executablePath ?? CommandLine.arguments[0]
        let command = "\(shellQuoted(executable)) hook --agent \(agent.rawValue)"

        var root: [String: Any] = [:]
        if let data = try? Data(contentsOf: settingsURL) {
            guard let existing = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw CocoaError(.fileReadCorruptFile, userInfo: [NSFilePathErrorKey: settingsURL.path])
            }
            root = existing
        }
        var hooks = root["hooks"] as? [String: Any] ?? [:]

        func install(_ event: String, matcher: String?, timeout: Int) {
            var entries = hooks[event] as? [[String: Any]] ?? []
            entries.removeAll { entry in
                (entry["hooks"] as? [[String: Any]] ?? []).contains { ($0["command"] as? String)?.contains("vibie") == true }
            }
            var entry: [String: Any] = ["hooks": [["type": "command", "command": command, "timeout": timeout]]]
            if let matcher { entry["matcher"] = matcher }
            entries.append(entry)
            hooks[event] = entries
        }

        install("PreToolUse", matcher: "Edit|MultiEdit|Write|NotebookEdit|Bash", timeout: 600)
        install("PostToolUse", matcher: "*", timeout: 10)
        install("UserPromptSubmit", matcher: nil, timeout: 10)
        install("Notification", matcher: nil, timeout: 10)
        if checkpoints {
            install("Stop", matcher: nil, timeout: 600)
        }
        root["hooks"] = hooks

        try FileManager.default.createDirectory(at: settingsURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        try data.write(to: settingsURL, options: .atomic)

        Console.success("Vibie hooks installed in \(settingsURL.path)")
        print("""

          • Edits, new files and shell commands become reels on your phone to approve or deny.
          • Read-only commands (ls, cat, git status…) skip the phone.
          \(checkpoints ? "• When \(agent.displayName) finishes a turn, your phone can send it a follow-up." : "• Turn-end follow-ups are off (--no-checkpoints).")
          • If the bridge isn't running or your phone is away, \(agent.displayName) just asks in the terminal.

          Next: run `vibie serve` and keep it open while you work.
        """)
    }

    /// Double quotes survive paths like "/Volumes/Alex's Drive/…".
    private static func shellQuoted(_ path: String) -> String {
        var escaped = path
        for character in ["\\", "\"", "$", "`"] {
            escaped = escaped.replacingOccurrences(of: character, with: "\\" + character)
        }
        return "\"\(escaped)\""
    }
}
