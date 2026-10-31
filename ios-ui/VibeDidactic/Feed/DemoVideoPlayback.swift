import AVFoundation
import SwiftUI

/// The actual movie is the clock for a video story; the synthetic 20-second reel timer stays idle.
@Observable
@MainActor
final class DemoVideoPlayback {
    @ObservationIgnored let player = AVPlayer()
    private(set) var duration = 0.0
    private(set) var elapsed = 0.0
    private(set) var isPaused = false
    private(set) var finished = false
    private(set) var loading = true
    private(set) var errorMessage: String?

    @ObservationIgnored private var active = false
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var endObserver: NSObjectProtocol?
    @ObservationIgnored private var statusObserver: NSKeyValueObservation?
    @ObservationIgnored private var configuredURL: URL?

    var progress: Double { duration > 0 ? min(max(elapsed / duration, 0), 1) : 0 }

    init() {
        player.actionAtItemEnd = .pause
        player.isMuted = true
    }

    deinit {
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
    }

    func configure(url: URL?) async {
        guard let url else {
            loading = false
            errorMessage = "The demo video couldn't be found. You can still explore the code and quiz."
            return
        }
        guard configuredURL != url else { return }
        configuredURL = url
        do {
            let asset = AVURLAsset(url: url)
            let seconds = try await asset.load(.duration).seconds
            guard !Task.isCancelled else { return }
            guard seconds.isFinite, seconds > 0 else {
                loading = false
                errorMessage = "The demo video couldn't be opened. You can still explore the code and quiz."
                return
            }
            duration = seconds
            let item = AVPlayerItem(asset: asset)
            player.replaceCurrentItem(with: item)
            timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { [weak self] time in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.elapsed = max(0, time.seconds.isFinite ? time.seconds : 0)
                }
            }
            endObserver = NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: item, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.elapsed = self.duration
                    self.finished = true
                }
            }
            statusObserver = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
                let failed = item.status == .failed
                let ready = item.status == .readyToPlay
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if failed {
                        self.loading = false
                        self.errorMessage = "The demo video couldn't be played. You can still explore the code and quiz."
                    } else if ready {
                        self.loading = false
                    }
                }
            }
            updatePlayback()
        } catch {
            guard !Task.isCancelled else { return }
            loading = false
            errorMessage = "The demo video couldn't be opened. You can still explore the code and quiz."
        }
    }

    func setActive(_ active: Bool) {
        self.active = active
        updatePlayback()
    }

    func setMuted(_ muted: Bool) { player.isMuted = muted }

    func togglePause() {
        if finished { restart(); return }
        isPaused.toggle()
        updatePlayback()
    }

    func skip(by seconds: Double) {
        guard duration > 0 else { return }
        elapsed = min(max(elapsed + seconds, 0), duration)
        finished = elapsed >= duration
        player.seek(to: CMTime(seconds: elapsed, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
        updatePlayback()
    }

    func restart() {
        elapsed = 0
        finished = false
        isPaused = false
        player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        updatePlayback()
    }

    private func updatePlayback() {
        if active && !isPaused && !finished && errorMessage == nil {
            player.play()
        } else {
            player.pause()
        }
    }
}

struct DemoVideoStage: View {
    let playback: DemoVideoPlayback

    var body: some View {
        ZStack {
            MovieSurface(player: playback.player)
                .allowsHitTesting(false)
            if let message = playback.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "video.slash").font(.title)
                    Text(message).font(.subheadline).multilineTextAlignment(.center)
                }
                .padding(20)
            } else if playback.loading {
                ProgressView("Loading video…")
            }
        }
        .background(.black)
        .clipShape(.rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.1)))
    }
}

/// Aspect fit preserves the captions and code already present in the supplied portrait movie.
private struct MovieSurface: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> Surface {
        let view = Surface()
        view.playerLayer.videoGravity = .resizeAspect
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ view: Surface, context: Context) { view.playerLayer.player = player }

    final class Surface: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}

/// Kept visible beside demo stories, including while a movie or quiz is open.
struct DemoRiskOverview: View {
    let item: ReelItem

    var body: some View {
        HStack(spacing: 16) {
            RiskMeter(level: item.explainer.risk)
                .frame(width: 80, height: 42)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(item.explainer.risk.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(item.explainer.risk.color)
                Text(item.explainer.watchOut)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(.white.opacity(0.035), in: .rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.07)))
    }
}
