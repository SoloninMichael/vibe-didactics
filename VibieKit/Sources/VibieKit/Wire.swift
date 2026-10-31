import Foundation

/// Constants shared by the iPhone app and the Mac bridge.
public enum Vibie {
    public static let protocolVersion = 1
    public static let bonjourType = "_vibie._tcp"
    public static let defaultPort: UInt16 = 7766
    public static let controlPort: UInt16 = 7767
}

public enum AgentKind: String, Codable, Sendable, Hashable, CaseIterable {
    case claudeCode = "claude-code"
    case codex
    case demo

    public var displayName: String {
        switch self {
        case .claudeCode: "Claude Code"
        case .codex: "Codex"
        case .demo: "Demo Agent"
        }
    }

    public var handle: String { "@" + rawValue }
}

public enum ChangeKind: String, Codable, Sendable, Hashable {
    /// Modifies an existing file.
    case edit
    /// Writes a file that did not exist.
    case create
    /// Runs a shell command.
    case command
    /// The agent finished a turn and is asking what to do next.
    case checkpoint
    /// Any other tool call.
    case tool
}

public struct DiffLine: Codable, Sendable, Hashable {
    public enum Kind: String, Codable, Sendable { case context, added, removed, gap }

    public var kind: Kind
    public var text: String
    public var oldNumber: Int?
    public var newNumber: Int?

    public init(kind: Kind, text: String, oldNumber: Int? = nil, newNumber: Int? = nil) {
        self.kind = kind
        self.text = text
        self.oldNumber = oldNumber
        self.newNumber = newNumber
    }
}

/// One reel: a single change the agent wants to make.
public struct ChangeCard: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var createdAt: Date
    public var agent: AgentKind
    public var project: String
    public var kind: ChangeKind
    public var tool: String
    public var filePath: String?
    public var command: String?
    /// The agent's own words about what it is doing, taken from its transcript.
    public var agentIntent: String?
    public var lines: [DiffLine]
    public var additions: Int
    public var deletions: Int
    public var truncated: Bool
    /// How many secrets the bridge scrubbed before this card left the Mac.
    public var redactions: Int
    public var language: String?

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        agent: AgentKind,
        project: String,
        kind: ChangeKind,
        tool: String,
        filePath: String? = nil,
        command: String? = nil,
        agentIntent: String? = nil,
        lines: [DiffLine] = [],
        additions: Int = 0,
        deletions: Int = 0,
        truncated: Bool = false,
        redactions: Int = 0,
        language: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.agent = agent
        self.project = project
        self.kind = kind
        self.tool = tool
        self.filePath = filePath
        self.command = command
        self.agentIntent = agentIntent
        self.lines = lines
        self.additions = additions
        self.deletions = deletions
        self.truncated = truncated
        self.redactions = redactions
        self.language = language
    }

    public var fileName: String? {
        filePath.map { ($0 as NSString).lastPathComponent }
    }
}

public enum Verdict: String, Codable, Sendable, Hashable {
    case approve, deny
}

public struct DecisionPayload: Codable, Sendable, Hashable {
    public var cardID: UUID
    public var verdict: Verdict
    /// Free-form guidance for the agent: why it was denied, or what to do next.
    public var note: String?

    public init(cardID: UUID, verdict: Verdict, note: String? = nil) {
        self.cardID = cardID
        self.verdict = verdict
        self.note = note
    }
}

public struct AgentStatus: Codable, Sendable, Hashable {
    public enum State: String, Codable, Sendable { case working, waiting, idle }

    public var state: State
    public var detail: String
    public var project: String
    public var agent: AgentKind
    public var updatedAt: Date

    public init(state: State, detail: String, project: String, agent: AgentKind, updatedAt: Date = Date()) {
        self.state = state
        self.detail = detail
        self.project = project
        self.agent = agent
        self.updatedAt = updatedAt
    }
}

public struct BridgeInfo: Codable, Sendable, Hashable {
    public var name: String
    public var version: Int

    public init(name: String, version: Int = Vibie.protocolVersion) {
        self.name = name
        self.version = version
    }
}

/// Messages between the iPhone and the bridge. Always sent encrypted.
public enum WireMessage: Codable, Sendable {
    case welcome(BridgeInfo)
    case card(ChangeCard)
    case resolved(cardID: UUID, reason: String)
    case status(AgentStatus)
    case decision(DecisionPayload)
    case ping
    case pong
}

/// Messages between a hook process and the bridge over 127.0.0.1.
public enum ControlMessage: Codable, Sendable {
    case awaitDecision(token: String, card: ChangeCard)
    case status(token: String, status: AgentStatus)
    case decision(DecisionPayload)
    case noPhone
    case rejected(String)
}

public enum WireCoding {
    public static func encode<T: Encodable>(_ value: T) throws -> Data {
        try JSONEncoder().encode(value)
    }

    public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try JSONDecoder().decode(type, from: data)
    }
}

/// What the Mac shows as a QR code so the phone can pair with it.
public struct PairingInvite: Codable, Sendable, Hashable {
    public var v: Int
    public var name: String
    /// The bridge's long-term Curve25519 public key.
    public var bridgeKey: Data
    /// One-time secret proving the phone actually saw the QR code.
    public var secret: Data
    public var hosts: [String]
    public var port: UInt16
    public var expires: Date

    public init(name: String, bridgeKey: Data, secret: Data, hosts: [String], port: UInt16, expires: Date) {
        self.v = Vibie.protocolVersion
        self.name = name
        self.bridgeKey = bridgeKey
        self.secret = secret
        self.hosts = hosts
        self.port = port
        self.expires = expires
    }

    public var url: URL {
        let json = (try? WireCoding.encode(self)) ?? Data()
        var components = URLComponents()
        components.scheme = "vibie"
        components.host = "pair"
        components.queryItems = [URLQueryItem(name: "d", value: json.base64URLEncodedString())]
        return components.url!
    }

    public init?(url: URL) {
        guard url.scheme == "vibie", url.host == "pair",
              let payload = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "d" })?.value,
              let data = Data(base64URLEncoded: payload),
              let invite = try? WireCoding.decode(PairingInvite.self, from: data)
        else { return nil }
        self = invite
    }
}

extension Data {
    public func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    public init?(base64URLEncoded string: String) {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64.append("=") }
        self.init(base64Encoded: base64)
    }
}

public enum Language {
    public static func name(forPath path: String) -> String? {
        let file = (path as NSString).lastPathComponent
        switch (path as NSString).pathExtension.lowercased() {
        case "ts": return "TypeScript"
        case "tsx": return "TSX"
        case "js", "mjs", "cjs": return "JavaScript"
        case "jsx": return "JSX"
        case "swift": return "Swift"
        case "py": return "Python"
        case "rb": return "Ruby"
        case "go": return "Go"
        case "rs": return "Rust"
        case "kt", "kts": return "Kotlin"
        case "java": return "Java"
        case "c", "h": return "C"
        case "cpp", "cc", "hpp": return "C++"
        case "m", "mm": return "Objective-C"
        case "cs": return "C#"
        case "php": return "PHP"
        case "html", "htm": return "HTML"
        case "css", "scss", "sass": return "CSS"
        case "json": return "JSON"
        case "md", "mdx": return "Markdown"
        case "yml", "yaml": return "YAML"
        case "toml": return "TOML"
        case "sh", "bash", "zsh": return "Shell"
        case "sql": return "SQL"
        case "vue": return "Vue"
        case "svelte": return "Svelte"
        case "dart": return "Dart"
        case "ipynb": return "Notebook"
        default:
            if file == "Dockerfile" { return "Docker" }
            if file.hasPrefix(".env") { return "Env" }
            return nil
        }
    }
}
