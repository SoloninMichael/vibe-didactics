import VibieKit
import SwiftUI

/// The vertical, full-screen, swipe-to-advance feed.
struct ReelFeedView: View {
    var onPair: () -> Void
    /// Extra room for whatever floats above and below the feed (the header on a phone).
    var clearance = EdgeInsets(top: 56, leading: 0, bottom: 0, trailing: 0)
    @Environment(ReelStore.self) private var store
    @State private var position: FeedPage?
    @State private var programmaticTarget: FeedPage?

    var body: some View {
        GeometryReader { geo in
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(store.items) { item in
                        ReelView(item: item, isActive: position == .card(item.id) && store.prompt == nil, insets: insets(geo))
                            .containerRelativeFrame([.horizontal, .vertical])
                            .id(FeedPage.card(item.id))
                    }
                    EndOfFeedView(insets: insets(geo), onPair: onPair)
                        .containerRelativeFrame([.horizontal, .vertical])
                        .id(FeedPage.end)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $position)
            .scrollIndicators(.hidden)
        }
        .onAppear {
            if position == nil { position = store.items.first.map { .card($0.id) } ?? .end }
            if case .card(let id)? = position { store.activeID = id }
        }
        .onChange(of: position) { old, new in
            if case .card(let id)? = new { store.activeID = id } else { store.activeID = nil }
            if new == programmaticTarget {
                programmaticTarget = nil
            } else {
                swiped(from: old, to: new)
            }
        }
        .onChange(of: store.jumpTarget) { _, target in
            guard let target else { return }
            programmaticTarget = target
            withAnimation(.smooth) { position = target }
            store.jumpTarget = nil
        }
        .onChange(of: store.items.map(\.id)) { old, new in
            // The feed was reset (demo restarted, session wiped).
            if case .card(let id)? = position, !new.contains(id) {
                position = new.first.map { .card($0) } ?? .end
                return
            }
            // A fresh reel arrived while you were waiting at the end: bring it up.
            if position == .end || position == nil,
               let fresh = store.items.first(where: { !old.contains($0.id) && $0.status.isPending }) {
                withAnimation(.smooth) { position = .card(fresh.id) }
            }
        }
    }

    private func insets(_ geo: GeometryProxy) -> EdgeInsets {
        EdgeInsets(top: geo.safeAreaInsets.top + clearance.top, leading: 0,
                   bottom: geo.safeAreaInsets.bottom + clearance.bottom, trailing: 0)
    }

    private func index(of page: FeedPage?) -> Int? {
        switch page {
        case .card(let id)?: store.items.firstIndex { $0.id == id }
        case .end?: store.items.count
        case nil: nil
        }
    }

    /// Swiping forward past an undecided reel brings up the approve/deny prompt for it.
    private func swiped(from old: FeedPage?, to new: FeedPage?) {
        guard let from = index(of: old), let to = index(of: new), to > from,
              case .card(let id)? = old, let item = store.item(id) else { return }
        store.userSwiped(past: item)
    }
}

struct FeedHeader: View {
    var onPrivacy: () -> Void
    var onConnection: () -> Void
    @Environment(ReelStore.self) private var store
    @Environment(BridgeClient.self) private var bridge

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onPrivacy) {
                Image(systemName: "waveform.path")
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(.cyan)
                    .frame(width: 44, height: 44)
                    .background(.cyan.opacity(0.12), in: .rect(cornerRadius: 15))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Vibie privacy and settings")

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("vibie")
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                    if store.mode == .demo {
                        Text("DEMO")
                            .font(.system(size: 9, weight: .heavy))
                            .tracking(1)
                            .foregroundStyle(.cyan)
                            .padding(.horizontal, 7).padding(.vertical, 4)
                            .background(.cyan.opacity(0.12), in: .capsule)
                    }
                }
                statusLine
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            GlassEffectContainer(spacing: 12) {
            HStack(spacing: 10) {
            if store.pendingCount > 0 {
                Button(action: store.jumpToNextPending) {
                    Label("\(store.pendingCount)", systemImage: "tray.full.fill")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .contentTransition(.numericText(value: Double(store.pendingCount)))
                        .padding(.horizontal, 12)
                        .frame(height: 42)
                        .glassEffect(.regular.interactive(), in: .capsule)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(store.pendingCount) changes waiting")
                .transition(.scale.combined(with: .opacity))
            }

            CircleGlassButton(symbol: "laptopcomputer", dot: connectionColor, action: onConnection)
                .accessibilityLabel("Your Mac")
            if store.studio {
                CircleGlassButton(symbol: "lock.shield", action: onPrivacy)
                    .accessibilityLabel("Privacy")
            }
            }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .contextMenu {
            Button("Privacy", systemImage: "lock.shield", action: onPrivacy)
            if store.mode == .demo {
                Button("Restart demo", systemImage: "arrow.counterclockwise", action: store.startDemo)
            }
        }
        .animation(.snappy, value: store.pendingCount)
    }

    private var connectionColor: Color {
        switch bridge.phase {
        case .live: .green
        case .connecting: .yellow
        case .unpaired: .gray
        case .offline, .failed: .red
        }
    }

    @ViewBuilder
    private var statusLine: some View {
        let text: String = {
            if store.mode == .demo {
                return store.agentStatus?.state == .working ? "The agent is working…" : "Your agent, at a glance"
            }
            switch bridge.phase {
            case .live: return store.agentStatus.map { "\($0.agent.shortName) · \($0.detail)" } ?? "Live · \(bridge.mac?.name ?? "Mac")"
            case .connecting: return "Connecting to \(bridge.mac?.name ?? "your Mac")…"
            case .unpaired: return "Not paired"
            case .offline, .failed: return "\(bridge.mac?.name ?? "Mac") offline"
            }
        }()
        HStack(spacing: 5) {
            Circle()
                .fill(store.mode == .demo ? .cyan : connectionColor)
                .frame(width: 6, height: 6)
            Text(text)
                .lineLimit(1)
                .contentTransition(.opacity)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.white.opacity(0.8))
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut, value: text)
    }
}

struct EndOfFeedView: View {
    let insets: EdgeInsets
    var onPair: () -> Void
    @Environment(ReelStore.self) private var store
    @Environment(BridgeClient.self) private var bridge

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 0.025, green: 0.035, blue: 0.065)
                RadialGradient(colors: [.indigo.opacity(0.22), .clear], center: .top, startRadius: 10, endRadius: 400)

                ScrollView {
                    VStack(spacing: 18) {
                        AgentOrb(state: store.agentStatus?.state ?? .idle)
                            .scaleEffect(0.65)
                            .frame(height: 140)
                            .accessibilityHidden(true)

                        Text(store.pendingCount == 0 ? "You're all caught up." : "A few changes to go.")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .tracking(-0.6)
                            .multilineTextAlignment(.center)

                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.55))
                            .multilineTextAlignment(.center)

                        if store.pendingCount > 0 {
                            Button(action: store.jumpToNextPending) {
                                Label("Review \(store.pendingCount) waiting", systemImage: "arrow.up")
                                    .font(.system(size: 14, weight: .semibold))
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .foregroundStyle(.black)
                                    .background(.cyan, in: .rect(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                        }

                        if store.mode == .demo || !bridge.isPaired {
                            VStack(spacing: 14) {
                                Label("Ready for your own project?", systemImage: "laptopcomputer")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Pair your Mac to review real changes from your coding agent. Direct, encrypted, and always in your control.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white.opacity(0.55))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(3)
                                Button(action: onPair) {
                                    Label("Pair my Mac", systemImage: "qrcode.viewfinder")
                                        .font(.system(size: 14, weight: .semibold))
                                        .frame(maxWidth: .infinity, minHeight: 46)
                                }
                                .buttonStyle(.glass)
                            }
                            .padding(20)
                            .background(.white.opacity(0.04), in: .rect(cornerRadius: 24))
                            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.white.opacity(0.08)))
                        }
                        if store.mode == .demo {
                            Button("Replay demo", systemImage: "arrow.counterclockwise", action: store.startDemo)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                                .frame(minHeight: 44)
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, insets.top + 16)
                    .padding(.bottom, insets.bottom + 16)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geo.size.height)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var subtitle: String {
        if let status = store.agentStatus {
            return "\(status.agent.shortName) · \(status.detail)"
        }
        switch bridge.phase {
        case .live: return "New changes from your agent will appear here as reels."
        case .connecting: return "Connecting to \(bridge.mac?.name ?? "your Mac")…"
        case .failed(let message): return message
        default: return "Changes will appear here as reels."
        }
    }
}
