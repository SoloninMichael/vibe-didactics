import Foundation

struct QuizQuestion: Identifiable, Equatable {
    let id = UUID()
    var prompt: String
    var choices: [String]
    var correct: Int
    var explanation: String
    var codeChoices = false
    var label: String? = nil
}
