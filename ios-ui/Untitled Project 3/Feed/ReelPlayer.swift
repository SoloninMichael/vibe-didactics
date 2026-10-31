import VibieKit
import Foundation

/// One chapter of a reel. Five beats of ~4 seconds make the 20-second explainer.
enum Beat: Hashable {
    case gist, location, code, why, risk
    case done, summary, next

    var label: String {
        switch self {
        case .gist: "THE GIST"
        case .location: "WHERE"
        case .code: "THE CODE"
        case .why: "WHY"
        case .risk: "VIBE CHECK"
        case .done: "CHECKPOINT"
        case .summary: "WHAT IT DID"
        case .next: "WHAT'S NEXT"
        }
    }

    static func sequence(for card: ChangeCard) -> [Beat] {
        switch card.kind {
        case .command: [.gist, .code, .why, .risk]
        case .checkpoint: [.done, .summary, .next]
        default: [.gist, .location, .code, .why, .risk]
        }
    }
}

/// Drives a reel's beats like stories: tap to pause, tap the edges to skip.
@Observable
final class ReelPlayer {
    private(set) var index = 0
    private(set) var progress = 0.0
    private(set) var isPaused = false
    private(set) var finished = false

    @ObservationIgnored private var durations: [Double] = []
    @ObservationIgnored private var task: Task<Void, Never>?

    init() {
        #if DEBUG
        // Stable chapters for presentation screenshots without changing release playback.
        if UserDefaults.standard.bool(forKey: "holdReel") {
            isPaused = true
            index = max(0, UserDefaults.standard.integer(forKey: "reelBeat"))
        }
        #endif
    }

    func play(durations: [Double]) {
        self.durations = durations
        if finished { restart(); return }
        index = min(index, max(durations.count - 1, 0))
        startLoop()
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    func togglePause() {
        isPaused.toggle()
    }

    func restart() {
        index = 0
        progress = 0
        finished = false
        isPaused = false
        startLoop()
    }

    func next() {
        if index < durations.count - 1 {
            index += 1
            progress = 0
        } else {
            progress = 1
            finished = true
        }
        isPaused = false
    }

    func previous() {
        if progress < 0.2, index > 0 { index -= 1 }
        progress = 0
        finished = false
        isPaused = false
    }

    private func startLoop() {
        task?.cancel()
        task = Task { [weak self] in
            var last = ContinuousClock.now
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(33))
                guard let self else { return }
                let now = ContinuousClock.now
                let elapsed = (now - last) / .seconds(1)
                last = now
                guard !self.isPaused, !self.finished, self.index < self.durations.count else { continue }
                self.progress += elapsed / self.durations[self.index]
                if self.progress >= 1 { self.next() }
            }
        }
    }
}
