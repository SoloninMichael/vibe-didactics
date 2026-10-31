import VibieKit
import Foundation

/// Sends a pretend hook event through the real pipeline, so you can try the
/// phone flow without running an agent.
enum Simulate {
    static func run(kind: String, controlPort: UInt16) {
        let workspace = FileManager.default.temporaryDirectory.appendingPathComponent("vibie-demo-app", isDirectory: true)
        try? FileManager.default.createDirectory(at: workspace.appendingPathComponent("src"), withIntermediateDirectories: true)
        let file = workspace.appendingPathComponent("src/greeting.ts")
        try? """
        import { formatName } from "./names";

        export function greet(name: string) {
          return "Hello, " + formatName(name);
        }
        """.write(to: file, atomically: true, encoding: .utf8)

        let payload: [String: Any]
        switch kind {
        case "bash":
            payload = [
                "hook_event_name": "PreToolUse",
                "cwd": workspace.path,
                "tool_name": "Bash",
                "tool_input": ["command": "npm install canvas-confetti@1.9.3", "description": "Install a tiny confetti library for the success screen"],
                "transcript_path": transcript(in: workspace, text: "To celebrate when someone finishes onboarding, I'll add a small confetti library. It has no other dependencies."),
            ]
        case "stop":
            payload = [
                "hook_event_name": "Stop",
                "cwd": workspace.path,
                "transcript_path": transcript(in: workspace, text: "Done! The greeting now gets excited on request, and I added a test for both cases. Want me to wire it into the welcome screen next?"),
            ]
        default:
            payload = [
                "hook_event_name": "PreToolUse",
                "cwd": workspace.path,
                "tool_name": "Edit",
                "tool_input": [
                    "file_path": file.path,
                    "old_string": "export function greet(name: string) {\n  return \"Hello, \" + formatName(name);\n}",
                    "new_string": "export function greet(name: string, excited = false) {\n  const greeting = `Hello, ${formatName(name)}`;\n  return excited ? `${greeting}!` : greeting;\n}",
                ],
                "transcript_path": transcript(in: workspace, text: "I'll let greet() optionally sound excited, and switch to a template string so it's easier to read."),
            ]
        }

        Console.log(Console.magenta("→"), "Sent a pretend \(kind) to your phone. Decide there…")
        let output = HookCommand.process(payload, agent: .claudeCode, timeout: 300, controlPort: controlPort)
        if let output {
            Console.success("The agent would receive:\n\(output)")
        } else {
            Console.warn("No decision came back (bridge not running, no phone connected, or timed out). Claude Code would ask in the terminal instead.")
        }
    }

    private static func transcript(in directory: URL, text: String) -> String {
        let url = directory.appendingPathComponent("transcript.jsonl")
        let entries: [[String: Any]] = [
            ["type": "user", "message": ["role": "user", "content": "make the greeting nicer"]],
            ["type": "assistant", "message": ["role": "assistant", "content": [["type": "text", "text": text]]]],
        ]
        let lines = entries.compactMap { try? JSONSerialization.data(withJSONObject: $0) }.map { String(decoding: $0, as: UTF8.self) }
        try? lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        return url.path
    }
}
