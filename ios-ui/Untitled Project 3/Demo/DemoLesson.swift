import Foundation

/// Curated lessons are attached only to locally created demo reels, never live bridge cards.
enum DemoLesson: String, CaseIterable {
    case demoVid1, demoVid2, demoVid3

    var title: String {
        switch self {
        case .demoVid1: "The Last Candy Problem"
        case .demoVid2: "Break-It! Mode: Empty Bowl Stampede"
        case .demoVid3: "Multi-Agent Parallel Workflow"
        }
    }

    var videoLabel: String {
        switch self {
        case .demoVid1: "Video #1"
        case .demoVid2: "Video #2"
        case .demoVid3: "Video #3"
        }
    }

    var symbol: String {
        switch self {
        case .demoVid1: "🍬"
        case .demoVid2: "💥"
        case .demoVid3: "🤖"
        }
    }

    var connection: String {
        switch self {
        case .demoVid1: "Google Maps ↔ GhostLock ↔ Smart Candy Feeder"
        case .demoVid2: "Counterfactual Bug · spooky_route_controller.py"
        case .demoVid3: "Prompt Trigger ↔ 3 Azure OpenAI Agents ↔ Bundle Data"
        }
    }

    var summary: String {
        switch self {
        case .demoVid1:
            "Reserve candy for kids already walking to House #7 so Google Maps immediately reroutes new kids to House #8."
        case .demoVid2:
            "Deleting '- walking_kids' leaves House #7 falsely glowing ORANGE on Google Maps while Kid A eats the last candy, sending Kid B to an empty bowl."
        case .demoVid3:
            "Fans out one user prompt to Sales, Marketing, and Product AI Agents in parallel, recalls department data, and bundles all three structured outputs."
        }
    }

    var videoResource: String? {
        switch self {
        case .demoVid1: "demo_vid_1"
        case .demoVid2: "demo_vid_2"
        case .demoVid3: "demo_vid_3"
        }
    }

    var watchOut: String {
        switch self {
        case .demoVid1: "Check physical_candy - walking_kids and the 180s reservation TTL."
        case .demoVid2: "Watch physical_candy hit 0 while pin_state stays ORANGE (stale!)."
        case .demoVid3: "1 prompt triggers 3x parallel Azure OpenAI calls; fan-in waits on the slowest branch."
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
        case .demoVid1:
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
        case .demoVid2:
            [
                QuizQuestion(
                    prompt: "In the Break-It! reel, which code change on line 46 of spooky_route_controller.py causes the Empty Bowl Stampede at House #7?",
                    choices: [
                        "Deleting '- walking_kids' so claimable_candy equals physical_candy without subtracting active walkers.",
                        "Setting physical_candy = -1 when the porch light turns on.",
                        "Changing the house number from House #7 to House #8.",
                    ],
                    correct: 0,
                    explanation: "Crossing out '- walking_kids' ignores active GhostLock reservations, so the route controller thinks 1 candy is still claimable even though Kid A is already walking to take it.",
                    label: "Q2.1 · Break-It! Code Mutation"),
                QuizQuestion(
                    prompt: "In the live watch table, why does pin_state stay ORANGE (stale!) while Kid B gets routed to an EMPTY House #7?",
                    choices: [
                        "Because walking_kids was ignored when Kid B requested a route, so Google Maps kept advertising House #7 as available while Kid A ate the last candy.",
                        "Because the smart candy feeder lost Wi-Fi for 24 hours.",
                        "Because Kid B turned off GPS on their phone.",
                    ],
                    correct: 0,
                    explanation: "When walking_kids is ignored, claimable_candy falsely reads 1. By the time Kid B walks over, Kid A has eaten the last candy (physical_candy: 0) and the bowl is empty.",
                    label: "Q2.2 · Live Watch Table Check"),
                QuizQuestion(
                    prompt: "Once kids reach the porch, why does the feeder identify a kid using costume + height_bucket (e.g., spiderman_120cm) instead of just costume?",
                    choices: [
                        "So two different kids wearing the same Spider-Man mask can each get a candy, while rounding to 10cm stops the same kid on tiptoes from claiming twice.",
                        "Because taller kids automatically get king-size chocolate bars.",
                        "Because the camera cannot see red costumes in the dark.",
                    ],
                    correct: 0,
                    explanation: "Combining costume with a 10cm height bucket distinguishes two friends in identical masks while absorbing small posture changes like standing on tiptoes.",
                    label: "Q2.3 · Porch Guard Follow-Up"),
            ]
        case .demoVid3:
            [
                QuizQuestion(
                    prompt: "When a single User Prompt Trigger fires in this workflow, how many parallel Azure OpenAI agent branches execute?",
                    choices: [
                        "Three parallel branches (Sales, Marketing, and Product AI Agents), multiplying LLM token usage by 3x per trigger.",
                        "Only one branch runs, chosen at random.",
                        "Zero LLM calls are made because all data is static.",
                    ],
                    correct: 0,
                    explanation: "The prompt trigger fans out simultaneously to the Sales, Marketing, and Product AI Agent prototypes, each invoking its own Azure OpenAI Chat Model.",
                    label: "Q3.1 · Cloud Cost & Fan-Out"),
                QuizQuestion(
                    prompt: "What happens at the 'Bundle processed data' node if the Marketing Data Processor takes 8 seconds while Sales and Product finish in 1 second?",
                    choices: [
                        "The fan-in bundler waits for all three parallel branches to complete, so total latency equals the slowest branch (8s) or fails if one branch times out.",
                        "It immediately returns only the Sales result and deletes Marketing and Product.",
                        "It restarts the entire workflow from the beginning every second.",
                    ],
                    correct: 0,
                    explanation: "Fan-in synchronization ('Bundle processed data') blocks until Sales, Marketing, and Product processors all deliver their outputs before generating Success Status.",
                    label: "Q3.2 · Fan-In Synchronization"),
                QuizQuestion(
                    prompt: "Why does each AI Agent connect to both an 'Azure OpenAI Chat Model' node and a 'Structured Output Parsed' node before 'Data Recall'?",
                    choices: [
                        "To enforce a strict schema on the LLM response before querying downstream Sales, Marketing, or Product data stores.",
                        "To translate the prompt into binary machine code for the GPU.",
                        "To dim the user's phone screen during processing.",
                    ],
                    correct: 0,
                    explanation: "Parsing structured output guarantees the agent's response has valid fields before 'Data Recall' and 'Data Processor' nodes run.",
                    label: "Q3.3 · Structured Output Guard"),
            ]
        }
    }
}
