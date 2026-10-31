import Foundation

/// Curated lessons are attached only to locally created demo reels, never live bridge cards.
enum DemoLesson: String, CaseIterable {
    case lastCandy, costumeAuth

    var title: String {
        switch self {
        case .lastCandy: "The Last Candy Problem"
        case .costumeAuth: "Two Kids in the Same Spider-Man Mask"
        }
    }

    var videoLabel: String {
        switch self {
        case .lastCandy: "Video #1"
        case .costumeAuth: "Video #2A"
        }
    }

    var symbol: String {
        switch self {
        case .lastCandy: "🍬"
        case .costumeAuth: "🕷️"
        }
    }

    var connection: String {
        switch self {
        case .lastCandy: "Google Maps ↔ Smart Candy Feeder"
        case .costumeAuth: "Costume Auth ↔ Smart Feeder"
        }
    }

    var summary: String {
        switch self {
        case .lastCandy:
            "Reserve candy for kids already walking to the porch, so Google Maps doesn't send more kids to an empty bowl."
        case .costumeAuth:
            "Combine costume and a rounded height to distinguish two Spider-Man friends and reduce repeat candy claims."
        }
    }

    var videoResource: String? {
        switch self {
        case .lastCandy: "last-candy"
        case .costumeAuth: nil
        }
    }

    var watchOut: String {
        switch self {
        case .lastCandy: "Check the last-candy case and expired walking reservations."
        case .costumeAuth: "Check matching costumes and small height changes."
        }
    }

    var videoURL: URL? {
        guard let videoResource else { return nil }
        return Bundle.main.url(forResource: videoResource, withExtension: "mp4")
            ?? Bundle.main.url(forResource: videoResource, withExtension: "mp4", subdirectory: "Resources/Demo")
            ?? Bundle.main.url(forResource: videoResource, withExtension: "mp4", subdirectory: "Demo")
    }

    /// Preserve the supplied question order and A/B/C answer mappings on every replay.
    var questions: [QuizQuestion] {
        switch self {
        case .lastCandy:
            [
                QuizQuestion(
                    prompt: "Why does the code check physical_candy - walking_kids instead of just checking physical_candy > 0?",
                    choices: [
                        "Because kids who are already walking toward the house will take the last candy before new kids farther down the street arrive.",
                        "Because the smart candy feeder weighs candies in grams instead of counting pieces.",
                        "To turn off the street lights when too many kids are on the sidewalk.",
                    ],
                    correct: 0,
                    explanation: "Candy promised to walking kids is already spoken for. Subtract those reservations before showing new visitors that candy is available.",
                    label: "Q1.1 · Core Logic"),
                QuizQuestion(
                    prompt: "What happens on the street if a developer deletes - walking_kids from the code?",
                    choices: [
                        "House #7 stays glowing orange on Google Maps until the bowl physically hits zero, tricking other kids into walking all the way to an empty porch.",
                        "The smart candy feeder dumps all 25 candies to the first kid at once.",
                        "Google Maps crashes and hides every house on the street.",
                    ],
                    correct: 0,
                    explanation: "Without subtracting walking reservations, the map advertises candy that an arriving kid will take. Other kids can be sent to a porch that will be empty by the time they arrive.",
                    label: "Q1.2 · “Break-It!” Mode Check"),
                QuizQuestion(
                    prompt: "Why does the walking reservation expire after 3 minutes (ttl_sec=180)?",
                    choices: [
                        "If a walking kid gets distracted or goes home without visiting the porch, the reservation expires so the candy becomes available on Google Maps again.",
                        "Because chocolate melts inside the feeder after 180 seconds.",
                        "Because the doorbell camera reboots every 3 minutes.",
                    ],
                    correct: 0,
                    explanation: "The three-minute expiry releases abandoned reservations. A kid who never reaches the porch should not keep real candy hidden from the map forever.",
                    label: "Q1.3 · Edge Case — 3-Minute Timer"),
            ]
        case .costumeAuth:
            [
                QuizQuestion(
                    prompt: "Why does the feeder identify a kid using costume + height_bucket (e.g., spiderman_120cm) instead of just costume?",
                    choices: [
                        "So two different kids wearing the same popular Spider-Man mask can each get a candy, while still stopping the exact same kid from grabbing 10 candies in a row.",
                        "Because taller kids automatically get king-size chocolate bars.",
                        "Because the camera cannot see red costumes in the dark.",
                    ],
                    correct: 0,
                    explanation: "A costume alone can be shared by different kids. The height bucket adds another signal so the two Spider-Man friends in the demo have different claim keys.",
                    label: "Q2A.1 · Core Logic"),
                QuizQuestion(
                    prompt: "What happens in the “Break-It!” animation when height_bucket is removed?",
                    choices: [
                        "The feeder mistakes the second Spider-Man friend for the first kid and refuses to give him any candy (ALREADY CLAIMED).",
                        "Both kids receive 10 candies each until the bowl is empty.",
                        "The porch light turns off permanently.",
                    ],
                    correct: 0,
                    explanation: "Both friends collapse to the same costume-only claim key. After the first claim, the second friend is incorrectly treated as a repeat visitor.",
                    label: "Q2A.2 · “Break-It!” Mode Check"),
                QuizQuestion(
                    prompt: "Why does the code round height to 10cm buckets (120cm, 140cm) instead of using exact millimeters like 136.4cm?",
                    choices: [
                        "If exact millimeters were used, the same kid could just stand on their tiptoes (136cm → 139cm) to trick the feeder into thinking they are a brand-new person!",
                        "Because Python strings cannot store decimal points.",
                        "To make the green laser beam look wider on camera.",
                    ],
                    correct: 0,
                    explanation: "Bucketing reduces sensitivity to small height changes. In this example, 136cm and 139cm both round to 140cm, keeping the same claim key.",
                    label: "Q2A.3 · Edge Case — Why Round Height to 10cm?"),
            ]
        }
    }
}
