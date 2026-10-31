import VibieKit
import Foundation

/// Instant, offline explainer built from the diff and the agent's own words.
/// Shown immediately; the on-device model upgrades it when Apple Intelligence is available.
enum QuickExplainer {
    static func make(for card: ChangeCard) -> Explainer {
        let (risk, watchOut) = assessRisk(card)
        let (headline, reason) = headlineAndReason(card)
        return Explainer(
            headline: headline,
            whatChanges: whatChanges(card),
            why: why(card, reason: reason),
            risk: risk,
            watchOut: watchOut,
            tags: tags(card))
    }

    // MARK: Headline

    private static func headlineAndReason(_ card: ChangeCard) -> (String, String?) {
        if card.kind == .checkpoint { return ("\(card.agent.shortName) finished a step", nil) }
        if let sentence = sentences(card.agentIntent).first {
            let (head, tail) = splitReason(thirdPerson(sentence))
            if head.split(separator: " ").count >= 2 { return (clip(head, words: 9), tail) }
        }
        switch card.kind {
        case .create: return ("Creates \(card.fileName ?? "a new file")", nil)
        case .edit: return ("Edits \(card.fileName ?? "a file")", nil)
        case .command: return ("Runs \(commandName(card.command))", nil)
        default: return ("Uses \(card.tool)", nil)
        }
    }

    private static let fillers = ["now ", "next, ", "next ", "first, ", "first ", "okay, ", "ok, ", "great! ", "great, ",
                                  "perfect! ", "perfect, ", "alright, ", "so ", "then ", "finally, ", "also, "]
    private static let leads = ["let me ", "i'll ", "i will ", "i'm going to ", "i am going to ", "i need to ", "let's ",
                                "we need to ", "we'll ", "i want to ", "going to ", "i should ", "i can ", "time to "]
    private static let verbs: [String: String] = [
        "add": "Adds", "update": "Updates", "fix": "Fixes", "create": "Creates", "remove": "Removes", "delete": "Deletes",
        "install": "Installs", "run": "Runs", "refactor": "Refactors", "implement": "Implements", "write": "Writes",
        "change": "Changes", "replace": "Replaces", "rename": "Renames", "move": "Moves", "set": "Sets", "make": "Makes",
        "wire": "Wires", "hook": "Hooks", "check": "Checks", "test": "Tests", "configure": "Configures", "build": "Builds",
        "improve": "Improves", "clean": "Cleans", "use": "Uses", "switch": "Switches", "extract": "Extracts", "edit": "Edits",
        "hash": "Hashes", "show": "Shows", "let": "Lets", "give": "Gives", "store": "Stores", "save": "Saves", "load": "Loads",
        "handle": "Handles", "convert": "Converts", "split": "Splits", "simplify": "Simplifies", "introduce": "Introduces",
        "enable": "Enables", "disable": "Disables", "upgrade": "Upgrades", "bump": "Bumps", "migrate": "Migrates",
        "start": "Starts", "stop": "Stops", "reset": "Resets", "wrap": "Wraps", "guard": "Guards", "protect": "Protects",
        "validate": "Validates", "format": "Formats", "style": "Styles", "polish": "Polishes", "tidy": "Tidies",
        "clear": "Clears", "generate": "Generates", "scaffold": "Scaffolds", "wipe": "Wipes", "count": "Counts",
        "keep": "Keeps", "put": "Puts", "pull": "Pulls", "push": "Pushes", "commit": "Commits", "deploy": "Deploys",
    ]

    static func thirdPerson(_ sentence: String) -> String {
        var text = sentence
        var stripped = true
        while stripped {
            stripped = false
            for prefix in fillers + leads where text.lowercased().hasPrefix(prefix) {
                text = String(text.dropFirst(prefix.count))
                stripped = true
            }
        }
        let parts = text.split(separator: " ", maxSplits: 1)
        guard let first = parts.first else { return text }
        if let verb = verbs[first.lowercased()] {
            return verb + (parts.count > 1 ? " " + parts[1] : "")
        }
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    /// "Hashes passwords with bcrypt so a leak doesn't expose them" → head + reason.
    private static func splitReason(_ sentence: String) -> (String, String?) {
        for marker in [" so that ", " so ", " because ", " to make sure ", " which ", ", "] {
            if let range = sentence.range(of: marker), sentence.distance(from: sentence.startIndex, to: range.lowerBound) > 12 {
                let tail = sentence[range.upperBound...].trimmingCharacters(in: .whitespaces)
                return (String(sentence[..<range.lowerBound]), tail.isEmpty ? nil : tail.prefix(1).uppercased() + tail.dropFirst() + ".")
            }
        }
        return (sentence, nil)
    }

    // MARK: Body

    private static func whatChanges(_ card: ChangeCard) -> String {
        let file = card.fileName ?? "a file"
        switch card.kind {
        case .create:
            return "Creates \(file), a brand-new \(card.language.map { $0 + " " } ?? "")file \(plural(card.additions, "line")) long."
        case .edit:
            if card.deletions == 0 { return "Adds \(plural(card.additions, "new line")) to \(file)." }
            if card.additions == 0 { return "Removes \(plural(card.deletions, "line")) from \(file)." }
            return "Rewrites \(plural(card.deletions, "line")) of \(file) into \(plural(card.additions, "new one"))."
        case .command:
            return "Runs a command in your project. \(CommandKind.classify(card.command ?? "").meaning)."
        case .checkpoint:
            let summary = sentences(card.agentIntent).prefix(2).joined(separator: " ")
            return summary.isEmpty ? "It's paused and waiting for your next instruction." : summary
        case .tool:
            return "Uses the \(card.tool) tool."
        }
    }

    private static func why(_ card: ChangeCard, reason: String?) -> String {
        if let reason { return reason }
        let all = sentences(card.agentIntent)
        if all.count > 1 { return all.dropFirst().prefix(2).joined(separator: " ") }
        if card.kind == .checkpoint { return "Nothing more happens until you reply." }
        return all.first.map { "In its words: \($0)." } ?? "The agent didn't say why — tap Ask to dig in."
    }

    // MARK: Risk

    static func assessRisk(_ card: ChangeCard) -> (RiskLevel, String) {
        switch card.kind {
        case .checkpoint:
            return (.low, "Nothing changes until you send the next instruction.")
        case .command:
            let command = (card.command ?? "").lowercased()
            if matches(command, #"\brm\s+-[a-z]*[rf]|\bsudo\b|\|\s*(ba|z)?sh\b|git\s+push\s+.*(-f\b|--force)|git\s+reset\s+--hard|drop\s+(table|database)|chmod\s+-r\s+777|\bmkfs\b|\bdd\s+if="#) {
                return (.high, "Destructive command — double-check exactly what it deletes or overwrites.")
            }
            switch CommandKind.classify(command) {
            case .install: return (.medium, "Adds third-party code to your project — make sure you recognise the package.")
            case .network: return (.medium, "Downloads from the internet — check you trust the source.")
            case .git where command.contains("push"): return (.medium, "Changes your remote repository, not just this Mac.")
            default:
                if matches(command, #"deploy|migrate|docker|kubectl|terraform"#) {
                    return (.medium, "Affects something outside this folder — like a server or database.")
                }
                return (.low, "Runs locally and doesn't look destructive.")
            }
        default:
            let path = (card.filePath ?? "").lowercased()
            if matches(path, #"(^|/)\.env|secret|credential|payment|billing|stripe|migration|\.sql$|\.github/workflows|dockerfile|terraform|infra/"#) {
                return (.high, "Touches secrets, money or stored data — read the code before approving.")
            }
            if matches(path, #"auth|login|session|password|signin|sign-in"#) {
                return (.medium, "Touches sign-in code — try logging in after this.")
            }
            if matches(path, #"token|security|middleware|permission|config|package\.json|podfile|package\.swift|requirements\.txt|gemfile|/api/"#) {
                return (.medium, "Touches shared plumbing — other parts of the app depend on it.")
            }
            if card.deletions > 40 || (card.deletions > 10 && card.deletions > card.additions * 2) {
                return (.medium, "Deletes more than it adds — check nothing important disappears.")
            }
            if card.additions + card.deletions > 150 {
                return (.medium, "A big change — worth opening the full code before approving.")
            }
            if matches(path, #"test|spec|\.md$|\.css$|\.scss$|readme|docs/"#) {
                return (.low, "Tests, docs or styling — low stakes.")
            }
            if card.kind == .create {
                return (.low, "A brand-new file — nothing existing changes until something uses it.")
            }
            return (.low, "A small, contained change.")
        }
    }

    // MARK: Tags

    private static let genericFolders: Set<String> = ["src", "app", "lib", "libs", "source", "sources", "components", "pages",
                                                      "public", "utils", "util", "index", "main", "internal", "pkg", "~", "."]

    private static func tags(_ card: ChangeCard) -> [String] {
        var tags: [String] = []
        func add(_ tag: String?) {
            guard let tag = tag?.lowercased().filter({ $0.isLetter || $0.isNumber || $0 == "-" }),
                  tag.count > 1, !tags.contains(tag), !genericFolders.contains(tag) else { return }
            tags.append(tag)
        }
        switch card.kind {
        case .command:
            add(CommandKind.classify(card.command ?? "").tag)
            add(card.command?.split(separator: " ").first.map(String.init))
        case .checkpoint:
            add("progress")
            add(card.project)
        default:
            if let path = card.filePath {
                let parts = path.split(separator: "/").map(String.init)
                parts.dropLast().reversed().forEach(add)
                add(((parts.last ?? "") as NSString).deletingPathExtension)
            }
            add(card.language)
        }
        return Array(tags.prefix(3))
    }

    // MARK: Helpers

    static func sentences(_ text: String?) -> [String] {
        guard let text = text?.replacingOccurrences(of: "**", with: "").replacingOccurrences(of: "`", with: ""),
              !text.isEmpty else { return [] }
        var result: [String] = []
        text.enumerateSubstrings(in: text.startIndex..., options: .bySentences) { substring, _, _, _ in
            guard let sentence = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !sentence.isEmpty else { return }
            result.append(sentence.trimmingCharacters(in: CharacterSet(charactersIn: ".!:")))
        }
        return result
    }

    private static func clip(_ text: String, words: Int) -> String {
        let parts = text.split(separator: " ")
        return parts.count <= words ? text : parts.prefix(words).joined(separator: " ") + "…"
    }

    private static func commandName(_ command: String?) -> String {
        let words = (command ?? "a command").split(separator: " ").prefix(2).joined(separator: " ")
        return words.isEmpty ? "a command" : words
    }

    private static func plural(_ count: Int, _ noun: String) -> String {
        count == 1 ? "1 \(noun)" : "\(count) \(noun)s"
    }

    static func matches(_ text: String, _ pattern: String) -> Bool {
        text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
}

enum CommandKind: CaseIterable {
    case delete, network, install, test, git, build, run, other

    var meaning: String {
        switch self {
        case .delete: "It deletes files"
        case .network: "It downloads something from the internet"
        case .install: "It installs packages"
        case .test: "It runs your tests"
        case .git: "It works with your git history"
        case .build: "It builds the project"
        case .run: "It starts the app or a server"
        case .other: "It runs a script"
        }
    }

    var tag: String {
        switch self {
        case .delete: "cleanup"
        case .network: "download"
        case .install: "dependencies"
        case .test: "tests"
        case .git: "git"
        case .build: "build"
        case .run: "run"
        case .other: "terminal"
        }
    }

    static func classify(_ command: String) -> CommandKind {
        let c = command.lowercased()
        let checks: [(CommandKind, String)] = [
            (.delete, #"\brm\b|\brmdir\b|git\s+clean"#),
            (.network, #"\bcurl\b|\bwget\b"#),
            (.install, #"\b(npm|pnpm|yarn|bun)\s+(i|install|add|ci)\b|pip3?\s+install|brew\s+install|cargo\s+add|pod\s+install|gem\s+install|swift\s+package\s+resolve"#),
            (.test, #"\b(test|jest|vitest|pytest|go\s+test|cargo\s+test|swift\s+test)\b"#),
            (.git, #"^\s*git\b"#),
            (.build, #"\b(build|tsc|webpack|make|xcodebuild)\b"#),
            (.run, #"\b(dev|start|serve|run)\b"#),
        ]
        return checks.first { QuickExplainer.matches(c, $0.1) }?.0 ?? .other
    }
}
