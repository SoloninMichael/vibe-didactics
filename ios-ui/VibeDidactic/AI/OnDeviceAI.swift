import VibieKit
import Foundation
import FoundationModels

// Everything here runs on Apple's on-device foundation model. Nothing is sent to a server.

@Generable
struct AIExplainer {
    @Guide(description: "A punchy title of 3 to 7 words that starts with a verb, like 'Adds a thirsty-plant badge'")
    var headline: String
    @Guide(description: "One or two short sentences in plain English about what changes for the app or its users")
    var whatChanges: String
    @Guide(description: "One short sentence on why the agent is making this change")
    var why: String
    @Guide(description: "How risky it is to approve this change", .anyOf(["low", "medium", "high"]))
    var risk: String
    @Guide(description: "One short sentence: the main thing that could go wrong, or what to test after approving")
    var watchOut: String
    @Guide(description: "Three short lowercase topic tags without the # sign", .count(3))
    var tags: [String]
}

@Generable
struct AIQuiz {
    @Guide(description: "Multiple-choice questions that check whether a beginner understood this specific change", .count(3))
    var questions: [AIQuestion]
}

@Generable
struct AIQuestion {
    @Guide(description: "A short, friendly question about this specific change")
    var question: String
    @Guide(description: "Three short answer options; exactly one is correct", .count(3))
    var choices: [String]
    @Guide(description: "Index of the correct option", .range(0...2))
    var correctIndex: Int
    @Guide(description: "One sentence explaining why that answer is right")
    var explanation: String
}

enum OnDeviceAI {
    static var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    static var statusText: String {
        switch SystemLanguageModel.default.availability {
        case .available: "Apple Intelligence, running on this iPhone"
        case .unavailable(.deviceNotEligible): "This device can't run Apple Intelligence — using built-in explainers"
        case .unavailable(.appleIntelligenceNotEnabled): "Turn on Apple Intelligence in Settings for richer explainers"
        case .unavailable(.modelNotReady): "The on-device model is still downloading"
        case .unavailable: "Not available — using built-in explainers"
        }
    }

    static let tutorInstructions = """
        You explain code changes made by an AI coding agent to someone who builds apps by "vibe coding" \
        and may not read code fluently. Be concrete, warm and brief. Use plain English; if you must use a \
        technical term, explain it in a few words. Never invent files, functions or behaviour that are not \
        in the change you are given.
        """

    /// A compact description of the change that fits comfortably in the on-device context window.
    static func context(for card: ChangeCard, budget: Int = 1_800) -> String {
        var text = "Agent: \(card.agent.displayName). Project: \(card.project).\n"
        switch card.kind {
        case .command:
            text += "Action: run this shell command: \(card.command ?? "")\n"
        case .checkpoint:
            text += "Action: the agent finished its turn and is waiting for the next instruction.\n"
        default:
            text += "Action: \(card.kind == .create ? "create" : "edit") the file \(card.filePath ?? "?")"
            text += card.language.map { " (\($0))" } ?? ""
            text += ", \(card.additions) lines added and \(card.deletions) removed.\n"
        }
        if let intent = card.agentIntent {
            text += "The agent said: \"\(intent.prefix(500))\"\n"
        }
        let changed = card.lines.filter { $0.kind != .gap }
        if !changed.isEmpty {
            text += "Code (+ added, - removed, unmarked = unchanged):\n"
            for line in changed {
                let marker = line.kind == .added ? "+ " : line.kind == .removed ? "- " : "  "
                let row = marker + line.text.trimmingCharacters(in: .whitespaces) + "\n"
                if text.count + row.count > budget { text += "(more lines not shown)\n"; break }
                text += row
            }
        }
        return text
    }

    static func explainer(for card: ChangeCard, quick: Explainer) async throws -> Explainer {
        let session = LanguageModelSession(instructions: tutorInstructions)
        let ai = try await session.respond(
            to: "Explain this change for a 20-second vertical video.\n\n" + context(for: card),
            generating: AIExplainer.self
        ).content
        // Never let the model talk a change *down*: keep whichever risk is higher.
        let risk = max(RiskLevel(rawValue: ai.risk.lowercased()) ?? .medium, quick.risk)
        return Explainer(
            headline: ai.headline,
            whatChanges: ai.whatChanges,
            why: ai.why,
            risk: risk,
            watchOut: risk > (RiskLevel(rawValue: ai.risk.lowercased()) ?? .low) ? quick.watchOut : ai.watchOut,
            tags: ai.tags.map { $0.lowercased().replacingOccurrences(of: "#", with: "") },
            source: .onDevice)
    }

    static func quiz(for card: ChangeCard) async throws -> [QuizQuestion] {
        let session = LanguageModelSession(instructions: tutorInstructions)
        let quiz = try await session.respond(
            to: "Write a quick 3-question quiz about this change for a beginner.\n\n" + context(for: card),
            generating: AIQuiz.self
        ).content
        return quiz.questions.compactMap { question in
            guard question.choices.count == 3, (0...2).contains(question.correctIndex) else { return nil }
            return QuizQuestion(prompt: question.question, choices: question.choices, correct: question.correctIndex, explanation: question.explanation)
        }
    }
}
