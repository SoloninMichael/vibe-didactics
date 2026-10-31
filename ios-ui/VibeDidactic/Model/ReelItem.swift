import VibieKit
import SwiftUI

enum ReviewStatus: Equatable {
    case pending
    case approved
    case denied
    /// Decided somewhere else: in the terminal, or on another device.
    case elsewhere(String)

    var isPending: Bool { self == .pending }
}

enum RiskLevel: String, CaseIterable, Comparable {
    case low, medium, high

    var title: String {
        switch self {
        case .low: "Low risk"
        case .medium: "Medium risk"
        case .high: "High risk"
        }
    }

    var color: Color {
        switch self {
        case .low: .mint
        case .medium: .orange
        case .high: .pink
        }
    }

    /// Needle position on the risk meter, 0…1.
    var gauge: Double {
        switch self {
        case .low: 0.17
        case .medium: 0.5
        case .high: 0.85
        }
    }

    static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
        allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)!
    }
}

/// Everything the 20-second reel says about a change.
struct Explainer: Equatable {
    enum Source: Equatable { case quick, onDevice }

    var headline: String
    var whatChanges: String
    var why: String
    var risk: RiskLevel
    var watchOut: String
    var tags: [String]
    var source: Source = .quick
}

@Observable
final class ReelItem: Identifiable {
    let card: ChangeCard
    let demoLesson: DemoLesson?
    var status: ReviewStatus = .pending
    var explainer: Explainer
    var note = ""
    var quizScore: Int?

    var id: UUID { card.id }

    init(card: ChangeCard, demoLesson: DemoLesson? = nil) {
        self.card = card
        self.demoLesson = demoLesson
        self.explainer = QuickExplainer.make(for: card)
        if let demoLesson {
            self.explainer.headline = demoLesson.title
            self.explainer.whatChanges = demoLesson.summary
            self.explainer.watchOut = demoLesson.watchOut
        }
    }

    var palette: Palette { Palette(kind: card.kind, risk: explainer.risk) }

    func caption(for beat: Beat) -> String {
        switch beat {
        case .gist:
            return explainer.whatChanges
        case .location:
            let file = card.fileName ?? "this file"
            return card.kind == .create
                ? "A brand-new file: \(file), \(card.additions) lines."
                : "In \(file): \(card.additions) added, \(card.deletions) removed."
        case .code:
            return card.kind == .command ? "This is the exact command it wants to run." : "Green is new. Red is going away."
        case .why:
            return explainer.why
        case .risk:
            return "\(explainer.risk.title). \(explainer.watchOut)"
        case .done:
            return "\(card.agent.shortName) finished a step in \(card.project)."
        case .summary:
            return "Here's its own summary."
        case .next:
            return "Swipe up to tell it what's next — or let it rest."
        }
    }

    func narration(for beat: Beat) -> String {
        beat == .gist ? "\(explainer.headline). \(explainer.whatChanges)" : caption(for: beat)
    }
}

struct Palette {
    var primary: Color
    var secondary: Color

    init(kind: ChangeKind, risk: RiskLevel) {
        switch kind {
        case .edit: secondary = .indigo
        case .create: secondary = .teal
        case .command: secondary = .orange
        case .checkpoint: secondary = .green
        case .tool: secondary = .purple
        }
        switch (kind, risk) {
        case (.checkpoint, _): primary = .mint
        case (_, .low): primary = .cyan
        case (_, .medium): primary = .purple
        case (_, .high): primary = .pink
        }
    }
}

extension ChangeKind {
    var label: String {
        switch self {
        case .edit: "EDIT"
        case .create: "NEW FILE"
        case .command: "COMMAND"
        case .checkpoint: "CHECKPOINT"
        case .tool: "TOOL"
        }
    }

    var symbol: String {
        switch self {
        case .edit: "pencil.line"
        case .create: "doc.badge.plus"
        case .command: "terminal.fill"
        case .checkpoint: "flag.checkered"
        case .tool: "wrench.and.screwdriver.fill"
        }
    }
}

extension AgentKind {
    var shortName: String {
        switch self {
        case .claudeCode: "Claude"
        case .codex: "Codex"
        case .demo: "Agent"
        }
    }
}

extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
