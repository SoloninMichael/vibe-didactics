import AVFoundation
import SwiftUI
import VibieKit

/// First launch: what Vibie is, in three swipes, over a looping video (or animated cards).
struct WelcomeView: View {
    var onDemo: () -> Void
    var onPair: () -> Void
    @State private var page = 0

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("play.rectangle.on.rectangle.fill", "Every change, as a reel",
         "Your AI agent writes the code. Vibie turns each change into a 20-second explainer you can swipe through."),
        ("apple.intelligence", "Understand before you approve",
         "Explore the code, ask a question, or take a quick quiz. Explanations stay on your iPhone, with Apple Intelligence when available."),
        ("hand.thumbsup.fill", "Approve from anywhere",
         "Review a change, approve it, or send your agent a better direction. Your Mac does the work. You stay in control."),
    ]

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width >= 600
            ZStack {
                IntroBackdrop()
                VStack(spacing: 20) {
                    HStack {
                        Label("vibie", systemImage: "waveform.path")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                        Spacer()
                        Label("PRIVATE BY DESIGN", systemImage: "lock.shield")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 8)

                    if wide {
                        let heroWidth = min(360, (geo.size.width - 92) * 0.42)
                        HStack(spacing: 28) {
                            hero(showTagline: true)
                                .scaleEffect(min(1, heroWidth / 370))
                                .frame(width: heroWidth)
                            introduction
                                .frame(maxWidth: 380)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                if geo.size.height >= 750 {
                                    hero(showTagline: false)
                                        .scaleEffect(0.85)
                                        .frame(height: 250)
                                }
                                introduction
                            }
                            .frame(maxWidth: 440)
                            .frame(maxWidth: .infinity)
                        }
                        .scrollIndicators(.hidden)
                    }

                    Text("No accounts. No cloud. Always in your hands.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(wide ? 32 : 20)
            }
        }
    }

    private func hero(showTagline: Bool) -> some View {
        VStack(spacing: 28) {
            FloatingReelStack()
                .frame(height: 280)
            if showTagline {
                Text("Your agent.\nYour next move.")
                    .font(.system(size: 35, weight: .bold, design: .rounded))
                    .tracking(-1)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 8) {
                Capsule().fill(.cyan).frame(width: 22, height: 3)
                Text("CODE, WITH CLARITY")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(.cyan)
            }

            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    let page = pages[index]
                    VStack(alignment: .leading, spacing: 16) {
                        Text(page.title)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .tracking(-0.8)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(page.body)
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.65))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 210)

            HStack(spacing: 7) {
                ForEach(pages.indices, id: \.self) { index in
                    Button {
                        withAnimation(.smooth) { page = index }
                    } label: {
                        Capsule()
                            .fill(index == page ? Color.cyan : .white.opacity(0.2))
                            .frame(width: index == page ? 24 : 6, height: 6)
                            .frame(minWidth: 28, minHeight: 28)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Introduction page \(index + 1)")
                    .accessibilityAddTraits(index == page ? .isSelected : [])
                }
                Spacer()
                Text("0\(page + 1) / 03")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .animation(.smooth, value: page)

            VStack(spacing: 10) {
                Button(action: onDemo) {
                    HStack {
                        Text("Explore the demo")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(.cyan, in: .rect(cornerRadius: 18))
                }
                .buttonStyle(.plain)

                Button(action: onPair) {
                    Label("Pair my Mac", systemImage: "laptopcomputer")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(.white.opacity(0.06), in: .rect(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .background(.black.opacity(0.25), in: .rect(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).strokeBorder(.white.opacity(0.1)))
    }
}

/// Plays `Resources/intro-loop.mp4` (or .mov) if you add one; otherwise a living mesh gradient.
struct IntroBackdrop: View {
    static let videoURL = Bundle.main.url(forResource: "intro-loop", withExtension: "mp4")
        ?? Bundle.main.url(forResource: "intro-loop", withExtension: "mov")

    var body: some View {
        Group {
            if let url = Self.videoURL {
                LoopingVideo(url: url)
            } else {
                ReelBackground(palette: Palette(kind: .edit, risk: .medium), animate: true)
            }
        }
        .overlay(LinearGradient(colors: [.clear, .clear, .black.opacity(0.65)], startPoint: .top, endPoint: .bottom))
        .ignoresSafeArea()
    }
}

struct LoopingVideo: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PlayerView { PlayerView(url: url) }
    func updateUIView(_ view: PlayerView, context: Context) {}

    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        private let player = AVQueuePlayer()
        private var looper: AVPlayerLooper?

        init(url: URL) {
            super.init(frame: .zero)
            looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
            player.isMuted = true
            player.preventsDisplaySleepDuringVideoPlayback = false
            if let layer = layer as? AVPlayerLayer {
                layer.player = player
                layer.videoGravity = .resizeAspectFill
            }
            player.play()
        }

        required init?(coder: NSCoder) { nil }
    }
}

/// Three mini reels fanned out and gently floating: the product at a glance.
private struct FloatingReelStack: View {
    private let cards: [(kind: ChangeKind, title: String, risk: RiskLevel, file: String)] = [
        (.edit, "Break-It! Empty Bowl", .high, "spooky_route_controller.py"),
        (.edit, "The Last Candy Problem", .low, "spooky_route_controller.py"),
        (.edit, "Multi-Agent Workflow", .medium, "multi_agent_pipeline.py"),
    ]

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(cards.indices, id: \.self) { index in
                    let card = cards[index]
                    let offset = Double(index - 1)
                    MiniReel(kind: card.kind, title: card.title, risk: card.risk, file: card.file)
                        .rotationEffect(.degrees(offset * 11 + sin(t * 0.8 + offset) * 2))
                        .offset(x: offset * 92, y: abs(offset) * 26 + sin(t * 1.1 + offset * 1.7) * 8)
                        .zIndex(index == 1 ? 1 : 0)
                }
            }
        }
    }
}

private struct MiniReel: View {
    let kind: ChangeKind
    let title: String
    let risk: RiskLevel
    let file: String

    var body: some View {
        let palette = Palette(kind: kind, risk: risk)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 3) {
                ForEach(0..<5) { index in
                    Capsule().fill(.white.opacity(index < 2 ? 1 : 0.3)).frame(height: 2)
                }
            }
            Spacer()
            KindBadge(kind: kind, small: true)
            Text(title)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .lineLimit(3)
            Text(file)
                .font(.caption2.monospaced().weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
            HStack(spacing: 6) {
                Image(systemName: "xmark").frame(maxWidth: .infinity, minHeight: 26)
                    .glassEffect(.regular.tint(.pink.opacity(0.5)), in: .capsule)
                Image(systemName: "checkmark").frame(maxWidth: .infinity, minHeight: 26)
                    .glassEffect(.regular.tint(.green.opacity(0.5)), in: .capsule)
            }
            .font(.caption.weight(.heavy))
        }
        .padding(14)
        .frame(width: 150, height: 250)
        .background {
            LinearGradient(colors: [palette.secondary.opacity(0.9), palette.primary.opacity(0.6), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .clipShape(.rect(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(.white.opacity(0.25)))
        .shadow(color: palette.primary.opacity(0.5), radius: 24, y: 10)
    }
}
