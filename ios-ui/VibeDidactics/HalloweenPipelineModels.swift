import Foundation
import SwiftUI

// MARK: - Pipeline Stage & Didactic Technique Enums

enum PipelineStageStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case ingested = "INGESTED"
    case decomposed = "DECOMPOSED"
    case sceneGenerated = "SCENE_GENERATED"
    case sceneWatched = "SCENE_WATCHED"
    case quizInProgress = "QUIZ_IN_PROGRESS"
    case mastered = "MASTERED"

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .ingested: return "1. PR Ingested"
        case .decomposed: return "2. Decomposed"
        case .sceneGenerated: return "3. 3D Scene Ready"
        case .sceneWatched: return "4. Scene Watched"
        case .quizInProgress: return "5. Recall Quiz"
        case .mastered: return "6. PR Mastered"
        }
    }
}

enum DidacticTechnique: String, Codable, CaseIterable, Identifiable, Sendable {
    case dualCoding3D = "dual_coding_3d_metaphor"
    case counterfactualBreakIt = "counterfactual_break_it"
    case socraticMaieutics = "socratic_maieutics"
    case activeRecallFlipcard = "active_recall_flipcard"
    case parsonsPuzzle = "parsons_flow_reconstruction"
    case feynmanRubberDuck = "feynman_rubber_duck_voice"
    case spiralEli5 = "spiral_progressive_depth"

    var id: String { rawValue }
}

// MARK: - Stage 1: Ingestion & Hotspot Schemas

struct IngestRequest: Codable, Equatable, Hashable, Sendable {
    var repoName: String = "spooky-pumpkin-factory-os"
    var prTitle: String = "feat(halloween): AI-generated autonomous Pumpkin Carving, Candle FSM, Candy Saga & 500-Skeleton Sync"
    var simulatedTotalLines: Int = 2_140_000
    var targetBranch: String = "feature/ai-halloween-overhaul"

    enum CodingKeys: String, CodingKey {
        case repoName = "repo_name"
        case prTitle = "pr_title"
        case simulatedTotalLines = "simulated_total_lines"
        case targetBranch = "target_branch"
    }
}

struct SubsystemHotspot: Codable, Identifiable, Equatable, Hashable, Sendable {
    let subsystemId: String
    let title: String
    let filePath: String
    let linesOfCode: Int
    let cyclomaticComplexity: Int
    let architecturalPattern: String
    let riskLevel: String
    let whyHardToUnderstand: String
    let callsTo: [String]

    var id: String { subsystemId }

    enum CodingKeys: String, CodingKey {
        case subsystemId = "subsystem_id"
        case title
        case filePath = "file_path"
        case linesOfCode = "lines_of_code"
        case cyclomaticComplexity = "cyclomatic_complexity"
        case architecturalPattern = "architectural_pattern"
        case riskLevel = "risk_level"
        case whyHardToUnderstand = "why_hard_to_understand"
        case callsTo = "calls_to"
    }
}

struct RepoIngestionSummary: Codable, Equatable, Hashable, Sendable {
    let repoName: String
    let prTitle: String
    let targetBranch: String
    let totalRawLinesScanned: Int
    let filteredGeneratedOrVendorLines: Int
    let coreArchitecturalLines: Int
    let compressionRatio: String
    let mermaidInteractionGraph: String
    let hotspots: [SubsystemHotspot]

    enum CodingKeys: String, CodingKey {
        case repoName = "repo_name"
        case prTitle = "pr_title"
        case targetBranch = "target_branch"
        case totalRawLinesScanned = "total_raw_lines_scanned"
        case filteredGeneratedOrVendorLines = "filtered_generated_or_vendor_lines"
        case coreArchitecturalLines = "core_architectural_lines"
        case compressionRatio = "compression_ratio"
        case mermaidInteractionGraph = "mermaid_interaction_graph"
        case hotspots
    }
}

// MARK: - Stage 2: Spiral Explanations & Counterfactual Mutation

struct SpiralExplanations: Codable, Equatable, Hashable, Sendable {
    let eli5Child: String
    let juniorDev: String
    let seniorArchitect: String

    enum CodingKeys: String, CodingKey {
        case eli5Child = "eli5_child"
        case juniorDev = "junior_dev"
        case seniorArchitect = "senior_architect"
    }
}

struct CounterfactualMutation: Codable, Identifiable, Equatable, Hashable, Sendable {
    let mutationId: String
    let title: String
    let targetFile: String
    let targetLineRange: String
    let codeLineRemoved: String
    let whatBreaksInCode: String
    let cartoonChaosAnimation: String
    let severity: String

    var id: String { mutationId }

    enum CodingKeys: String, CodingKey {
        case mutationId = "mutation_id"
        case title
        case targetFile = "target_file"
        case targetLineRange = "target_line_range"
        case codeLineRemoved = "code_line_removed"
        case whatBreaksInCode = "what_breaks_in_code"
        case cartoonChaosAnimation = "cartoon_chaos_animation"
        case severity
    }
}

// MARK: - Stage 3: 3D Halloween Cartoon Scene Schemas

struct Scene3DActor: Codable, Identifiable, Equatable, Hashable, Sendable {
    let actorId: String
    let name: String
    let roleMetaphor: String
    let codeSymbol: String
    let filePath: String
    let lineRange: String
    let shapeType: String
    let colorHex: String
    let position: [Double]

    var id: String { actorId }

    enum CodingKeys: String, CodingKey {
        case actorId = "actor_id"
        case name
        case roleMetaphor = "role_metaphor"
        case codeSymbol = "code_symbol"
        case filePath = "file_path"
        case lineRange = "line_range"
        case shapeType = "shape_type"
        case colorHex = "color_hex"
        case position
    }
}

struct Scene3DConnection: Codable, Identifiable, Equatable, Hashable, Sendable {
    let fromActorId: String
    let toActorId: String
    let label: String
    let packetType: String
    let colorHex: String

    var id: String { "\(fromActorId)->\(toActorId)-\(label)" }

    enum CodingKeys: String, CodingKey {
        case fromActorId = "from_actor_id"
        case toActorId = "to_actor_id"
        case label
        case packetType = "packet_type"
        case colorHex = "color_hex"
    }
}

struct Scene3DAnimationStep: Codable, Identifiable, Equatable, Hashable, Sendable {
    let stepIndex: Int
    let actTitle: String
    let activeActorIds: [String]
    let packetFlow: String?
    let voiceoverNarration: String
    let codeHighlightFile: String
    let codeHighlightLines: String
    let codeSnippet: String
    let durationSeconds: Double

    var id: Int { stepIndex }

    enum CodingKeys: String, CodingKey {
        case stepIndex = "step_index"
        case actTitle = "act_title"
        case activeActorIdsCapital = "Active_actor_ids"
        case activeActorIdsLower = "active_actor_ids"
        case packetFlow = "packet_flow"
        case voiceoverNarration = "voiceover_narration"
        case codeHighlightFile = "code_highlight_file"
        case codeHighlightLines = "code_highlight_lines"
        case codeSnippet = "code_snippet"
        case durationSeconds = "duration_seconds"
    }

    init(
        stepIndex: Int,
        actTitle: String,
        activeActorIds: [String],
        packetFlow: String? = nil,
        voiceoverNarration: String,
        codeHighlightFile: String,
        codeHighlightLines: String,
        codeSnippet: String,
        durationSeconds: Double = 5.0
    ) {
        self.stepIndex = stepIndex
        self.actTitle = actTitle
        self.activeActorIds = activeActorIds
        self.packetFlow = packetFlow
        self.voiceoverNarration = voiceoverNarration
        self.codeHighlightFile = codeHighlightFile
        self.codeHighlightLines = codeHighlightLines
        self.codeSnippet = codeSnippet
        self.durationSeconds = durationSeconds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stepIndex = try container.decode(Int.self, forKey: .stepIndex)
        actTitle = try container.decode(String.self, forKey: .actTitle)
        if let capitalIds = try container.decodeIfPresent([String].self, forKey: .activeActorIdsCapital) {
            activeActorIds = capitalIds
        } else if let lowerIds = try container.decodeIfPresent([String].self, forKey: .activeActorIdsLower) {
            activeActorIds = lowerIds
        } else {
            activeActorIds = []
        }
        packetFlow = try container.decodeIfPresent(String.self, forKey: .packetFlow)
        voiceoverNarration = try container.decode(String.self, forKey: .voiceoverNarration)
        codeHighlightFile = try container.decode(String.self, forKey: .codeHighlightFile)
        codeHighlightLines = try container.decode(String.self, forKey: .codeHighlightLines)
        codeSnippet = try container.decode(String.self, forKey: .codeSnippet)
        durationSeconds = try container.decodeIfPresent(Double.self, forKey: .durationSeconds) ?? 5.0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(stepIndex, forKey: .stepIndex)
        try container.encode(actTitle, forKey: .actTitle)
        try container.encode(activeActorIds, forKey: .activeActorIdsCapital)
        try container.encodeIfPresent(packetFlow, forKey: .packetFlow)
        try container.encode(voiceoverNarration, forKey: .voiceoverNarration)
        try container.encode(codeHighlightFile, forKey: .codeHighlightFile)
        try container.encode(codeHighlightLines, forKey: .codeHighlightLines)
        try container.encode(codeSnippet, forKey: .codeSnippet)
        try container.encode(durationSeconds, forKey: .durationSeconds)
    }
}

struct Scene3DPayload: Codable, Identifiable, Equatable, Hashable, Sendable {
    let chapterId: String
    let sceneTitle: String
    let halloweenThemeSetting: String
    let videoStoryboardUrl: String
    let interactivePlayerUrl: String
    let actors: [Scene3DActor]
    let connections: [Scene3DConnection]
    let steps: [Scene3DAnimationStep]
    let breakItMutation: CounterfactualMutation

    var id: String { chapterId }
    var videoStoryboardURL: String { videoStoryboardUrl }
    var interactivePlayerURL: String { interactivePlayerUrl }

    enum CodingKeys: String, CodingKey {
        case chapterId = "chapter_id"
        case sceneTitle = "scene_title"
        case halloweenThemeSetting = "halloween_theme_setting"
        case videoStoryboardUrl = "video_storyboard_url"
        case interactivePlayerUrl = "interactive_player_url"
        case actors
        case connections
        case steps
        case breakItMutation = "break_it_mutation"
    }
}

// MARK: - Stage 4 & 5: Gated Flip Cards, Parsons Puzzle & Feynman Voice Check

struct FlipCard: Codable, Identifiable, Equatable, Hashable, Sendable {
    let cardId: String
    let chapterId: String
    let frontQuestion: String
    let socraticHint: String
    let backAnswer: String
    let codeReferenceFile: String
    let codeReferenceLines: String
    let codeSnippet: String
    let difficulty: String
    let didacticTechnique: DidacticTechnique

    var id: String { cardId }

    enum CodingKeys: String, CodingKey {
        case cardId = "card_id"
        case chapterId = "chapter_id"
        case frontQuestion = "front_question"
        case socraticHint = "socratic_hint"
        case backAnswer = "back_answer"
        case codeReferenceFile = "code_reference_file"
        case codeReferenceLines = "code_reference_lines"
        case codeSnippet = "code_snippet"
        case difficulty
        case didacticTechnique = "didactic_technique"
    }
}

struct ParsonsBlock: Codable, Identifiable, Equatable, Hashable, Sendable {
    let blockId: String
    let correctOrderIndex: Int
    let label: String
    let codeLine: String

    var id: String { blockId }

    enum CodingKeys: String, CodingKey {
        case blockId = "block_id"
        case correctOrderIndex = "correct_order_index"
        case label
        case codeLine = "code_line"
    }
}

struct ChapterDidacticAssessment: Codable, Identifiable, Equatable, Hashable, Sendable {
    let chapterId: String
    var unlocked: Bool
    var lockedReason: String?
    let socraticOpeningQuestion: String
    let flipCards: [FlipCard]
    let parsonsBlocksShuffled: [ParsonsBlock]
    let feynmanPrompt: String
    let requiredConceptsForFeynman: [String]

    var id: String { chapterId }

    enum CodingKeys: String, CodingKey {
        case chapterId = "chapter_id"
        case unlocked
        case lockedReason = "locked_reason"
        case socraticOpeningQuestion = "socratic_opening_question"
        case flipCards = "flip_cards"
        case parsonsBlocksShuffled = "parsons_blocks_shuffled"
        case feynmanPrompt = "feynman_prompt"
        case requiredConceptsForFeynman = "required_concepts_for_feynman"
    }
}

struct DidacticChapter: Codable, Identifiable, Equatable, Hashable, Sendable {
    let chapterId: String
    let orderIndex: Int
    let title: String
    let subtitle: String
    let filePath: String
    let architecturalPattern: String
    let spiralExplanations: SpiralExplanations
    let scene3d: Scene3DPayload
    var assessment: ChapterDidacticAssessment
    var sceneCompleted: Bool
    var answeredCards: [String: Bool]
    var feynmanScore: Int?
    var masteryPercentage: Int

    var id: String { chapterId }
    var scene3D: Scene3DPayload { scene3d }

    enum CodingKeys: String, CodingKey {
        case chapterId = "chapter_id"
        case orderIndex = "order_index"
        case title
        case subtitle
        case filePath = "file_path"
        case architecturalPattern = "architectural_pattern"
        case spiralExplanations = "spiral_explanations"
        case scene3d = "scene_3d"
        case assessment
        case sceneCompleted = "scene_completed"
        case answeredCards = "answered_cards"
        case feynmanScore = "feynman_score"
        case masteryPercentage = "mastery_percentage"
    }
}

struct PipelineRunState: Codable, Identifiable, Equatable, Hashable, Sendable {
    let runId: String
    var stageStatus: PipelineStageStatus
    let ingestionSummary: RepoIngestionSummary
    var chapters: [DidacticChapter]
    var overallMasteryPercentage: Int
    var readyToMergePr: Bool

    var id: String { runId }
    var readyToMergePR: Bool { readyToMergePr }

    enum CodingKeys: String, CodingKey {
        case runId = "run_id"
        case stageStatus = "stage_status"
        case ingestionSummary = "ingestion_summary"
        case chapters
        case overallMasteryPercentage = "overall_mastery_percentage"
        case readyToMergePr = "ready_to_merge_pr"
    }
}

// MARK: - API Request & Response Payloads

struct FlipCardAnswerRequest: Codable, Equatable, Hashable, Sendable {
    let cardId: String
    let knewAnswer: Bool

    enum CodingKeys: String, CodingKey {
        case cardId = "card_id"
        case knewAnswer = "knew_answer"
    }
}

struct FlipCardAnswerResponse: Codable, Equatable, Hashable, Sendable {
    let cardId: String
    let knewAnswer: Bool
    let followUpMessage: String
    let simplifiedMetaphor: String?
    let chapterMasteryPercentage: Int
    let overallMasteryPercentage: Int

    enum CodingKeys: String, CodingKey {
        case cardId = "card_id"
        case knewAnswer = "knew_answer"
        case followUpMessage = "follow_up_message"
        case simplifiedMetaphor = "simplified_metaphor"
        case chapterMasteryPercentage = "chapter_mastery_percentage"
        case overallMasteryPercentage = "overall_mastery_percentage"
    }
}

struct FeynmanVoiceRequest: Codable, Equatable, Hashable, Sendable {
    let spokenTranscript: String
    var audioDurationSeconds: Double = 15.0

    enum CodingKeys: String, CodingKey {
        case spokenTranscript = "spoken_transcript"
        case audioDurationSeconds = "audio_duration_seconds"
    }
}

struct FeynmanVoiceFeedback: Codable, Equatable, Hashable, Sendable {
    let chapterId: String
    let comprehensionScore: Int
    let passed: Bool
    let matchedConcepts: [String]
    let missingConcepts: [String]
    let rubberDuckReply: String
    let socraticFollowUp: String?
    let chapterMasteryPercentage: Int
    let overallMasteryPercentage: Int
    let readyToMergePr: Bool

    var readyToMergePR: Bool { readyToMergePr }

    enum CodingKeys: String, CodingKey {
        case chapterId = "chapter_id"
        case comprehensionScore = "comprehension_score"
        case passed
        case matchedConcepts = "matched_concepts"
        case missingConcepts = "missing_concepts"
        case rubberDuckReply = "rubber_duck_reply"
        case socraticFollowUp = "socratic_follow_up"
        case chapterMasteryPercentage = "chapter_mastery_percentage"
        case overallMasteryPercentage = "overall_mastery_percentage"
        case readyToMergePr = "ready_to_merge_pr"
    }
}

// MARK: - VibeDidacticsAPIClient

@MainActor
final class VibeDidacticsAPIClient: ObservableObject {
    static let shared = VibeDidacticsAPIClient()

    @Published var runState: PipelineRunState
    @Published var selectedChapterId: String
    @Published var isLoading: Bool = false
    @Published var isOfflineFallback: Bool = false
    @Published var lastErrorMessage: String?
    @Published var lastFlipCardResponse: FlipCardAnswerResponse?
    @Published var lastFeynmanFeedback: FeynmanVoiceFeedback?

    let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        baseURL: String = "http://127.0.0.1:8000",
        initialRun: PipelineRunState = HalloweenMockData.sampleRun
    ) {
        self.baseURL = baseURL
        self.runState = initialRun
        self.selectedChapterId = initialRun.chapters.first?.chapterId ?? "sub_1_carving"

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 3.5
        config.timeoutIntervalForResource = 6.0
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    var chapters: [DidacticChapter] {
        runState.chapters
    }

    var selectedChapter: DidacticChapter? {
        if let idx = findChapterIndex(for: selectedChapterId) {
            return runState.chapters[idx]
        }
        return runState.chapters.first
    }

    // MARK: 1. Fetch Default Pipeline Run (with automatic offline Halloween fallback)

    @discardableResult
    func fetchDefaultRun() async -> PipelineRunState {
        isLoading = true
        defer { isLoading = false }

        let candidatePaths = [
            "/api/v1/pipeline/runs/default",
            "/api/v1/pipeline/runs/latest"
        ]

        for path in candidatePaths {
            guard let url = URL(string: "\(baseURL)\(path)") else { continue }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            do {
                let (data, response) = try await session.data(for: request)
                if let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) {
                    let decoded = try decoder.decode(PipelineRunState.self, from: data)
                    runState = decoded
                    if findChapterIndex(for: selectedChapterId) == nil,
                       let firstId = decoded.chapters.first?.chapterId {
                        selectedChapterId = firstId
                    }
                    isOfflineFallback = false
                    lastErrorMessage = nil
                    return decoded
                }
            } catch {
                continue
            }
        }

        // Automatic fallback to built-in offline Halloween mock data
        isOfflineFallback = true
        lastErrorMessage = nil
        if runState.chapters.isEmpty {
            runState = HalloweenMockData.sampleRun
        }
        return runState
    }

    func loadDefaultRun() async {
        _ = await fetchDefaultRun()
    }

    // MARK: 2. Mark 3D Scene Completed & Unlock Assessment Gate

    @discardableResult
    func completeScene(chapterId: String) async -> DidacticChapter? {
        let resolvedChapterId = resolveChapterId(chapterId)
        let candidateRunIds = [runState.runId, "default"]

        for runId in candidateRunIds {
            if let url = URL(string: "\(baseURL)/api/v1/pipeline/runs/\(runId)/chapters/\(resolvedChapterId)/complete-scene") {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                do {
                    let (data, response) = try await session.data(for: request)
                    if let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) {
                        isOfflineFallback = false
                        if let updatedRun = try? decoder.decode(PipelineRunState.self, from: data) {
                            runState = updatedRun
                            if let idx = findChapterIndex(for: resolvedChapterId) {
                                return runState.chapters[idx]
                            }
                        } else if let updatedChapter = try? decoder.decode(DidacticChapter.self, from: data) {
                            if let idx = findChapterIndex(for: resolvedChapterId) {
                                runState.chapters[idx] = updatedChapter
                                recalculateOverallMastery()
                                return updatedChapter
                            }
                        }
                    }
                } catch {
                    // Fall through to local state transition below
                }
            }
        }

        // Offline / local fallback state update
        isOfflineFallback = true
        guard let idx = findChapterIndex(for: resolvedChapterId) else { return nil }
        runState.chapters[idx].sceneCompleted = true
        runState.chapters[idx].assessment.unlocked = true
        runState.chapters[idx].assessment.lockedReason = nil
        runState.chapters[idx].masteryPercentage = max(runState.chapters[idx].masteryPercentage, 30)
        if runState.stageStatus == .ingested ||
            runState.stageStatus == .decomposed ||
            runState.stageStatus == .sceneGenerated {
            runState.stageStatus = .sceneWatched
        }
        recalculateOverallMastery()
        return runState.chapters[idx]
    }

    // MARK: 3. Answer a Flip Card (Swipe Right = Got It, Swipe Left = Explain Simpler)

    @discardableResult
    func answerFlipCard(
        chapterId: String,
        cardId: String,
        knewAnswer: Bool
    ) async -> FlipCardAnswerResponse {
        let resolvedChapterId = resolveChapterId(chapterId)
        let payload = FlipCardAnswerRequest(cardId: cardId, knewAnswer: knewAnswer)
        let candidateRunIds = [runState.runId, "default"]

        for runId in candidateRunIds {
            if let url = URL(string: "\(baseURL)/api/v1/pipeline/runs/\(runId)/chapters/\(resolvedChapterId)/flip-cards/answer") {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try? encoder.encode(payload)

                do {
                    let (data, response) = try await session.data(for: request)
                    if let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode),
                       let decoded = try? decoder.decode(FlipCardAnswerResponse.self, from: data) {
                        isOfflineFallback = false
                        applyLocalFlipCardState(
                            chapterId: resolvedChapterId,
                            cardId: cardId,
                            knewAnswer: knewAnswer,
                            serverChapterMastery: decoded.chapterMasteryPercentage,
                            serverOverallMastery: decoded.overallMasteryPercentage
                        )
                        lastFlipCardResponse = decoded
                        return decoded
                    }
                } catch {
                    // Fall through to offline calculation
                }
            }
        }

        // Offline fallback calculation
        isOfflineFallback = true
        let fallbackResponse = buildOfflineFlipCardResponse(
            chapterId: resolvedChapterId,
            cardId: cardId,
            knewAnswer: knewAnswer
        )
        lastFlipCardResponse = fallbackResponse
        return fallbackResponse
    }

    // MARK: 4. Submit Feynman Rubber-Duck Voice Explanation

    @discardableResult
    func submitFeynmanCheck(
        chapterId: String,
        transcript: String,
        audioDurationSeconds: Double = 15.0
    ) async -> FeynmanVoiceFeedback {
        let resolvedChapterId = resolveChapterId(chapterId)
        let payload = FeynmanVoiceRequest(
            spokenTranscript: transcript,
            audioDurationSeconds: audioDurationSeconds
        )
        let candidateRunIds = [runState.runId, "default"]

        for runId in candidateRunIds {
            if let url = URL(string: "\(baseURL)/api/v1/pipeline/runs/\(runId)/chapters/\(resolvedChapterId)/feynman-voice") {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try? encoder.encode(payload)

                do {
                    let (data, response) = try await session.data(for: request)
                    if let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode),
                       let decoded = try? decoder.decode(FeynmanVoiceFeedback.self, from: data) {
                        isOfflineFallback = false
                        applyLocalFeynmanState(chapterId: resolvedChapterId, feedback: decoded)
                        lastFeynmanFeedback = decoded
                        return decoded
                    }
                } catch {
                    // Fall through to offline grading
                }
            }
        }

        // Offline fallback Feynman grading
        isOfflineFallback = true
        let fallbackFeedback = evaluateOfflineFeynmanCheck(
            chapterId: resolvedChapterId,
            transcript: transcript
        )
        lastFeynmanFeedback = fallbackFeedback
        return fallbackFeedback
    }

    func resetToOfflineSample() {
        runState = HalloweenMockData.sampleRun
        selectedChapterId = runState.chapters.first?.chapterId ?? "sub_1_carving"
        lastFlipCardResponse = nil
        lastFeynmanFeedback = nil
    }

    // MARK: - Internal State Helpers

    private func findChapterIndex(for chapterId: String) -> Int? {
        if let exact = runState.chapters.firstIndex(where: { $0.chapterId == chapterId }) {
            return exact
        }
        let lowered = chapterId.lowercased()
        return runState.chapters.firstIndex { chapter in
            let cid = chapter.chapterId.lowercased()
            return (lowered.contains("carv") && cid.contains("carv")) ||
                (lowered.contains("candle") && cid.contains("candle")) ||
                (lowered.contains("candy") && cid.contains("candy")) ||
                ((lowered.contains("sync") || lowered.contains("party")) &&
                 (cid.contains("sync") || cid.contains("party")))
        }
    }

    private func resolveChapterId(_ chapterId: String) -> String {
        if let idx = findChapterIndex(for: chapterId) {
            return runState.chapters[idx].chapterId
        }
        return chapterId
    }

    private func applyLocalFlipCardState(
        chapterId: String,
        cardId: String,
        knewAnswer: Bool,
        serverChapterMastery: Int?,
        serverOverallMastery: Int?
    ) {
        guard let idx = findChapterIndex(for: chapterId) else { return }
        runState.chapters[idx].sceneCompleted = true
        runState.chapters[idx].assessment.unlocked = true
        runState.chapters[idx].assessment.lockedReason = nil
        runState.chapters[idx].answeredCards[cardId] = knewAnswer

        if let serverChapterMastery {
            runState.chapters[idx].masteryPercentage = serverChapterMastery
        } else {
            runState.chapters[idx].masteryPercentage = computeChapterMastery(runState.chapters[idx])
        }

        if runState.stageStatus != .mastered {
            runState.stageStatus = .quizInProgress
        }

        if let serverOverallMastery {
            runState.overallMasteryPercentage = serverOverallMastery
            runState.readyToMergePr = serverOverallMastery >= 80
        } else {
            recalculateOverallMastery()
        }
    }

    private func buildOfflineFlipCardResponse(
        chapterId: String,
        cardId: String,
        knewAnswer: Bool
    ) -> FlipCardAnswerResponse {
        applyLocalFlipCardState(
            chapterId: chapterId,
            cardId: cardId,
            knewAnswer: knewAnswer,
            serverChapterMastery: nil,
            serverOverallMastery: nil
        )

        let chapter = findChapterIndex(for: chapterId).map { runState.chapters[$0] }
        let card = chapter?.assessment.flipCards.first(where: { $0.cardId == cardId })

        let followUp: String
        let simplified: String?

        if knewAnswer {
            followUp = "Locked in! You nailed how `\(card?.codeReferenceFile ?? "this module")` enforces its production safety invariant."
            simplified = nil
        } else {
            followUp = "No worries! Let's anchor the mental model with a simpler Halloween metaphor before re-testing."
            simplified = chapter?.spiralExplanations.eli5Child
                ?? "Think of Bouncer Bat checking every ticket at the door so two robots never carve the same pumpkin twice!"
        }

        return FlipCardAnswerResponse(
            cardId: cardId,
            knewAnswer: knewAnswer,
            followUpMessage: followUp,
            simplifiedMetaphor: simplified,
            chapterMasteryPercentage: chapter?.masteryPercentage ?? 45,
            overallMasteryPercentage: runState.overallMasteryPercentage
        )
    }

    private func evaluateOfflineFeynmanCheck(
        chapterId: String,
        transcript: String
    ) -> FeynmanVoiceFeedback {
        guard let idx = findChapterIndex(for: chapterId) else {
            return FeynmanVoiceFeedback(
                chapterId: chapterId,
                comprehensionScore: 85,
                passed: true,
                matchedConcepts: ["idempotency", "backpressure"],
                missingConcepts: [],
                rubberDuckReply: "Quack-tastic! Professor Quackula approves your architectural explanation!",
                socraticFollowUp: nil,
                chapterMasteryPercentage: 90,
                overallMasteryPercentage: runState.overallMasteryPercentage,
                readyToMergePr: runState.readyToMergePr
            )
        }

        let chapter = runState.chapters[idx]
        let normalizedTranscript = transcript.lowercased()
        let required = chapter.assessment.requiredConceptsForFeynman

        var matched: [String] = []
        var missing: [String] = []

        for concept in required {
            if transcriptMatchesConcept(transcript: normalizedTranscript, concept: concept.lowercased()) {
                matched.append(concept)
            } else {
                missing.append(concept)
            }
        }

        let ratio = required.isEmpty ? 1.0 : Double(matched.count) / Double(required.count)
        let wordBonus = normalizedTranscript.split(separator: " ").count >= 12 ? 10 : 0
        let rawScore = Int((ratio * 90.0).rounded()) + (matched.isEmpty ? 0 : wordBonus)
        let score = min(100, max(25, rawScore))
        let passed = score >= 70 || matched.count >= max(1, required.count - 1)

        runState.chapters[idx].sceneCompleted = true
        runState.chapters[idx].assessment.unlocked = true
        runState.chapters[idx].assessment.lockedReason = nil
        runState.chapters[idx].feynmanScore = score
        runState.chapters[idx].masteryPercentage = computeChapterMastery(runState.chapters[idx])
        recalculateOverallMastery()

        let reply: String
        let followUp: String?
        if passed {
            reply = "Quack-tastic! Professor Quackula tipped his witch hat—you clearly explained \(matched.joined(separator: ", ")) for \(chapter.title)!"
            followUp = missing.isEmpty
                ? nil
                : "Bonus stretch question: how does `\(missing.first!)` interact with this path under a 10x Halloween traffic spike?"
        } else {
            reply = "Hmm, Professor Quackula tilted his head! You touched on \(matched.isEmpty ? "the high-level flow" : matched.joined(separator: ", ")), but missed a crucial failure guard."
            followUp = "Try explaining what happens in `\(chapter.filePath)` when we need \(missing.joined(separator: " and "))!"
        }

        return FeynmanVoiceFeedback(
            chapterId: chapter.chapterId,
            comprehensionScore: score,
            passed: passed,
            matchedConcepts: matched,
            missingConcepts: missing,
            rubberDuckReply: reply,
            socraticFollowUp: followUp,
            chapterMasteryPercentage: runState.chapters[idx].masteryPercentage,
            overallMasteryPercentage: runState.overallMasteryPercentage,
            readyToMergePr: runState.readyToMergePr
        )
    }

    private func applyLocalFeynmanState(chapterId: String, feedback: FeynmanVoiceFeedback) {
        guard let idx = findChapterIndex(for: chapterId) else { return }
        runState.chapters[idx].sceneCompleted = true
        runState.chapters[idx].assessment.unlocked = true
        runState.chapters[idx].assessment.lockedReason = nil
        runState.chapters[idx].feynmanScore = feedback.comprehensionScore
        runState.chapters[idx].masteryPercentage = feedback.chapterMasteryPercentage
        runState.overallMasteryPercentage = feedback.overallMasteryPercentage
        runState.readyToMergePr = feedback.readyToMergePr
        if feedback.readyToMergePr {
            runState.stageStatus = .mastered
        }
    }

    private func transcriptMatchesConcept(transcript: String, concept: String) -> Bool {
        if transcript.contains(concept) { return true }
        let tokens = concept
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map(String.init)
            .filter { $0.count >= 3 }

        for token in tokens {
            let stem = String(token.prefix(max(4, token.count - 2)))
            if transcript.contains(stem) {
                return true
            }
        }
        return false
    }

    private func computeChapterMastery(_ chapter: DidacticChapter) -> Int {
        var score = chapter.sceneCompleted ? 30 : 0
        let totalCards = max(1, chapter.assessment.flipCards.count)
        let masteredCards = chapter.answeredCards.values.filter { $0 }.count
        score += Int((Double(masteredCards) / Double(totalCards)) * 35.0)
        if let feynman = chapter.feynmanScore {
            score += Int((Double(feynman) / 100.0) * 35.0)
        }
        return min(100, max(chapter.masteryPercentage, score))
    }

    private func recalculateOverallMastery() {
        guard !runState.chapters.isEmpty else { return }
        let total = runState.chapters.reduce(0) { $0 + $1.masteryPercentage }
        runState.overallMasteryPercentage = total / runState.chapters.count
        runState.readyToMergePr = runState.overallMasteryPercentage >= 80
        if runState.readyToMergePr {
            runState.stageStatus = .mastered
        }
    }
}

// MARK: - Rich Offline Halloween Mock Data

enum HalloweenMockData {
    static let sampleRun: PipelineRunState = {
        let hotspots: [SubsystemHotspot] = [
            SubsystemHotspot(
                subsystemId: "sub_1_carving",
                title: "Autonomous Laser Pumpkin Carving Dispatcher",
                filePath: "mock_halloween_app/carving_dispatcher.py",
                linesOfCode: 158,
                cyclomaticComplexity: 22,
                architecturalPattern: "Idempotency Lock + Token Bucket",
                riskLevel: "CRITICAL",
                whyHardToUnderstand: "Combines time-proportional token-bucket burst rate limiting, in-flight TTL idempotency locking, and fractal SVG kerf-load structural physics in a single synchronous laser dispatch path.",
                callsTo: ["sub_2_candle_fsm", "sub_4_spooky_sync"]
            ),
            SubsystemHotspot(
                subsystemId: "sub_2_candle_fsm",
                title: "Smart Jack-o'-Lantern Candle Safety FSM",
                filePath: "mock_halloween_app/candle_safety_fsm.py",
                linesOfCode: 169,
                cyclomaticComplexity: 26,
                architecturalPattern: "Hierarchical FSM + Circuit Breaker",
                riskLevel: "CRITICAL",
                whyHardToUnderstand: "Couples UDP monotonic sequence-number deduplication with a 6-state flame safety state machine and a 3-state (CLOSED/OPEN/HALF_OPEN) thermal circuit breaker that triggers emergency CO2 extinguisher puffs.",
                callsTo: ["sub_4_spooky_sync"]
            ),
            SubsystemHotspot(
                subsystemId: "sub_3_candy_saga",
                title: "Allergy-Safe Candy Inventory & Dispatch Saga",
                filePath: "mock_halloween_app/candy_router.py",
                linesOfCode: 174,
                cyclomaticComplexity: 21,
                architecturalPattern: "Optimistic Locking + Saga Rollback",
                riskLevel: "CRITICAL",
                whyHardToUnderstand: "Interleaves transitive allergen cross-contamination set verification with versioned compare-and-swap (CAS) cauldron mutations, reverse-order compensating rollbacks, and Dead Letter Queue (DLQ) routing.",
                callsTo: ["sub_4_spooky_sync"]
            ),
            SubsystemHotspot(
                subsystemId: "sub_4_spooky_sync",
                title: "500-Skeleton Animatronic 60fps Audio Sync Hub",
                filePath: "mock_halloween_app/spooky_sync_engine.py",
                linesOfCode: 155,
                cyclomaticComplexity: 19,
                architecturalPattern: "Bounded Ring Buffer + Backpressure",
                riskLevel: "HIGH",
                whyHardToUnderstand: "Synchronizes 128 BPM trigonometric joint choreography across 500 lossy graveyard Wi-Fi nodes using a Drop-Oldest bounded ring buffer and exponential moving average (EMA) clock-drift jitter compensation.",
                callsTo: []
            )
        ]

        let summary = RepoIngestionSummary(
            repoName: "spooky-pumpkin-factory-os",
            prTitle: "feat(halloween): AI-generated autonomous Pumpkin Carving, Candle FSM, Candy Saga & 500-Skeleton Sync",
            targetBranch: "feature/ai-halloween-overhaul",
            totalRawLinesScanned: 2_140_000,
            filteredGeneratedOrVendorLines: 2_139_344,
            coreArchitecturalLines: 656,
            compressionRatio: "99.97% noise filtered (2,140,000 -> 656 core architectural lines)",
            mermaidInteractionGraph: """
            flowchart TD
                PR["Massive AI PR (2,140,000 raw lines)"] -->|Semantic AST Filter| CORE["4 Core Architectural Hotspots"]
                CORE --> sub_1_carving["1. Autonomous Laser Pumpkin Carving Dispatcher"]
                CORE --> sub_2_candle_fsm["2. Smart Jack-o'-Lantern Candle Safety FSM"]
                CORE --> sub_3_candy_saga["3. Allergy-Safe Candy Inventory & Dispatch Saga"]
                CORE --> sub_4_spooky_sync["4. 500-Skeleton Animatronic 60fps Audio Sync Hub"]
                sub_1_carving -->|"Carved Pumpkin Ready -> Arm Ignition"| sub_2_candle_fsm
                sub_1_carving -->|"Laser Rig Cue Event"| sub_4_spooky_sync
                sub_2_candle_fsm -->|"CO2 Cutoff / Flame Telemetry Alert"| sub_4_spooky_sync
                sub_3_candy_saga -->|"Trick-or-Treater Arrival Fanfare"| sub_4_spooky_sync
            """,
            hotspots: hotspots
        )

        return PipelineRunState(
            runId: "run-halloween-2026",
            stageStatus: .sceneGenerated,
            ingestionSummary: summary,
            chapters: [
                chapter1Carving,
                chapter2CandleFSM,
                chapter3CandySaga,
                chapter4SpookySync
            ],
            overallMasteryPercentage: 0,
            readyToMergePr: false
        )
    }()

    // MARK: Chapter 1 — Autonomous Laser Pumpkin Carving Dispatcher

    static let chapter1Carving = DidacticChapter(
        chapterId: "sub_1_carving",
        orderIndex: 1,
        title: "Autonomous Laser Pumpkin Carving Dispatcher",
        subtitle: "Why network retries & burst spikes won't shred the same pumpkin twice",
        filePath: "mock_halloween_app/carving_dispatcher.py",
        architecturalPattern: "Idempotency Lock + Token Bucket",
        spiralExplanations: SpiralExplanations(
            eli5Child: "Imagine two hyperactive Robot Knives—Choppy-Bot and Slice-Bot—who both hear a spooky echo telling them to carve the exact same giant pumpkin at the same time! Without Bouncer Bat standing guard at the chopping block holding the Single Golden Carving Ticket, both robot knives would jump on the pumpkin together and chop it into orange mush. Bouncer Bat checks the ticket number first and tells the second robot: 'Shoo! Ticket #404 is already being carved!'",
            juniorDev: "When a webhook or message queue retries a request after a brief network blip, `carve_pumpkin(req)` can receive duplicate payloads carrying the same `idempotency_key`. Before firing the physical laser actuator, the service calls `self.lock_store.acquire(req.idempotency_key)` and checks the completed-operation ledger. If the key is already locked or processed, it short-circuits and returns the cached result instead of executing the carving G-code twice.",
            seniorArchitect: "Relying on a TTL-bound distributed mutex (`lock_store.acquire` with lock TTL) under at-least-once delivery introduces a classic split-brain hazard under GC pauses or NTP clock drift. Production-grade safety pairs the `idempotency_key` ledger with a token-bucket burst limiter (`TokenBucket.consume`) and monotonically increasing fencing tokens validated directly by the downstream CNC laser controller."
        ),
        scene3d: Scene3DPayload(
            chapterId: "sub_1_carving",
            sceneTitle: "Bouncer Bat & The Twin Laser Knives",
            halloweenThemeSetting: "Neon Haunted CNC Pumpkin Workshop",
            videoStoryboardUrl: "http://127.0.0.1:8000/static/player.html?chapter=sub_1_carving",
            interactivePlayerUrl: "http://127.0.0.1:8000/static/player.html?chapter=sub_1_carving",
            actors: [
                Scene3DActor(
                    actorId: "bouncer_bat",
                    name: "Bouncer Bat (Idempotency Lock)",
                    roleMetaphor: "Checks the Golden Ticket ledger so duplicate retry ghosts get bounced at the door",
                    codeSymbol: "IdempotencyLockStore.acquire",
                    filePath: "mock_halloween_app/carving_dispatcher.py",
                    lineRange: "L48-L68",
                    shapeType: "bouncer_bat",
                    colorHex: "#A855F7",
                    position: [-2.4, 1.2, 0.0]
                ),
                Scene3DActor(
                    actorId: "token_cauldron",
                    name: "Glowing Token Cauldron",
                    roleMetaphor: "Refills laser energy tokens at a steady drip so burst spikes don't melt the CNC diode",
                    codeSymbol: "TokenBucket.consume",
                    filePath: "mock_halloween_app/carving_dispatcher.py",
                    lineRange: "L22-L45",
                    shapeType: "cauldron_queue",
                    colorHex: "#22C55E",
                    position: [-0.6, 0.5, -1.0]
                ),
                Scene3DActor(
                    actorId: "pumpkin_bot",
                    name: "Choppy-Bot CNC Laser Rig",
                    roleMetaphor: "High-precision fractal Jack-o'-Lantern laser carver",
                    codeSymbol: "CarvingDispatcher.dispatch_carve",
                    filePath: "mock_halloween_app/carving_dispatcher.py",
                    lineRange: "L92-L138",
                    shapeType: "pumpkin_bot",
                    colorHex: "#F97316",
                    position: [1.8, 0.8, 0.0]
                ),
                Scene3DActor(
                    actorId: "prize_pumpkin",
                    name: "Prize Giant Pumpkin #99",
                    roleMetaphor: "Shared physical hardware resource that is destroyed by concurrent unguarded writes",
                    codeSymbol: "PumpkinCarvingJob",
                    filePath: "mock_halloween_app/carving_dispatcher.py",
                    lineRange: "L12-L20",
                    shapeType: "candy_vault",
                    colorHex: "#FB923C",
                    position: [2.8, 0.0, 0.5]
                )
            ],
            connections: [
                Scene3DConnection(
                    fromActorId: "bouncer_bat",
                    toActorId: "token_cauldron",
                    label: "1. Lock Acquired (PENDING)",
                    packetType: "idempotency_ticket",
                    colorHex: "#A855F7"
                ),
                Scene3DConnection(
                    fromActorId: "token_cauldron",
                    toActorId: "pumpkin_bot",
                    label: "2. Consume 1 Laser Token",
                    packetType: "rate_token",
                    colorHex: "#22C55E"
                ),
                Scene3DConnection(
                    fromActorId: "pumpkin_bot",
                    toActorId: "prize_pumpkin",
                    label: "3. Execute Fractal SVG Cut",
                    packetType: "laser_gcode",
                    colorHex: "#F97316"
                )
            ],
            steps: [
                Scene3DAnimationStep(
                    stepIndex: 1,
                    actTitle: "Act I: Webhook & Network Retry Ghost Arrive",
                    activeActorIds: ["bouncer_bat"],
                    packetFlow: "bouncer_bat->token_cauldron",
                    voiceoverNarration: "Two identical `req_id=vip-42` carving requests arrive 8ms apart due to a shaky graveyard Wi-Fi retry. Bouncer Bat stamps `vip-42` as `IN_FLIGHT` and bounces the duplicate ghost immediately!",
                    codeHighlightFile: "mock_halloween_app/carving_dispatcher.py",
                    codeHighlightLines: "L52-L64",
                    codeSnippet: """
                    existing = self._idempotency_ledger.get(req.idempotency_key)
                    if existing and not existing.is_expired(now):
                        return existing.cached_receipt  # Deduped retry!
                    self._idempotency_ledger[req.idempotency_key] = Lease(status="IN_FLIGHT", ttl=30.0)
                    """,
                    durationSeconds: 5.0
                ),
                Scene3DAnimationStep(
                    stepIndex: 2,
                    actTitle: "Act II: Token Bucket Laser Backpressure",
                    activeActorIds: ["token_cauldron", "pumpkin_bot"],
                    packetFlow: "token_cauldron->pumpkin_bot",
                    voiceoverNarration: "Next, Choppy-Bot dips a ladle into the Glowing Token Cauldron. Because tokens refill at a fixed rate, a sudden 100-pumpkin burst won't overheat the laser diodes.",
                    codeHighlightFile: "mock_halloween_app/carving_dispatcher.py",
                    codeHighlightLines: "L31-L42",
                    codeSnippet: """
                    self._refill(now)
                    if self.tokens < cost:
                        raise RateLimitExceededError("Laser cooling down — retry after backoff")
                    self.tokens -= cost
                    """,
                    durationSeconds: 5.0
                ),
                Scene3DAnimationStep(
                    stepIndex: 3,
                    actTitle: "Act III: Atomic Carving & Ledger Commit",
                    activeActorIds: ["pumpkin_bot", "prize_pumpkin", "bouncer_bat"],
                    packetFlow: "pumpkin_bot->prize_pumpkin",
                    voiceoverNarration: "Choppy-Bot carves the grinning Jack-o'-Lantern face in one clean pass and upgrades Bouncer Bat's ledger entry from `IN_FLIGHT` to `COMPLETED`.",
                    codeHighlightFile: "mock_halloween_app/carving_dispatcher.py",
                    codeHighlightLines: "L114-L129",
                    codeSnippet: """
                    receipt = self._execute_laser_gcode(req)
                    self._idempotency_ledger[req.idempotency_key].mark_completed(receipt)
                    return receipt
                    """,
                    durationSeconds: 5.0
                )
            ],
            breakItMutation: CounterfactualMutation(
                mutationId: "mut_1_idempotency_guard",
                title: "Remove Bouncer Bat's Idempotency Lock Check",
                targetFile: "mock_halloween_app/carving_dispatcher.py",
                targetLineRange: "L54-L56",
                codeLineRemoved: "if not self.lock_store.acquire(req.idempotency_key):",
                whatBreaksInCode: "Duplicate webhook or queue retry deliveries bypass the distributed mutex and execute laser G-code concurrently on the same physical pumpkin unit, causing a race-condition state collision and overlapping hardware cuts.",
                cartoonChaosAnimation: "Bouncer Bat vanishes in a puff of purple smoke! Two manic Robot Knives dive onto Prize Pumpkin #99 simultaneously at 2x speed, sparks flying, slicing it into splattered orange pumpkin puree while duplicate 'CARVING_COMPLETE' ribbons rain from the rafters!",
                severity: "CRITICAL"
            )
        ),
        assessment: ChapterDidacticAssessment(
            chapterId: "sub_1_carving",
            unlocked: false,
            lockedReason: "Watch the 3D Halloween Cartoon Scene first so your visual mental model of Bouncer Bat & Choppy-Bot is anchored before testing active recall.",
            socraticOpeningQuestion: "Why must the idempotency key be recorded as `IN_FLIGHT` *before* the laser begins carving, rather than only saving it after the carving finishes?",
            flipCards: [
                FlipCard(
                    cardId: "card_carving_1",
                    chapterId: "sub_1_carving",
                    frontQuestion: "What bug occurs if `idempotency_key` is only written to the store *after* `_execute_laser_gcode()` finishes?",
                    socraticHint: "Think about how long a physical CNC laser takes vs. how fast an impatient mobile app retries on slow Wi-Fi.",
                    backAnswer: "A Time-of-Check to Time-of-Use (TOCTOU) race window opens: a network retry arriving while the first cut is still in progress sees no key in the store and starts a second concurrent laser cut on the same pumpkin.",
                    codeReferenceFile: "mock_halloween_app/carving_dispatcher.py",
                    codeReferenceLines: "L52-L66",
                    codeSnippet: "self._idempotency_ledger[req.idempotency_key] = Lease(status='IN_FLIGHT', ttl=30.0)",
                    difficulty: "MEDIUM",
                    didacticTechnique: .activeRecallFlipcard
                ),
                FlipCard(
                    cardId: "card_carving_2",
                    chapterId: "sub_1_carving",
                    frontQuestion: "Why does `CarvingDispatcher` need BOTH an Idempotency Lock AND a Token Bucket rate limiter?",
                    socraticHint: "What if 500 *different* guests tap 'Carve My Pumpkin' at the exact same second?",
                    backAnswer: "Idempotency only blocks duplicate retries of the *same* request. The Token Bucket protects the physical CNC laser from 500 *distinct* valid requests arriving in a simultaneous burst.",
                    codeReferenceFile: "mock_halloween_app/carving_dispatcher.py",
                    codeReferenceLines: "L28-L45",
                    codeSnippet: "if not self.token_bucket.consume(cost=req.estimated_laser_tokens):\n    raise BackpressureRateLimitError()",
                    difficulty: "EASY",
                    didacticTechnique: .socraticMaieutics
                ),
                FlipCard(
                    cardId: "card_carving_3",
                    chapterId: "sub_1_carving",
                    frontQuestion: "Why does the `IN_FLIGHT` idempotency lease carry a TTL expiration timestamp?",
                    socraticHint: "What happens to Pumpkin #99 if the worker crashes mid-cut and the lock never expires?",
                    backAnswer: "Without a lease TTL, a worker crash during carving leaves the key permanently stuck in `IN_FLIGHT`, wedging future retries forever (deadlock).",
                    codeReferenceFile: "mock_halloween_app/carving_dispatcher.py",
                    codeReferenceLines: "L58-L74",
                    codeSnippet: "if existing.status == 'IN_FLIGHT' and now < existing.expires_at:\n    return existing",
                    difficulty: "HARD",
                    didacticTechnique: .counterfactualBreakIt
                )
            ],
            parsonsBlocksShuffled: [
                ParsonsBlock(
                    blockId: "p1_step3",
                    correctOrderIndex: 2,
                    label: "Consume Token Bucket capacity before hardware I/O",
                    codeLine: "self.token_bucket.consume_or_raise(req.token_cost)"
                ),
                ParsonsBlock(
                    blockId: "p1_step1",
                    correctOrderIndex: 0,
                    label: "Check idempotency ledger for existing COMPLETED/IN_FLIGHT key",
                    codeLine: "if cached := self.lock_store.get_active(req.idempotency_key): return cached"
                ),
                ParsonsBlock(
                    blockId: "p1_step4",
                    correctOrderIndex: 3,
                    label: "Execute CNC laser cut and commit COMPLETED receipt",
                    codeLine: "receipt = self.laser.carve(req); self.lock_store.complete(req.idempotency_key, receipt)"
                ),
                ParsonsBlock(
                    blockId: "p1_step2",
                    correctOrderIndex: 1,
                    label: "Acquire atomic IN_FLIGHT lease with TTL guard",
                    codeLine: "self.lock_store.acquire_in_flight(req.idempotency_key, ttl_seconds=30.0)"
                )
            ],
            feynmanPrompt: "Explain to Professor Quackula how Bouncer Bat's Idempotency Lock and the Glowing Token Cauldron work together so network retries and party traffic spikes never ruin a pumpkin.",
            requiredConceptsForFeynman: [
                "idempotency",
                "token bucket",
                "lock",
                "retry"
            ]
        ),
        sceneCompleted: false,
        answeredCards: [:],
        feynmanScore: nil,
        masteryPercentage: 0
    )

    // MARK: Chapter 2 — Smart Jack-o'-Lantern Candle Safety FSM

    static let chapter2CandleFSM = DidacticChapter(
        chapterId: "sub_2_candle_fsm",
        orderIndex: 2,
        title: "Smart Jack-o'-Lantern Candle Safety FSM",
        subtitle: "Filtering out-of-order UDP ghost packets & thermal runaway",
        filePath: "mock_halloween_app/candle_safety_fsm.py",
        architecturalPattern: "Hierarchical FSM + Circuit Breaker",
        spiralExplanations: SpiralExplanations(
            eli5Child: "Inside our giant Jack-o'-Lantern, a friendly Fire Sprite shouts 'SPARK! Light up!' while a mischievous Wind Ghost blows 'PUFF! Go dark!' across the graveyard. Sometimes an old 'SPARK!' message gets lost behind a tombstone and arrives late, *after* the pumpkin overheated and sprayed its emergency extinguisher! So the lantern checks the secret Page Number stamped on every spell: if an old page number shows up late, the lantern ignores it so the pumpkin never catches fire!",
            juniorDev: "The `CandleStateMachine` protects transitions (`UNLIT -> IGNITING -> LIT -> EXTINGUISHED`) using a monotonic UDP `sequence_number` watermark (`if packet.sequence_number <= self.last_seq: return`) plus a 3-state Thermal Circuit Breaker (`CLOSED -> OPEN -> HALF_OPEN`). When internal temperature exceeds 85°C, the breaker trips `OPEN` and blocks re-ignition until cooldown completes.",
            seniorArchitect: "Deterministic UDP packet reordering protection via monotonic per-sensor sequence watermarks strictly outperforms wall-clock Last-Write-Wins (LWW) timestamps, which silently violate safety FSM invariants under NTP clock skew. Pairing ingress sequence filtering with a hysteretic thermal circuit breaker prevents actuator chattering around the 85°C threshold."
        ),
        scene3d: Scene3DPayload(
            chapterId: "sub_2_candle_fsm",
            sceneTitle: "Graveyard Wind Gusts & The Zombie Postman",
            halloweenThemeSetting: "Foggy Porch Jack-o'-Lantern Telemetry Lab",
            videoStoryboardUrl: "http://127.0.0.1:8000/static/player.html?chapter=sub_2_candle_fsm",
            interactivePlayerUrl: "http://127.0.0.1:8000/static/player.html?chapter=sub_2_candle_fsm",
            actors: [
                Scene3DActor(
                    actorId: "zombie_postman",
                    name: "Zombie UDP Postman",
                    roleMetaphor: "Delivers numbered telemetry scrolls, sometimes out of order after tripping over tombstones",
                    codeSymbol: "CandleTelemetryPacket.sequence_number",
                    filePath: "mock_halloween_app/candle_safety_fsm.py",
                    lineRange: "L18-L34",
                    shapeType: "bouncer_bat",
                    colorHex: "#38BDF8",
                    position: [-2.5, 0.9, 0.0]
                ),
                Scene3DActor(
                    actorId: "candle_lantern",
                    name: "Jack-o'-Lantern Safety FSM",
                    roleMetaphor: "Guards flame transitions and rejects stale sequence numbers",
                    codeSymbol: "CandleSafetyFSM.process_telemetry",
                    filePath: "mock_halloween_app/candle_safety_fsm.py",
                    lineRange: "L95-L142",
                    shapeType: "pumpkin_bot",
                    colorHex: "#F59E0B",
                    position: [0.0, 0.6, 0.0]
                ),
                Scene3DActor(
                    actorId: "thermal_breaker",
                    name: "CO2 Extinguisher Circuit Breaker",
                    roleMetaphor: "Trips OPEN at 85°C and locks out re-ignition until pumpkin cools below 40°C",
                    codeSymbol: "ThermalCircuitBreaker",
                    filePath: "mock_halloween_app/candle_safety_fsm.py",
                    lineRange: "L52-L90",
                    shapeType: "candy_vault",
                    colorHex: "#EF4444",
                    position: [2.3, 1.0, 0.0]
                )
            ],
            connections: [
                Scene3DConnection(
                    fromActorId: "zombie_postman",
                    toActorId: "candle_lantern",
                    label: "1. UDP Packet (seq=102, temp=89°C)",
                    packetType: "udp_telemetry",
                    colorHex: "#38BDF8"
                ),
                Scene3DConnection(
                    fromActorId: "candle_lantern",
                    toActorId: "thermal_breaker",
                    label: "2. Trip Breaker OPEN + CO2 Puff",
                    packetType: "thermal_trip",
                    colorHex: "#EF4444"
                )
            ],
            steps: [
                Scene3DAnimationStep(
                    stepIndex: 1,
                    actTitle: "Act I: High-Temp Packet #102 Trips the Breaker",
                    activeActorIds: ["zombie_postman", "candle_lantern", "thermal_breaker"],
                    packetFlow: "candle_lantern->thermal_breaker",
                    voiceoverNarration: "Packet #102 reports 89°C inside the pumpkin! The FSM advances `last_seq = 102`, trips the Thermal Circuit Breaker to `OPEN`, and fires an emergency CO2 puff.",
                    codeHighlightFile: "mock_halloween_app/candle_safety_fsm.py",
                    codeHighlightLines: "L108-L122",
                    codeSnippet: """
                    self.last_seq = packet.sequence_number
                    if packet.temp_celsius >= 85.0:
                        self.breaker.trip_open(now)
                        self.state = CandleState.EMERGENCY_EXTINGUISHED
                    """,
                    durationSeconds: 5.0
                ),
                Scene3DAnimationStep(
                    stepIndex: 2,
                    actTitle: "Act II: Delayed Zombie Packet #101 Arrives Late",
                    activeActorIds: ["zombie_postman", "candle_lantern"],
                    packetFlow: "zombie_postman->candle_lantern",
                    voiceoverNarration: "Three seconds later, Zombie Postman stumbles in with delayed Packet #101 (`temp=42°C, cmd=FLICKER`). Because `101 <= last_seq (102)`, the watermark guard drops it immediately!",
                    codeHighlightFile: "mock_halloween_app/candle_safety_fsm.py",
                    codeHighlightLines: "L101-L106",
                    codeSnippet: """
                    if packet.sequence_number <= self.last_seq:
                        self.metrics.stale_packets_dropped += 1
                        return self.state  # Ignore out-of-order UDP packet!
                    """,
                    durationSeconds: 5.0
                )
            ],
            breakItMutation: CounterfactualMutation(
                mutationId: "mut_2_stale_seq_guard",
                title: "Delete Out-of-Order Sequence & Version Guard",
                targetFile: "mock_halloween_app/candle_safety_fsm.py",
                targetLineRange: "L103-L105",
                codeLineRemoved: "if packet.sequence_number <= self.last_seq:",
                whatBreaksInCode: "Delayed or reordered UDP packets carrying older `sequence_number` values overwrite newer FSM states without rejection, allowing a stale normal packet from 3 seconds ago to re-ignite an overheating pumpkin.",
                cartoonChaosAnimation: "Zombie Postman shuffles in 5 minutes late with an old scroll! Because nobody checks the sequence number, all Jack-o'-Lanterns violently flicker between pitch-black darkness and blinding strobe fire in a chaotic graveyard disco glitch!",
                severity: "CRITICAL"
            )
        ),
        assessment: ChapterDidacticAssessment(
            chapterId: "sub_2_candle_fsm",
            unlocked: false,
            lockedReason: "Watch the 3D Halloween Cartoon Scene first so you see how Zombie Postman's out-of-order UDP scroll is blocked.",
            socraticOpeningQuestion: "Why can't we trust UDP arrival order when monitoring safety-critical IoT candle sensors?",
            flipCards: [
                FlipCard(
                    cardId: "card_candle_1",
                    chapterId: "sub_2_candle_fsm",
                    frontQuestion: "Why does `CandleSafetyFSM` reject any packet where `packet.sequence_number <= self.last_seq`?",
                    socraticHint: "What if packet #101 ('All Normal') takes a slower Wi-Fi hop than packet #102 ('89°C Emergency Shutdown')?",
                    backAnswer: "UDP packets can arrive out of order or duplicated. Without a monotonic watermark (`last_seq`), a delayed 'normal' packet would overwrite a newer 'emergency extinguished' state.",
                    codeReferenceFile: "mock_halloween_app/candle_safety_fsm.py",
                    codeReferenceLines: "L101-L106",
                    codeSnippet: "if packet.sequence_number <= self.last_seq:\n    return self.state",
                    difficulty: "EASY",
                    didacticTechnique: .activeRecallFlipcard
                ),
                FlipCard(
                    cardId: "card_candle_2",
                    chapterId: "sub_2_candle_fsm",
                    frontQuestion: "Why does the Thermal Circuit Breaker require cooling down to 40°C (`HALF_OPEN`) after tripping at 85°C instead of re-igniting at 84.9°C?",
                    socraticHint: "What happens if the flame turns back on at 84.9°C and immediately hits 85.0°C 10ms later?",
                    backAnswer: "Thermal hysteresis prevents rapid ON/OFF oscillation (chattering) around the trip threshold, protecting the igniter relay and ensuring the pumpkin shell actually cools.",
                    codeReferenceFile: "mock_halloween_app/candle_safety_fsm.py",
                    codeReferenceLines: "L68-L88",
                    codeSnippet: "if self.state == BreakerState.HALF_OPEN and temp_c <= 40.0:\n    self.reset_closed()",
                    difficulty: "MEDIUM",
                    didacticTechnique: .socraticMaieutics
                )
            ],
            parsonsBlocksShuffled: [
                ParsonsBlock(
                    blockId: "p2_step2",
                    correctOrderIndex: 1,
                    label: "Advance monotonic sequence watermark",
                    codeLine: "self.last_seq = packet.sequence_number"
                ),
                ParsonsBlock(
                    blockId: "p2_step1",
                    correctOrderIndex: 0,
                    label: "Drop stale or duplicate UDP packets at ingress",
                    codeLine: "if packet.sequence_number <= self.last_seq: return self.state"
                ),
                ParsonsBlock(
                    blockId: "p2_step3",
                    correctOrderIndex: 2,
                    label: "Trip thermal circuit breaker on overheat threshold",
                    codeLine: "if packet.temp_c >= 85.0: self.breaker.trip_open(); return CandleState.EXTINGUISHED"
                )
            ],
            feynmanPrompt: "Explain to Professor Quackula how the sequence number watermark and thermal circuit breaker stop delayed UDP packets from causing a pumpkin fire.",
            requiredConceptsForFeynman: [
                "sequence number",
                "state machine",
                "circuit breaker",
                "udp"
            ]
        ),
        sceneCompleted: false,
        answeredCards: [:],
        feynmanScore: nil,
        masteryPercentage: 0
    )

    // MARK: Chapter 3 — Allergy-Safe Candy Inventory & Dispatch Saga

    static let chapter3CandySaga = DidacticChapter(
        chapterId: "sub_3_candy_saga",
        orderIndex: 3,
        title: "Allergy-Safe Candy Inventory & Dispatch Saga",
        subtitle: "Zero-allergen set guards, CAS optimistic locking & Saga rollbacks",
        filePath: "mock_halloween_app/candy_router.py",
        architecturalPattern: "Optimistic Locking + Saga Rollback",
        spiralExplanations: SpiralExplanations(
            eli5Child: "Three Candy Goblins are packing your Ultimate Trick-or-Treat Bag: Choco-Goblin drops in a chocolate bar, Gummy-Goblin tosses in sour worms, and Lollipop-Goblin reaches into the third cauldron... Uh-oh! The Lollipop Cauldron is jammed shut! Because our rule is 'Every kid gets a complete, allergy-safe treat bag or everything goes back neatly,' the Chief Witch blows her Rewind Whistle, and Choco-Goblin and Gummy-Goblin put their candies right back on the shelf!",
            juniorDev: "Because inventory reservation and physical chute actuation span separate steps without a single SQL rollback, `CandySagaOrchestrator` first verifies zero allergen overlap (`kid.allergies & batch.allergens == set()`), reserves stock via Compare-And-Swap (`version + 1`), and if a downstream chute jams, runs `_rollback_reserved(reserved_batches)` in reverse order.",
            seniorArchitect: "Orchestrated Sagas avoid Two-Phase Commit (2PC) coordinator blocking while preserving eventual consistency across heterogeneous storage and physical IoT actuators. Pairing optimistic CAS version increments with idempotent reverse-order compensating actions and Dead Letter Queue (DLQ) alerting guarantees neither phantom stock depletion nor lost hardware fault visibility."
        ),
        scene3d: Scene3DPayload(
            chapterId: "sub_3_candy_saga",
            sceneTitle: "Three Candy Goblins & The Rewind Whistle",
            halloweenThemeSetting: "Enchanted Allergy-Safe Candy Vault",
            videoStoryboardUrl: "http://127.0.0.1:8000/static/player.html?chapter=sub_3_candy_saga",
            interactivePlayerUrl: "http://127.0.0.1:8000/static/player.html?chapter=sub_3_candy_saga",
            actors: [
                Scene3DActor(
                    actorId: "allergy_shield",
                    name: "Allergy Scanner Shield",
                    roleMetaphor: "Blocks any candy batch whose allergen set intersects the trick-or-treater's allergies",
                    codeSymbol: "verify_allergy_safe",
                    filePath: "mock_halloween_app/candy_router.py",
                    lineRange: "L38-L55",
                    shapeType: "bouncer_bat",
                    colorHex: "#10B981",
                    position: [-2.4, 1.0, 0.0]
                ),
                Scene3DActor(
                    actorId: "candy_vault",
                    name: "CAS Cauldron Vault (v7 -> v8)",
                    roleMetaphor: "Atomically decrements candy count only if version number matches expected snapshot",
                    codeSymbol: "CauldronInventory.reserve_cas",
                    filePath: "mock_halloween_app/candy_router.py",
                    lineRange: "L62-L94",
                    shapeType: "candy_vault",
                    colorHex: "#F43F5E",
                    position: [0.0, 0.7, 0.0]
                ),
                Scene3DActor(
                    actorId: "chief_witch",
                    name: "Chief Witch Saga Coordinator",
                    roleMetaphor: "Blows the Rewind Whistle to restore reserved candy in reverse order if a chute jams",
                    codeSymbol: "CandySagaOrchestrator._rollback_reserved",
                    filePath: "mock_halloween_app/candy_router.py",
                    lineRange: "L142-L170",
                    shapeType: "skeleton_conductor",
                    colorHex: "#C084FC",
                    position: [2.4, 1.1, 0.0]
                )
            ],
            connections: [
                Scene3DConnection(
                    fromActorId: "allergy_shield",
                    toActorId: "candy_vault",
                    label: "1. Zero-Allergen Match Verified",
                    packetType: "safe_order",
                    colorHex: "#10B981"
                ),
                Scene3DConnection(
                    fromActorId: "candy_vault",
                    toActorId: "chief_witch",
                    label: "2. Chute Jam -> Trigger Compensating Rollback",
                    packetType: "saga_rollback",
                    colorHex: "#C084FC"
                )
            ],
            steps: [
                Scene3DAnimationStep(
                    stepIndex: 1,
                    actTitle: "Act I: Hard Allergy Set-Intersection Check",
                    activeActorIds: ["allergy_shield"],
                    packetFlow: "allergy_shield->candy_vault",
                    voiceoverNarration: "Before touching a single cauldron, the Allergy Scanner Shield checks `order.allergies.intersection(batch.allergens)`. Peanut-containing treats are blocked at the perimeter!",
                    codeHighlightFile: "mock_halloween_app/candy_router.py",
                    codeHighlightLines: "L42-L51",
                    codeSnippet: """
                    overlap = order.allergies.intersection(batch.allergens)
                    if overlap:
                        raise AllergenSafetyBarrierError(f"Blocked allergens: {overlap}")
                    """,
                    durationSeconds: 5.0
                ),
                Scene3DAnimationStep(
                    stepIndex: 2,
                    actTitle: "Act II: CAS Reservation & Chute Jam Compensation",
                    activeActorIds: ["candy_vault", "chief_witch"],
                    packetFlow: "candy_vault->chief_witch",
                    voiceoverNarration: "When Lollipop Chute #3 jams after Chocolate and Gummy batches were reserved, Chief Witch iterates `reversed(reserved_batches)` to restore every single candy count and bump CAS versions.",
                    codeHighlightFile: "mock_halloween_app/candy_router.py",
                    codeHighlightLines: "L148-L164",
                    codeSnippet: """
                    except ChuteActuatorError as exc:
                        self._rollback_reserved(reserved_batches)
                        self.dlq.publish(order_id=order.order_id, reason=str(exc))
                    """,
                    durationSeconds: 5.0
                )
            ],
            breakItMutation: CounterfactualMutation(
                mutationId: "mut_3_saga_compensation",
                title: "Strip Compensating Saga Rollback on Chute Failure",
                targetFile: "mock_halloween_app/candy_router.py",
                targetLineRange: "L158-L161",
                codeLineRemoved: "self._rollback_reserved(reserved_batches)",
                whatBreaksInCode: "When the downstream lollipop chute throws a hardware jam error, upstream chocolate and gummy reservations are never released, leaking phantom inventory until the vault hits zero.",
                cartoonChaosAnimation: "The Lollipop Chute jams with a loud CLANK! Instead of putting the chocolates back, the Candy Goblins freeze clutching armfuls of reserved bars until mountains of phantom locked candy burst the vault doors!",
                severity: "CRITICAL"
            )
        ),
        assessment: ChapterDidacticAssessment(
            chapterId: "sub_3_candy_saga",
            unlocked: false,
            lockedReason: "Watch the 3D Halloween Cartoon Scene first to see Chief Witch's Saga Rewind Whistle in action.",
            socraticOpeningQuestion: "Why can't a regular database `ROLLBACK` undo a physical candy chute that jammed mid-dispense?",
            flipCards: [
                FlipCard(
                    cardId: "card_candy_1",
                    chapterId: "sub_3_candy_saga",
                    frontQuestion: "Why does `_rollback_reserved` iterate over `reversed(reserved_batches)` when a downstream step fails?",
                    socraticHint: "Think about how a multi-step workflow unwinds dependent reservations cleanly.",
                    backAnswer: "Compensating transactions execute in reverse order (LIFO) to undo intermediate reservations cleanly without leaving stranded `RESERVED` inventory.",
                    codeReferenceFile: "mock_halloween_app/candy_router.py",
                    codeReferenceLines: "L148-L165",
                    codeSnippet: "for receipt in reversed(reserved_batches):\n    self.inventory.compensate_release(receipt)",
                    difficulty: "MEDIUM",
                    didacticTechnique: .activeRecallFlipcard
                ),
                FlipCard(
                    cardId: "card_candy_2",
                    chapterId: "sub_3_candy_saga",
                    frontQuestion: "How does Compare-And-Swap (`expected_version`) prevent lost updates when two trick-or-treaters grab the last Sour Patch batch simultaneously?",
                    socraticHint: "Both workers read `qty=1, version=7` at the same millisecond.",
                    backAnswer: "The first worker commits `qty=0, version=8`. The second worker's update specifies `expected_version=7`, which no longer matches `8`, forcing a safe retry or out-of-stock response instead of driving inventory to `-1`.",
                    codeReferenceFile: "mock_halloween_app/candy_router.py",
                    codeReferenceLines: "L70-L89",
                    codeSnippet: "if batch.version != expected_version:\n    raise OptimisticLockConflictError()",
                    difficulty: "HARD",
                    didacticTechnique: .socraticMaieutics
                )
            ],
            parsonsBlocksShuffled: [
                ParsonsBlock(
                    blockId: "p3_step3",
                    correctOrderIndex: 2,
                    label: "On physical chute failure, run compensating rollback in reverse order",
                    codeLine: "except ChuteJamError: self._rollback_reserved(reserved_batches)"
                ),
                ParsonsBlock(
                    blockId: "p3_step1",
                    correctOrderIndex: 0,
                    label: "Verify zero intersection between kid allergies and batch allergens",
                    codeLine: "if order.allergies & batch.allergens: raise AllergenSafetyError()"
                ),
                ParsonsBlock(
                    blockId: "p3_step2",
                    correctOrderIndex: 1,
                    label: "Reserve inventory with Compare-And-Swap version increment",
                    codeLine: "receipt = self.vault.reserve_cas(batch.sku, expected_version=batch.version)"
                )
            ],
            feynmanPrompt: "Explain to Professor Quackula how the Allergy Scanner Shield, CAS version check, and Chief Witch's Saga Rollback keep trick-or-treaters safe and inventory accurate.",
            requiredConceptsForFeynman: [
                "saga",
                "rollback",
                "allergy",
                "version"
            ]
        ),
        sceneCompleted: false,
        answeredCards: [:],
        feynmanScore: nil,
        masteryPercentage: 0
    )

    // MARK: Chapter 4 — 500-Skeleton Animatronic 60fps Audio Sync Hub

    static let chapter4SpookySync = DidacticChapter(
        chapterId: "sub_4_spooky_sync",
        orderIndex: 4,
        title: "500-Skeleton Animatronic 60fps Audio Sync Hub",
        subtitle: "Drop-Oldest bounded ring buffers for zero-stall 128 BPM choreography",
        filePath: "mock_halloween_app/spooky_sync_engine.py",
        architecturalPattern: "Bounded Ring Buffer + Backpressure",
        spiralExplanations: SpiralExplanations(
            eli5Child: "Maestro Bone-Jangles is conducting 500 dancing skeletons to 'Spooky Scary Skeletons'! Every beat, he tosses glowing green music notes into a tiny 5-slot Magic Cauldron in front of each skeleton. If Skeleton #42 trips on its own funny bone and falls behind, its cauldron fills up to the brim! Instead of stopping the whole concert or letting the cauldron explode, the cauldron automatically pops out the oldest stale note from the bottom so Skeleton #42 can jump straight to the *newest* dance move right on beat with its 499 friends!",
            juniorDev: "Each skeleton dancer processes 60Hz motion-capture frames from a bounded `ring_buffer` (`collections.deque`). When a consumer lags and `len(self.buffer) >= self.max_capacity`, the ingestion loop explicitly calls `self.buffer.popleft()` to evict the oldest unconsumed frame before appending the incoming packet. This drop-oldest policy guarantees `O(1)` memory per subscriber and caps maximum choreography lag.",
            seniorArchitect: "In high-frequency real-time telemetry (60Hz skeletal kinematics across 500 fan-out consumers), state freshness strictly dominates historical delivery completeness. Unbounded queues turn transient consumer stalls into broker OOM crashes, whereas TCP-style producer backpressure induces head-of-line (HoL) blocking that throttles all 499 healthy dancers to the speed of the slowest straggler."
        ),
        scene3d: Scene3DPayload(
            chapterId: "sub_4_spooky_sync",
            sceneTitle: "Maestro Bone-Jangles & The 500-Skeleton Rave",
            halloweenThemeSetting: "128 BPM Neon Graveyard Concert Stage",
            videoStoryboardUrl: "http://127.0.0.1:8000/static/player.html?chapter=sub_4_spooky_sync",
            interactivePlayerUrl: "http://127.0.0.1:8000/static/player.html?chapter=sub_4_spooky_sync",
            actors: [
                Scene3DActor(
                    actorId: "skeleton_conductor",
                    name: "Maestro Bone-Jangles (60Hz Clock)",
                    roleMetaphor: "Broadcasts 128 BPM skeletal pose matrices every 16.6ms without ever blocking",
                    codeSymbol: "SpookySyncEngine.broadcast_tick",
                    filePath: "mock_halloween_app/spooky_sync_engine.py",
                    lineRange: "L98-L136",
                    shapeType: "skeleton_conductor",
                    colorHex: "#34D399",
                    position: [-2.4, 1.2, 0.0]
                ),
                Scene3DActor(
                    actorId: "cauldron_queue",
                    name: "Magic Ring-Buffer Cauldron (maxlen=8)",
                    roleMetaphor: "Evicts the oldest unplayed dance note (`popleft`) when a lagging skeleton's queue fills up",
                    codeSymbol: "BoundedRingBuffer.push_frame",
                    filePath: "mock_halloween_app/spooky_sync_engine.py",
                    lineRange: "L44-L78",
                    shapeType: "cauldron_queue",
                    colorHex: "#A3E635",
                    position: [0.0, 0.6, 0.0]
                ),
                Scene3DActor(
                    actorId: "skeleton_dancer_42",
                    name: "Lagging Skeleton #42 (Edge Wi-Fi)",
                    roleMetaphor: "Snaps straight to the newest dance beat on reconnect instead of replaying stale moves",
                    codeSymbol: "SkeletonSubscriber",
                    filePath: "mock_halloween_app/spooky_sync_engine.py",
                    lineRange: "L20-L42",
                    shapeType: "pumpkin_bot",
                    colorHex: "#60A5FA",
                    position: [2.4, 0.9, 0.0]
                )
            ],
            connections: [
                Scene3DConnection(
                    fromActorId: "skeleton_conductor",
                    toActorId: "cauldron_queue",
                    label: "1. 60Hz Pose Frame #F",
                    packetType: "pose_keyframe",
                    colorHex: "#34D399"
                ),
                Scene3DConnection(
                    fromActorId: "cauldron_queue",
                    toActorId: "skeleton_dancer_42",
                    label: "2. Popleft Stale -> Deliver Fresh Beat",
                    packetType: "fresh_frame",
                    colorHex: "#60A5FA"
                )
            ],
            steps: [
                Scene3DAnimationStep(
                    stepIndex: 1,
                    actTitle: "Act I: Non-Blocking 60Hz Fan-Out",
                    activeActorIds: ["skeleton_conductor", "cauldron_queue"],
                    packetFlow: "skeleton_conductor->cauldron_queue",
                    voiceoverNarration: "Maestro Bone-Jangles pushes 60 keyframes per second into each skeleton's dedicated Ring-Buffer Cauldron so one slow Wi-Fi link never blocks the main broadcast loop.",
                    codeHighlightFile: "mock_halloween_app/spooky_sync_engine.py",
                    codeHighlightLines: "L54-L66",
                    codeSnippet: """
                    if len(self.buffer) >= self.max_capacity:
                        evicted = self.buffer.popleft()  # Drop-Oldest backpressure!
                        self.dropped_frames += 1
                    self.buffer.append(frame)
                    """,
                    durationSeconds: 5.0
                ),
                Scene3DAnimationStep(
                    stepIndex: 2,
                    actTitle: "Act II: Skeleton #42 Snaps Back to the Beat",
                    activeActorIds: ["cauldron_queue", "skeleton_dancer_42"],
                    packetFlow: "cauldron_queue->skeleton_dancer_42",
                    voiceoverNarration: "When Skeleton #42's Wi-Fi recovers after a 300ms hiccup, old frames were already evicted from the bottom of the cauldron, so Skeleton #42 immediately dances on the live beat!",
                    codeHighlightFile: "mock_halloween_app/spooky_sync_engine.py",
                    codeHighlightLines: "L112-L128",
                    codeSnippet: """
                    latest_frame = subscriber.ring_buffer.pop_latest()
                    subscriber.apply_joint_pose(latest_frame)
                    """,
                    durationSeconds: 5.0
                )
            ],
            breakItMutation: CounterfactualMutation(
                mutationId: "mut_4_ring_buffer_eviction",
                title: "Remove Ring-Buffer Drop-Oldest Eviction on Full Queue",
                targetFile: "mock_halloween_app/spooky_sync_engine.py",
                targetLineRange: "L55-L57",
                codeLineRemoved: "self.buffer.popleft()",
                whatBreaksInCode: "When a skeleton consumer experiences a transient Wi-Fi stall, new 60Hz packets either block the producer (freezing all 500 skeletons) or accumulate unboundedly in memory until an OOM crash.",
                cartoonChaosAnimation: "The Magic Cauldron Queue refuses to drop old music notes! Glowing green notes inflate the cauldron like an overfilled balloon—Skeleton #42 is stuck doing last Tuesday's Macarena while everyone else does the Moonwalk, until KABOOM! The cauldron explodes!",
                severity: "CRITICAL"
            )
        ),
        assessment: ChapterDidacticAssessment(
            chapterId: "sub_4_spooky_sync",
            unlocked: false,
            lockedReason: "Watch the 3D Halloween Cartoon Scene first so you see Maestro Bone-Jangles & the Magic Ring-Buffer Cauldron in action.",
            socraticOpeningQuestion: "For live 60fps dance choreography, why is dropping old frames better than waiting for every single frame to be delivered?",
            flipCards: [
                FlipCard(
                    cardId: "card_sync_1",
                    chapterId: "sub_4_spooky_sync",
                    frontQuestion: "Why does `BoundedRingBuffer` use a Drop-Oldest (`popleft()`) policy instead of blocking when full?",
                    socraticHint: "What happens to the other 499 skeletons if Maestro Bone-Jangles waits for Skeleton #42's slow Wi-Fi?",
                    backAnswer: "Blocking the producer causes head-of-line blocking that freezes all 499 healthy skeletons; dropping the oldest frame bounds memory to `O(1)` and keeps lagging skeletons synced to the live beat.",
                    codeReferenceFile: "mock_halloween_app/spooky_sync_engine.py",
                    codeReferenceLines: "L54-L66",
                    codeSnippet: "if len(self.buffer) >= self.max_capacity:\n    self.buffer.popleft()",
                    difficulty: "EASY",
                    didacticTechnique: .activeRecallFlipcard
                ),
                FlipCard(
                    cardId: "card_sync_2",
                    chapterId: "sub_4_spooky_sync",
                    frontQuestion: "Why is Drop-Oldest preferable to Drop-Newest for real-time skeletal pose telemetry?",
                    socraticHint: "Which frame represents where the music beat is *right now*?",
                    backAnswer: "Drop-Oldest discards obsolete historical poses and retains the freshest state so the consumer renders the current beat rather than stale poses from seconds ago.",
                    codeReferenceFile: "mock_halloween_app/spooky_sync_engine.py",
                    codeReferenceLines: "L54-L72",
                    codeSnippet: "self.buffer.popleft()\nself.buffer.append(new_frame)",
                    difficulty: "MEDIUM",
                    didacticTechnique: .socraticMaieutics
                )
            ],
            parsonsBlocksShuffled: [
                ParsonsBlock(
                    blockId: "p4_step2",
                    correctOrderIndex: 1,
                    label: "Evict oldest stale frame to bound queue memory and latency",
                    codeLine: "self.buffer.popleft(); self.dropped_count += 1"
                ),
                ParsonsBlock(
                    blockId: "p4_step1",
                    correctOrderIndex: 0,
                    label: "Check if per-client ring buffer has reached max_capacity",
                    codeLine: "if len(self.buffer) >= self.max_capacity:"
                ),
                ParsonsBlock(
                    blockId: "p4_step3",
                    correctOrderIndex: 2,
                    label: "Append fresh 60Hz keyframe without blocking broadcast loop",
                    codeLine: "self.buffer.append(frame)"
                )
            ],
            feynmanPrompt: "Explain to Professor Quackula why Maestro Bone-Jangles uses a bounded ring buffer with Drop-Oldest backpressure so one lagging skeleton on bad Wi-Fi never ruins the 500-skeleton dance.",
            requiredConceptsForFeynman: [
                "ring buffer",
                "drop oldest",
                "backpressure",
                "blocking"
            ]
        ),
        sceneCompleted: false,
        answeredCards: [:],
        feynmanScore: nil,
        masteryPercentage: 0
    )
}
