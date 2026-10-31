import SwiftUI
import VibieKit

/// Unfolded iPhone Duo: the reel on the left, a Liquid Glass inspector on the right.
struct StudioLayout: View {
    var onPrivacy: () -> Void
    var onConnection: () -> Void
    @Environment(ReelStore.self) private var store

    var body: some View {
        GeometryReader { geo in
            let reelWidth = min((geo.size.width - 48) * 0.47, 460)
            ZStack {
                // The glass refracts whatever reel is playing.
                ReelBackground(palette: store.activeItem?.palette ?? Palette(kind: .edit, risk: .low), animate: true)
                    .overlay(.black.opacity(0.72))
                    .animation(.easeInOut(duration: 0.8), value: store.activeID)

                VStack(spacing: 12) {
                    FeedHeader(onPrivacy: onPrivacy, onConnection: onConnection)
                    if let step = store.coach {
                        CoachTipView(step: step)
                    }
                    HStack(spacing: 16) {
                        ReelFeedView(onPair: onConnection, clearance: EdgeInsets())
                            .clipShape(.rect(cornerRadius: 30))
                            .overlay(RoundedRectangle(cornerRadius: 30).strokeBorder(.white.opacity(0.14)))
                            .shadow(color: .black.opacity(0.3), radius: 24, y: 12)
                            .frame(width: reelWidth)
                        InspectorPanel()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
        }
        .animation(.spring(duration: 0.4), value: store.coach)
    }
}

struct InspectorPanel: View {
    @Environment(ReelStore.self) private var store
    @State private var reviewingDecision = true

    private var inspectedItem: ReelItem? { store.prompt?.item ?? store.activeItem }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(store.prompt != nil && reviewingDecision ? "REVIEW CHANGE" : "CHANGE INSPECTOR")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.8)
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Image(systemName: "lock.shield")
                    .font(.caption)
                    .foregroundStyle(.mint.opacity(0.8))
                    .accessibilityLabel("On-device review")
            }
            .padding(.horizontal, 6)
            tabBar

            if let item = inspectedItem, item.demoLesson != nil {
                DemoRiskOverview(item: item)
            }

            Group {
                if let request = store.prompt, reviewingDecision {
                    ScrollView {
                        DecisionPrompt(request: request, docked: true)
                            .id(request.id)
                    }
                    .scrollIndicators(.hidden)
                } else if store.inspectorTab == .queue {
                    QueueList()
                } else if let item = inspectedItem {
                    switch store.inspectorTab {
                    case .code: CodePanel(item: item)
                    case .ask: AskPanel(item: item)
                    case .quiz: QuizSheet(item: item, otherFiles: store.knownFiles, embedded: true)
                    case .queue: EmptyView()
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 42, weight: .light))
                            .foregroundStyle(.mint)
                        Text("A little more clarity.")
                            .font(.title3.weight(.semibold))
                        Text("Choose a change from the queue to explore its code, ask a question, or test your understanding.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Open queue") { store.inspectorTab = .queue }
                            .buttonStyle(.glass)
                    }
                    .padding(20)
                }
            }
            .id("\(store.inspectorTab.rawValue)-\(inspectedItem?.id.uuidString ?? "none")")
            .transition(.blurReplace)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if store.prompt != nil, !reviewingDecision {
                Button {
                    withAnimation(.smooth) { reviewingDecision = true }
                } label: {
                    Label("Back to your decision", systemImage: "checkmark.bubble")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.glass)
            } else if store.prompt == nil, let item = store.activeItem, item.status.isPending {
                DecideNowBar(item: item)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(16)
        .background(.white.opacity(0.035), in: .rect(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).strokeBorder(.white.opacity(0.1)))
        .animation(.spring(duration: 0.45), value: store.inspectorTab)
        .animation(.spring(duration: 0.45), value: store.prompt?.id)
        .animation(.spring(duration: 0.45), value: store.activeID)
        .onChange(of: store.prompt?.id) { _, _ in reviewingDecision = true }
    }

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(InspectorTab.allCases) { tab in
                let selected = store.inspectorTab == tab
                Button {
                    withAnimation(.smooth(duration: 0.25)) {
                        store.inspectorTab = tab
                        reviewingDecision = false
                    }
                    if tab != .queue { store.coach(.openedTool) }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 16, weight: .semibold))
                        Text(tab.title).font(.system(size: 10, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .foregroundStyle(selected ? Color.cyan : .white.opacity(0.55))
                    .background(selected ? .cyan.opacity(0.12) : .clear, in: .rect(cornerRadius: 15))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab == .queue ? "Queue, \(store.pendingCount) waiting" : tab.title)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(.black.opacity(0.22), in: .rect(cornerRadius: 19))
    }
}

/// One-tap decisions without leaving the inspector.
private struct DecideNowBar: View {
    let item: ReelItem
    @Environment(ReelStore.self) private var store

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    store.requestDecision(for: item)
                } label: {
                    Image(systemName: "text.bubble.fill").frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .circle)
                .accessibilityLabel("Decide with a note")

                Button {
                    store.decide(item, .deny, note: nil)
                } label: {
                    Label(item.card.kind == .checkpoint ? "Rest" : "Deny", systemImage: "xmark")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.tint(.pink.opacity(0.5)).interactive(), in: .capsule)

                Button {
                    if item.card.kind == .checkpoint {
                        store.requestDecision(for: item)
                    } else {
                        store.decide(item, .approve, note: nil)
                    }
                } label: {
                    Label(item.card.kind == .checkpoint ? "Reply" : "Approve", systemImage: item.card.kind == .checkpoint ? "paperplane.fill" : "checkmark")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.tint(.green.opacity(0.5)).interactive(), in: .capsule)
            }
        }
        .sensoryFeedback(.success, trigger: item.status)
    }
}

/// Every change this session, newest last, tap to jump.
struct QueueList: View {
    @Environment(ReelStore.self) private var store

    var body: some View {
        ScrollView {
            GlassEffectContainer(spacing: 8) {
                LazyVStack(spacing: 8) {
                    ForEach(store.items) { item in
                        Button {
                            store.jumpTarget = .card(item.id)
                        } label: {
                            QueueRow(item: item, active: store.activeID == item.id)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
            }
        }
        .scrollIndicators(.hidden)
    }
}

private struct QueueRow: View {
    let item: ReelItem
    let active: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.card.kind.symbol)
                .font(.system(size: 15, weight: .bold))
                .frame(width: 38, height: 38)
                .background(item.palette.primary.gradient.opacity(0.8), in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.explainer.headline)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Text(item.card.filePath ?? item.card.command ?? item.card.project)
                    .font(.caption.monospaced())
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
                    .truncationMode(.head)
            }
            Spacer(minLength: 4)
            statusIcon
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(active ? .regular.tint(.white.opacity(0.18)).interactive() : .regular.interactive(), in: .rect(cornerRadius: 20))
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch item.status {
        case .pending: Image(systemName: "clock.fill").foregroundStyle(.orange)
        case .approved: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .denied: Image(systemName: "xmark.circle.fill").foregroundStyle(.pink)
        case .elsewhere: Image(systemName: "arrow.uturn.left.circle.fill").foregroundStyle(.gray)
        }
    }
}

struct CoachTipView: View {
    let step: CoachStep

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: step.symbol).foregroundStyle(.cyan)
            Text(step.text).frame(maxWidth: .infinity, alignment: .leading)
        }
            .font(.footnote.weight(.semibold))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(.cyan.opacity(0.08), in: .rect(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.cyan.opacity(0.15)))
            .padding(.horizontal, 16)
            .id(step)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
    }
}
