import VibieKit
import SwiftUI

/// The sleek approve / deny card that slides up after you swipe past a reel.
/// Swipe the card right to approve, left to deny, or use the buttons.
struct DecisionPrompt: View {
    let request: DecisionRequest
    /// Docked inside the unfolded inspector instead of floating over the feed.
    var docked = false
    @Environment(ReelStore.self) private var store
    @State private var drag: CGFloat = 0
    @State private var note = ""
    @State private var redirecting = false
    @State private var decided: Verdict?
    @State private var nudge = 0
    @FocusState private var noteFocused: Bool

    private let threshold: CGFloat = 110
    private var item: ReelItem { request.item }
    private var card: ChangeCard { item.card }
    private var isCheckpoint: Bool { card.kind == .checkpoint }
    private var agent: String { card.agent.shortName }
    private var noteIsEmpty: Bool { note.nilIfBlank == nil }

    private var approveTitle: String {
        if isCheckpoint { return "Send" }
        switch card.kind {
        case .command: return "Run it"
        case .create: return "Create it"
        default: return "Approve"
        }
    }

    private var denyTitle: String {
        if isCheckpoint { return "Stop here" }
        return redirecting ? "Deny & send" : "Deny"
    }

    var body: some View {
        Group {
            if docked {
                panel
            } else {
                ZStack(alignment: .bottom) {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            if noteFocused { noteFocused = false } else { store.decideLater() }
                        }
                    ViewThatFits(in: .vertical) {
                        panel
                        ScrollView {
                            panel
                        }
                        .scrollIndicators(.hidden)
                        .defaultScrollAnchor(.bottom)
                    }
                }
            }
        }
        .onAppear {
            note = request.suggestedNote
            redirecting = isCheckpoint || request.suggestedNote.nilIfBlank != nil
        }
        .onDisappear {
            if store.prompt?.id == request.id {
                store.prompt?.suggestedNote = note
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: abs(drag) > threshold)
        .sensoryFeedback(trigger: decided) { _, verdict in
            Self.feedback(for: verdict)
        }
        .sensoryFeedback(.error, trigger: nudge)
    }

    private static func feedback(for verdict: Verdict?) -> SensoryFeedback? {
        switch verdict {
        case .approve: return .success
        case .deny: return .warning
        default: return nil
        }
    }

    private var panel: some View {
        VStack(spacing: 14) {
            if !docked {
                Capsule().fill(.white.opacity(0.3)).frame(width: 40, height: 5)
            }

            Text(isCheckpoint ? "\(agent.uppercased()) IS WAITING FOR YOU" : "YOUR CALL")
                .font(.caption.weight(.heavy))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.6))

            summaryCard
                .offset(x: drag)
                .rotationEffect(.degrees(Double(drag) / 24))
                .gesture(
                    DragGesture()
                        .onChanged { drag = $0.translation.width }
                        .onEnded { finishDrag($0.translation.width) })

            Text(isCheckpoint ? "Swipe right to send · left to let it rest" : "Swipe right to \(approveTitle.lowercased()) · left to deny")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.6))

            if redirecting {
                TextField(isCheckpoint ? "What should \(agent) do next?" : "Tell \(agent) what to do instead…", text: $note, axis: .vertical)
                    .lineLimit(1...4)
                    .focused($noteFocused)
                    .padding(14)
                    .background(.black.opacity(0.35), in: .rect(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.15)))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .modifier(Shake(trigger: nudge))
            }

            decisionButtons
            footer
        }
        .padding(docked ? 12 : 20)
        .glassEffect(.regular.tint(docked ? item.palette.primary.opacity(0.18) : .clear), in: .rect(cornerRadius: docked ? 28 : 36))
        .padding(.horizontal, docked ? 0 : 10)
        .padding(.bottom, docked ? 0 : 6)
    }

    private var decisionButtons: some View {
        HStack(spacing: 12) {
            Button {
                fling(.deny)
            } label: {
                Label(denyTitle, systemImage: isCheckpoint ? "moon.zzz.fill" : "xmark")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(isCheckpoint ? .indigo : .pink)

            Button {
                fling(.approve)
            } label: {
                Label(approveTitle, systemImage: isCheckpoint ? "paperplane.fill" : "checkmark")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(.green)
    }
    .controlSize(.large)
    }

    private var footer: some View {
        HStack {
            if !isCheckpoint, !redirecting {
                Button("Deny with a note…") {
                    withAnimation(.snappy) { redirecting = true }
                    noteFocused = true
                }
            }
            Spacer()
            Button("Decide later") { store.decideLater() }
    }
    .font(.subheadline.weight(.semibold))
    .foregroundStyle(.white.opacity(0.75))
    .buttonStyle(.plain)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                KindBadge(kind: card.kind, small: true)
                Spacer()
                Label(item.explainer.risk.title, systemImage: "gauge.with.dots.needle.33percent")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(item.explainer.risk.color)
            }
            Text(item.explainer.headline)
                .font(.title3.weight(.bold))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 10) {
                if let path = card.filePath {
                    Label(path, systemImage: "doc.text").lineLimit(1).truncationMode(.head)
                } else if let command = card.command {
                    Label(command, systemImage: "terminal").lineLimit(1)
                } else {
                    Label(card.project, systemImage: "folder")
                }
                Spacer(minLength: 0)
                if card.kind == .edit || card.kind == .create {
                    Text("+\(card.additions)").foregroundStyle(.green)
                    Text("−\(card.deletions)").foregroundStyle(.pink)
                }
            }
            .font(.footnote.weight(.semibold).monospaced())
            .foregroundStyle(.white.opacity(0.8))
        }
        .padding(16)
        .background(.black.opacity(0.35), in: .rect(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(drag > 0 ? Color.green : Color.pink, lineWidth: 2)
                .opacity(min(abs(drag) / threshold, 1))
        }
        .overlay(alignment: drag > 0 ? .topLeading : .topTrailing) {
            if drag != 0 {
                Text(drag > 0 ? approveTitle.uppercased() : denyTitle.uppercased())
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(drag > 0 ? .green : .pink)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(drag > 0 ? Color.green : Color.pink, lineWidth: 3))
                    .rotationEffect(.degrees(drag > 0 ? -14 : 14))
                    .opacity(min(abs(drag) / threshold, 1))
                    .padding(14)
            }
        }
    }

    private func finishDrag(_ width: CGFloat) {
        if width > threshold {
            fling(.approve)
        } else if width < -threshold {
            fling(.deny)
        } else {
            withAnimation(.spring(duration: 0.4, bounce: 0.4)) { drag = 0 }
        }
    }

    private func fling(_ verdict: Verdict) {
        guard decided == nil else { return }
        if isCheckpoint, verdict == .approve, noteIsEmpty {
            withAnimation(.spring(duration: 0.4, bounce: 0.4)) { drag = 0 }
            nudge += 1
            noteFocused = true
            return
        }
        noteFocused = false
        decided = verdict
        withAnimation(.easeIn(duration: 0.22)) { drag = verdict == .approve ? 700 : -700 }
        let sendNote = isCheckpoint || (verdict == .deny && redirecting)
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            store.decide(item, verdict, note: sendNote ? note : nil)
        }
    }
}

private struct Shake: ViewModifier, Animatable {
    var trigger: Int
    var phase: CGFloat = 0

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    init(trigger: Int) {
        self.trigger = trigger
        self.phase = CGFloat(trigger)
    }

    func body(content: Content) -> some View {
        content
            .offset(x: sin(phase * .pi * 6) * 8)
            .animation(.linear(duration: 0.4), value: trigger)
    }
}
