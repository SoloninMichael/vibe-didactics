import VibieKit
import SwiftUI

struct Toast: Identifiable, Equatable {
    let id = UUID()
    var symbol: String
    var text: String
    var tint: Color
}

struct DecisionRequest: Identifiable {
    let item: ReelItem
    var suggestedNote = ""
    var id: UUID { item.id }
}

enum FeedPage: Hashable {
    case card(UUID)
    case end
}

enum ReelSheet: String, Identifiable {
    case ask, quiz, code
    var id: String { rawValue }
}

/// Tabs of the glass inspector beside the reel when an iPhone Duo is unfolded.
enum InspectorTab: String, CaseIterable, Identifiable {
    case code, ask, quiz, queue
    var id: String { rawValue }

    var title: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .code: "chevron.left.forwardslash.chevron.right"
        case .ask: "sparkles"
        case .quiz: "gamecontroller.fill"
        case .queue: "list.bullet.rectangle.portrait.fill"
        }
    }
}

/// The guided walkthrough shown during the first demo session.
enum CoachStep: Equatable {
    case tapAround, tryTools, swipeUp, agentWorks

    var text: String {
        switch self {
        case .tapAround: "Tap the right edge to skip ahead · middle to pause"
        case .tryTools: "Confused? Tap Ask or take the Quiz"
        case .swipeUp: "Swipe up for the next change — then approve or deny"
        case .agentWorks: "Claude keeps working on your Mac. New reels land as it goes."
        }
    }

    var symbol: String {
        switch self {
        case .tapAround: "hand.tap.fill"
        case .tryTools: "sparkles"
        case .swipeUp: "hand.draw.fill"
        case .agentWorks: "bolt.horizontal.fill"
        }
    }
}

enum CoachEvent { case tapped, openedTool, reelFinished, swiped, decided }

/// The feed. Lives in memory only: closing the app forgets every reel.
@Observable
final class ReelStore {
    enum Mode { case demo, live }

    var items: [ReelItem] = []
    var mode: Mode = .demo
    var agentStatus: AgentStatus?
    var toast: Toast?
    var prompt: DecisionRequest?
    var jumpTarget: FeedPage?
    /// True while a full-screen panel covers the feed, so reels pause.
    var panelOpen = false
    /// The reel currently on screen.
    var activeID: UUID?
    /// Unfolded iPhone Duo (or any wide screen): reel and inspector side by side.
    var studio = false
    var inspectorTab: InspectorTab = .code
    /// Ask the active reel to open one of its sheets (used by the walkthrough and screenshots).
    var requestedSheet: ReelSheet?
    var coach: CoachStep?
    var showIntro = !UserDefaults.standard.bool(forKey: "seenIntro")
    var voiceOn = (UserDefaults.standard.object(forKey: "voiceOn") as? Bool) ?? true {
        didSet {
            UserDefaults.standard.set(voiceOn, forKey: "voiceOn")
            if !voiceOn { Narrator.shared.stop() }
        }
    }

    @ObservationIgnored private weak var bridge: BridgeClient?
    @ObservationIgnored private let demo = DemoAgent()
    @ObservationIgnored private var promptQueue: [UUID] = []
    @ObservationIgnored private var enhanceQueue: [UUID] = []
    @ObservationIgnored private var enhanceTask: Task<Void, Never>?
    @ObservationIgnored private var toastTask: Task<Void, Never>?
    @ObservationIgnored private var demoSession = UUID()

    var pendingCount: Int { items.count { $0.status.isPending } }
    var totalRedactions: Int { items.reduce(0) { $0 + $1.card.redactions } }
    var firstPending: ReelItem? { items.first { $0.status.isPending } }
    var knownFiles: [String] { items.compactMap(\.card.fileName) }
    var activeItem: ReelItem? { activeID.flatMap(item) }

    func item(_ id: UUID) -> ReelItem? {
        items.first { $0.id == id }
    }

    func connect(_ bridge: BridgeClient) {
        print("[vibie] connect called, bridge set:", self.bridge != nil)
        guard self.bridge == nil else { return }
        self.bridge = bridge
        bridge.onMessage = { [weak self] message in self?.receive(message) }
        if bridge.isPaired {
            mode = .live
            bridge.connect()
        } else {
            startDemo()
        }
        #if DEBUG
        applyDebugScene()
        #endif
    }

    // MARK: Modes

    func startDemo() {
        mode = .demo
        demo.reset()
        resetFeed(with: demo.opening())
        agentStatus = demo.status(.waiting, "Waiting for you to review")
        coach = UserDefaults.standard.bool(forKey: "coachDone") ? nil : .tapAround
    }

    func leaveDemo() {
        mode = .live
        resetFeed(with: [])
        agentStatus = nil
        coach = nil
        bridge?.connect()
    }

    func wipe() {
        Narrator.shared.stop()
        if mode == .demo { startDemo() } else { resetFeed(with: []) }
        show(Toast(symbol: "trash.fill", text: "Session wiped from this iPhone", tint: .white))
    }

    private func resetFeed(with reels: [ReelItem]) {
        demoSession = UUID()
        prompt = nil
        requestedSheet = nil
        promptQueue = []
        enhanceQueue = []
        items = reels
        items.forEach(enhance)
    }

    // MARK: From the bridge

    func receive(_ message: WireMessage) {
        switch message {
        case .welcome(let info):
            if mode == .demo { leaveDemo() }
            show(Toast(symbol: "lock.shield.fill", text: "Connected to \(info.name) · end-to-end encrypted", tint: .mint))
        case .card(let card):
            guard item(card.id) == nil else { return }
            let item = ReelItem(card: card)
            items.append(item)
            enhance(item)
        case .resolved(let id, let reason):
            guard let item = item(id), item.status.isPending else { return }
            item.status = .elsewhere(reason)
            promptQueue.removeAll { $0 == id }
            if prompt?.id == id { advancePrompt() }
        case .status(let status):
            agentStatus = status
        case .decision, .ping, .pong:
            break
        }
    }

    // MARK: Decisions

    func userSwiped(past item: ReelItem) {
        guard item.status.isPending, prompt?.id != item.id, !promptQueue.contains(item.id) else { return }
        if prompt == nil {
            prompt = DecisionRequest(item: item)
        } else {
            promptQueue.append(item.id)
        }
        coach(.swiped)
    }

    func requestDecision(for item: ReelItem, note: String = "") {
        guard item.status.isPending else { return }
        promptQueue.removeAll { $0 == item.id }
        prompt = DecisionRequest(item: item, suggestedNote: note)
    }

    func decideLater() {
        advancePrompt()
    }

    func decide(_ item: ReelItem, _ verdict: Verdict, note: String?) {
        defer { advancePrompt() }
        guard item.status.isPending else { return }
        let note = note?.nilIfBlank
        item.status = verdict == .approve ? .approved : .denied
        item.note = note ?? ""

        switch mode {
        case .live: bridge?.send(.decision(DecisionPayload(cardID: item.id, verdict: verdict, note: note)))
        case .demo: runDemoAgent(after: item, verdict: verdict)
        }
        coach(.decided)

        let agent = item.card.agent.shortName
        switch (item.card.kind == .checkpoint, verdict) {
        case (true, .approve): show(Toast(symbol: "paperplane.fill", text: "Sent — \(agent) is on it", tint: .mint))
        case (true, .deny): show(Toast(symbol: "moon.zzz.fill", text: "\(agent) will wrap up here", tint: .indigo))
        case (false, .approve): show(Toast(symbol: "checkmark.circle.fill", text: "Approved — \(agent) is back to work", tint: .green))
        case (false, .deny): show(Toast(symbol: "xmark.circle.fill", text: note == nil ? "Denied — \(agent) will try another way" : "Denied — \(agent) got your note", tint: .pink))
        }
    }

    func jumpToNextPending() {
        if let next = firstPending { jumpTarget = .card(next.id) }
    }

    func show(_ toast: Toast) {
        self.toast = toast
        toastTask?.cancel()
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.6))
            if self?.toast?.id == toast.id { self?.toast = nil }
        }
    }

    // MARK: Walkthrough

    func coach(_ event: CoachEvent) {
        guard mode == .demo, let step = coach else { return }
        switch (step, event) {
        case (.tapAround, .tapped):
            coach = .tryTools
        case (.tapAround, .reelFinished), (.tryTools, .openedTool), (.tryTools, .reelFinished):
            coach = .swipeUp
        case (_, .decided):
            coach = .agentWorks
            UserDefaults.standard.set(true, forKey: "coachDone")
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(6))
                if self?.coach == .agentWorks { self?.coach = nil }
            }
        case (.swipeUp, .swiped):
            coach = nil
        default:
            break
        }
    }

    func finishIntro() {
        UserDefaults.standard.set(true, forKey: "seenIntro")
        showIntro = false
    }

    func replayIntro() {
        UserDefaults.standard.set(false, forKey: "coachDone")
        showIntro = true
        if mode == .demo { startDemo() }
    }

    #if DEBUG
    /// `-scene prompt|ask|quiz|code|end|intro|card:N` jumps straight to a state, for screenshots.
    private func applyDebugScene() {
        print("[vibie] debug scene:", UserDefaults.standard.string(forKey: "scene") ?? "nil", "showIntro:", showIntro)
        guard let scene = UserDefaults.standard.string(forKey: "scene") else { return }
        showIntro = scene == "intro"
        if scene != "coach" { coach = nil }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.2))
            guard let self else { return }
            switch scene {
            case "prompt":
                if let first = self.items.first { self.requestDecision(for: first) }
            case "end":
                self.jumpTarget = .end
            case "ask", "quiz", "code":
                self.inspectorTab = InspectorTab(rawValue: scene) ?? .code
                if !self.studio { self.requestedSheet = ReelSheet(rawValue: scene) }
            case "queue":
                self.inspectorTab = .queue
            default:
                if scene.hasPrefix("card:"), let n = Int(scene.dropFirst(5)), n >= 0 {
                    while self.items.count <= n, let item = self.demo.next() {
                        self.items.append(item)
                    }
                    if self.items.indices.contains(n) {
                        self.jumpTarget = .card(self.items[n].id)
                    }
                }
            }
        }
    }
    #endif

    private func advancePrompt() {
        prompt = nil
        while !promptQueue.isEmpty {
            let id = promptQueue.removeFirst()
            if let next = item(id), next.status.isPending {
                prompt = DecisionRequest(item: next)
                return
            }
        }
    }

    // MARK: On-device explainers

    /// Upgrades the instant heuristic explainer with one written by the on-device model.
    private func enhance(_ item: ReelItem) {
        // Keep the curated lesson and its supplied quiz consistent across presentation devices.
        guard item.demoLesson == nil else { return }
        guard OnDeviceAI.isAvailable else { return }
        enhanceQueue.append(item.id)
        guard enhanceTask == nil else { return }
        enhanceTask = Task { [weak self] in
            while let self, !self.enhanceQueue.isEmpty {
                let id = self.enhanceQueue.removeFirst()
                guard let item = self.item(id) else { continue }
                if let better = try? await OnDeviceAI.explainer(for: item.card, quick: item.explainer) {
                    withAnimation(.smooth) { item.explainer = better }
                }
            }
            self?.enhanceTask = nil
        }
    }

    // MARK: Demo

    private func runDemoAgent(after item: ReelItem, verdict: Verdict) {
        let session = demoSession
        agentStatus = demo.status(.working, verdict == .approve
            ? "Applying \(item.card.fileName ?? "that step")…"
            : "Rethinking that step…")
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.8))
            guard let self, self.mode == .demo, self.demoSession == session else { return }
            if let next = self.demo.next() {
                self.items.append(next)
                self.enhance(next)
                self.agentStatus = self.demo.status(.waiting, "Waiting for you to review")
            } else if self.pendingCount == 0 {
                self.agentStatus = self.demo.status(.idle, "Demo complete — pair your Mac for the real thing")
            }
        }
    }
}
