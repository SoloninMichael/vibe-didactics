import SwiftUI
import VibieKit

/// One full-screen reel explaining one change.
struct ReelView: View {
    let item: ReelItem
    let isActive: Bool
    /// Where the reel's own chrome may start and end (already clear of the header and home indicator).
    let insets: EdgeInsets
    @Environment(ReelStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var player = ReelPlayer()
    @State private var video = DemoVideoPlayback()
    @State private var sheet: ReelSheet?

    private var beats: [Beat] { Beat.sequence(for: item.card) }
    private var beat: Beat { beats[min(player.index, beats.count - 1)] }
    private var hasVideo: Bool { item.demoLesson?.videoResource != nil }
    private var storyFinished: Bool { hasVideo ? video.finished : player.finished }
    private var storyPaused: Bool { hasVideo ? video.isPaused : player.isPaused }
    private var playing: Bool { isActive && sheet == nil && !store.panelOpen && scenePhase == .active }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ReelBackground(palette: item.palette, animate: playing)
                tapZones

                VStack(alignment: .leading, spacing: 18) {
                    chapterHeader

                    Group {
                        if hasVideo {
                            DemoVideoStage(playback: video)
                        } else {
                            BeatStage(item: item, beat: beat)
                        }
                    }
                        .environment(\.reelStageLayout, ReelStageLayout(width: geo.size.width - 40, height: geo.size.height - 260))
                        .id(beat)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 16)),
                            removal: .opacity.combined(with: .offset(y: -8))))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .allowsHitTesting(beat == .next)

                    VStack(alignment: .leading, spacing: 14) {
                        if storyFinished, item.status.isPending {
                            SwipeHint()
                                .frame(maxWidth: .infinity)
                                .transition(.opacity)
                        }
                        ReelMeta(item: item, caption: item.caption(for: beat))
                        if hasVideo, !store.studio { DemoRiskOverview(item: item) }
                        ActionRail(item: item, compact: store.studio, hasVideo: hasVideo,
                                   paused: storyPaused || storyFinished, open: open,
                                   onReplay: replay, onTogglePlayback: togglePlayback)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, insets.top + 18)
                .padding(.bottom, insets.bottom + 16)
            }
        }
        .animation(.spring(duration: 0.5), value: beat)
        .animation(.spring(duration: 0.4, bounce: 0.45), value: item.status)
        .onChange(of: playing, initial: true) { _, now in
            if hasVideo {
                if now { Narrator.shared.stop() }
                video.setActive(now)
                return
            }
            if now {
                player.play(durations: durations)
                speak()
            } else {
                player.stop()
                if isActive { Narrator.shared.stop() }
            }
        }
        .onChange(of: player.index) { speak() }
        .onChange(of: storyFinished) { _, finished in
            if finished, isActive { store.coach(.reelFinished) }
        }
        .onChange(of: store.voiceOn) { _, on in
            if hasVideo { video.setMuted(!on); return }
            guard playing else { return }
            if on { speak() }
            player.play(durations: durations)
        }
        .task {
            guard hasVideo else { return }
            video.setMuted(!store.voiceOn)
            await video.configure(url: item.demoLesson?.videoURL)
        }
        .onDisappear {
            video.setActive(false)
            player.stop()
        }
        .onChange(of: store.requestedSheet, initial: true) { _, requested in
            guard let requested, isActive else { return }
            store.requestedSheet = nil
            open(requested)
        }
        .sheet(item: $sheet) { sheet in
            Group {
                switch sheet {
                case .ask: AskSheet(item: item)
                case .quiz: QuizSheet(item: item, otherFiles: store.knownFiles)
                case .code: CodeSheet(item: item)
                }
            }
            .environment(store)
            .preferredColorScheme(.dark)
        }
    }

    private var durations: [Double] {
        let base = 20.0 / Double(beats.count)
        guard store.voiceOn else { return beats.map { _ in base } }
        return beats.map { max(base, Narrator.estimatedDuration(item.narration(for: $0))) }
    }

    private func speak() {
        guard !hasVideo, playing, store.voiceOn else { return }
        Narrator.shared.speak(item.narration(for: beat))
    }

    private func replay() {
        if hasVideo { video.restart() } else { player.restart() }
    }

    private func togglePlayback() {
        if hasVideo { video.togglePause() } else { player.togglePause() }
        store.coach(.tapped)
    }

    /// On a phone, tools open as sheets; unfolded, they switch the glass inspector instead.
    private func open(_ tool: ReelSheet) {
        store.coach(.openedTool)
        if store.studio {
            withAnimation(.bouncy) { store.inspectorTab = InspectorTab(rawValue: tool.rawValue) ?? .code }
        } else {
            sheet = tool
        }
    }

    // MARK: Layers

    private var tapZones: some View {
        HStack(spacing: 0) {
            Color.clear.contentShape(.rect)
                .onTapGesture {
                    if hasVideo { video.skip(by: -5) } else { player.previous() }
                    store.coach(.tapped)
                }
                .frame(maxWidth: .infinity)
            Color.clear.contentShape(.rect)
                .onTapGesture(perform: togglePlayback)
                .frame(maxWidth: .infinity)
            Color.clear.contentShape(.rect)
                .onTapGesture {
                    if hasVideo { video.skip(by: 5) } else { player.next() }
                    store.coach(.tapped)
                }
                .frame(maxWidth: .infinity)
        }
        .animation(.snappy, value: player.isPaused)
    }

    private var chapterHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProgressSegments(player: player, count: hasVideo ? 1 : beats.count, mediaProgress: hasVideo ? video.progress : nil)
            HStack(spacing: 8) {
                Text(String(format: "%02d", min(player.index, beats.count - 1) + 1))
                    .foregroundStyle(item.palette.primary)
                Text(hasVideo ? (item.demoLesson?.videoLabel.uppercased() ?? "VIDEO") : beat.label)
                    .tracking(1.6)
                    .contentTransition(.opacity)
                Spacer(minLength: 4)
                if item.status.isPending {
                    Text(storyPaused ? "PAUSED" : hasVideo ? (video.duration > 0 ? "\(Int(video.duration.rounded()))s" : "VIDEO") : "20s")
                        .foregroundStyle(storyPaused ? .cyan : .white.opacity(0.45))
                } else {
                    Image(systemName: item.status == .approved ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(item.status == .approved ? .mint : .pink)
                        .accessibilityLabel(item.status == .approved ? "Approved" : "Reviewed")
                }
            }
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(.white.opacity(0.65))
        }
        .allowsHitTesting(false)
    }

}

struct ProgressSegments: View {
    let player: ReelPlayer
    let count: Int
    var mediaProgress: Double?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(.white.opacity(0.22))
                    .overlay(alignment: .leading) {
                        GeometryReader { geo in
                            Capsule().fill(.white).frame(width: geo.size.width * fill(index))
                        }
                    }
                    .frame(height: 3)
            }
        }
    }

    private func fill(_ index: Int) -> CGFloat {
        if let mediaProgress { return CGFloat(min(max(mediaProgress, 0), 1)) }
        if index < player.index { return 1 }
        if index == player.index { return CGFloat(min(player.progress, 1)) }
        return 0
    }
}

private struct ReelMeta: View {
    let item: ReelItem
    let caption: String

    private var card: ChangeCard { item.card }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Image(systemName: "sparkle")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(item.palette.primary)
                    .frame(width: 26, height: 26)
                    .background(item.palette.primary.opacity(0.12), in: .circle)
                Text(card.agent.shortName).font(.system(size: 12, weight: .semibold))
                Text("/  " + card.project)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer(minLength: 0)
                if item.explainer.source == .onDevice {
                    Image(systemName: "apple.intelligence").foregroundStyle(.purple)
                }
            }
            .lineLimit(1)

            HStack(spacing: 8) {
                Label(card.fileName ?? card.command ?? card.project,
                      systemImage: card.command == nil ? "doc.text" : "terminal")
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 0)
                if card.kind == .edit || card.kind == .create {
                    Text("+\(card.additions)").foregroundStyle(.mint)
                    Text("−\(card.deletions)").foregroundStyle(.pink)
                }
            }
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(.white.opacity(0.6))

            Text(caption)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
                .animation(.easeInOut, value: caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .allowsHitTesting(false)
    }
}

private struct ActionRail: View {
    let item: ReelItem
    /// Unfolded, Ask/Quiz/Code live in the inspector, so the rail slims down.
    let compact: Bool
    let hasVideo: Bool
    let paused: Bool
    let open: (ReelSheet) -> Void
    let onReplay: () -> Void
    let onTogglePlayback: () -> Void
    @Environment(ReelStore.self) private var store

    var body: some View {
        HStack(spacing: 0) {
            if !compact {
                tool("sparkles", "Ask") { open(.ask) }
                tool("gamecontroller", "Quiz") { open(.quiz) }
                tool("chevron.left.forwardslash.chevron.right", "Code") { open(.code) }
            } else if !hasVideo {
                Label("REEL", systemImage: "play.rectangle")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 12)
            }
            if hasVideo {
                tool(paused ? "play.fill" : "pause.fill", paused ? "Play" : "Pause", action: onTogglePlayback)
            }
            tool(store.voiceOn ? "speaker.wave.2" : "speaker.slash", store.voiceOn ? (hasVideo ? "Sound" : "Voice") : "Muted") {
                store.voiceOn.toggle()
            }
            tool("arrow.counterclockwise", "Replay", action: onReplay)
        }
        .padding(.vertical, 4)
        .background(.white.opacity(0.055), in: .rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.06)))
    }

    private func tool(_ symbol: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: symbol).font(.system(size: 17, weight: .medium))
                Text(title).font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(.white.opacity(0.8))
            .frame(maxWidth: .infinity, minHeight: 48)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private struct SwipeHint: View {
    @State private var bounce = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.up")
                .offset(y: bounce ? -2 : 2)
            Text("Swipe up to review")
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(.white.opacity(0.6))
        .padding(.vertical, 2)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { bounce = true }
        }
    }
}

private struct StatusStamp: View {
    let status: ReviewStatus

    private var text: String {
        switch status {
        case .approved: "APPROVED"
        case .denied: "DENIED"
        case .elsewhere: "HANDLED"
        case .pending: ""
        }
    }

    private var color: Color {
        switch status {
        case .approved: .green
        case .denied: .pink
        default: .gray
        }
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(text)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundStyle(color)
                .padding(.horizontal, 14).padding(.vertical, 6)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(color, lineWidth: 3))
            if case .elsewhere(let reason) = status {
                Text(reason).font(.caption2.weight(.semibold)).foregroundStyle(.white.opacity(0.7))
            }
        }
        .rotationEffect(.degrees(-12))
        .shadow(color: color.opacity(0.6), radius: 12)
        .allowsHitTesting(false)
    }
}
