import VibieKit
import FoundationModels
import SwiftUI

struct AskSheet: View {
    let item: ReelItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            AskPanel(item: item)
                .navigationTitle("Ask about this change")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

/// Chat about one change with Apple's on-device model. Nothing typed here leaves the phone.
struct AskPanel: View {
    struct Line: Identifiable, Equatable {
        let id = UUID()
        var fromUser: Bool
        var text: String
    }

    let item: ReelItem
    @State private var lines: [Line] = []
    @State private var draft = ""
    @State private var session: LanguageModelSession?
    @State private var busy = false
    @FocusState private var focused: Bool

    private let suggestions = ["Explain it simply", "What could break?", "Why this way?", "How do I test it?"]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    if lines.count <= 1 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("A little more context?")
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                            Text("Start with a question, or choose one below.")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(suggestions, id: \.self) { suggestion in
                                    Button { Task { await ask(suggestion) } } label: {
                                        Text(suggestion)
                                            .font(.system(size: 12, weight: .medium))
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                                            .padding(.horizontal, 12)
                                            .background(.cyan.opacity(0.06), in: .rect(cornerRadius: 14))
                                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.cyan.opacity(0.12)))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(busy)
                                }
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    ForEach(lines) { line in
                        bubble(line).id(line.id)
                    }
                    if busy, lines.last?.text.isEmpty ?? true {
                        ProgressView().padding(.leading, 12)
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: lines) {
                withAnimation { proxy.scrollTo(lines.last?.id, anchor: .bottom) }
            }
        }
        .safeAreaInset(edge: .bottom) { composer }
        .onAppear {
            guard lines.isEmpty else { return }
            lines.append(Line(fromUser: false, text: OnDeviceAI.isAvailable
                ? "Ask me anything about this change. Answers are generated on your iPhone and stay here."
                : "I can walk you through what changes, why it matters, and what to check. Answers use Vibie's built-in explainer and stay on your iPhone."))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                KindBadge(kind: item.card.kind, small: true)
                Spacer()
                Label(OnDeviceAI.isAvailable ? "On-device AI" : "Built-in", systemImage: OnDeviceAI.isAvailable ? "apple.intelligence" : "cpu")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text(item.explainer.headline).font(.system(size: 15, weight: .semibold))
            if let path = item.card.filePath ?? item.card.command {
                Text(path).font(.caption.monospaced()).foregroundStyle(.secondary).lineLimit(1)
            }
        }
        .padding(14)
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 18))
    }

    private func bubble(_ line: Line) -> some View {
        HStack {
            if line.fromUser { Spacer(minLength: 40) }
            Text(line.text.isEmpty ? " " : line.text)
                .font(.system(size: 14))
                .lineSpacing(3)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(line.fromUser ? AnyShapeStyle(Color.accentColor.gradient) : AnyShapeStyle(.white.opacity(0.08)), in: .rect(cornerRadius: 18))
                .textSelection(.enabled)
            if !line.fromUser { Spacer(minLength: 40) }
        }
    }

    private var composer: some View {
        VStack(spacing: 10) {
            if lines.count > 1 {
              ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(suggestion) { Task { await ask(suggestion) } }
                            .font(.subheadline.weight(.semibold))
                            .buttonStyle(.glass)
                            .disabled(busy)
                    }
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
            }

            HStack(spacing: 10) {
                TextField("Ask anything…", text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .focused($focused)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .glassEffect(.regular, in: .rect(cornerRadius: 20))
                    .onSubmit(send)
                    .submitLabel(.send)
                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .font(.headline)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .disabled(draft.nilIfBlank == nil || busy)
                .accessibilityLabel("Send question")
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
        .background(.black.opacity(0.18))
    }

    private func send() {
        guard let question = draft.nilIfBlank else { return }
        draft = ""
        Task { await ask(question) }
    }

    private func ask(_ question: String) async {
        lines.append(Line(fromUser: true, text: question))
        busy = true
        defer { busy = false }

        guard OnDeviceAI.isAvailable else {
            lines.append(Line(fromUser: false, text: FallbackTutor.answer(question, item: item)))
            return
        }

        let session = self.session ?? LanguageModelSession(
            instructions: OnDeviceAI.tutorInstructions + "\n\nThe change you are discussing:\n" + OnDeviceAI.context(for: item.card))
        self.session = session
        lines.append(Line(fromUser: false, text: ""))
        let index = lines.count - 1
        do {
            for try await snapshot in session.streamResponse(to: question) {
                lines[index].text = snapshot.content
            }
        } catch let error as LanguageModelSession.GenerationError {
            if case .exceededContextWindowSize = error {
                self.session = nil
                lines[index].text = "We've chatted past what the on-device model can remember. Ask again and I'll start fresh."
            } else {
                lines[index].text = FallbackTutor.answer(question, item: item)
            }
        } catch {
            lines[index].text = FallbackTutor.answer(question, item: item)
        }
    }
}

/// Useful answers without a language model, built from the explainer.
enum FallbackTutor {
    static func answer(_ question: String, item: ReelItem) -> String {
        let q = question.lowercased()
        let e = item.explainer
        if q.contains("break") || q.contains("risk") || q.contains("wrong") || q.contains("safe") {
            return "\(e.risk.title). \(e.watchOut)"
        }
        if q.contains("why") {
            return e.why
        }
        if q.contains("test") || q.contains("check") {
            switch item.card.kind {
            case .command: return "Approve it, then watch the terminal on your Mac: if it prints errors in red, deny the next step and ask \(item.card.agent.shortName) to fix them. \(e.watchOut)"
            case .checkpoint: return "Open the app and try the thing it says it finished. If anything feels off, send that as your next instruction."
            default: return "After approving, open the part of your app that uses \(item.card.fileName ?? "this file") and try what it changes. \(e.watchOut)"
            }
        }
        if q.contains("colour") || q.contains("color") || q.contains("red") || q.contains("green") || q.contains("line") {
            return "Green lines marked + are being added. Pink lines marked − are being removed. Grey lines don't change — they're there so you can see where the change happens."
        }
        return "In short: \(e.whatChanges) \(e.why)"
    }
}
