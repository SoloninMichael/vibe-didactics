import VibieKit
import SwiftUI

/// "Vibe Check": a 3-question game about the change, so you actually understand what you approve.
struct QuizSheet: View {
    let item: ReelItem
    let otherFiles: [String]
    var embedded = false
    @Environment(\.dismiss) private var dismiss
    @AppStorage("xp") private var xp = 0
    @AppStorage("streak") private var streak = 0
    @State private var questions: [QuizQuestion] = []
    @State private var index = 0
    @State private var picked: Int?
    @State private var score = 0
    @State private var loading = true
    @State private var madeOnDevice = false

    var body: some View {
        ZStack {
            if !embedded {
                ReelBackground(palette: item.palette, animate: true).opacity(0.7)
            }
            VStack(spacing: 0) {
                header
                if loading {
                    Spacer()
                    VStack(spacing: 14) {
                        ProgressView().controlSize(.large)
                        Text(item.demoLesson != nil ? "Loading demo quiz…" : OnDeviceAI.isAvailable ? "Writing your quiz on-device…" : "Shuffling questions…")
                            .font(.headline)
                    }
                    Spacer()
                } else if index < questions.count {
                    ScrollView {
                        question(questions[index])
                    }
                    .scrollIndicators(.hidden)
                    .id(index)
                } else {
                    ScrollView { results }
                        .scrollIndicators(.hidden)
                }
            }
            .padding(embedded ? 4 : 20)
        }
        .presentationDetents([.large])
        .task { await load() }
        .sensoryFeedback(trigger: picked) { _, choice in
            guard let choice, index < questions.count else { return nil }
            return choice == questions[index].correct ? .success : .error
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("VIBE CHECK")
                    .font(.caption.weight(.heavy))
                    .tracking(2)
                Text(item.demoLesson.map { "\($0.videoLabel) · Demo quiz" } ?? (madeOnDevice ? "Written by on-device AI" : "Quick quiz"))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            Label("\(streak)", systemImage: "flame.fill")
                .foregroundStyle(.orange)
            Label("\(xp) XP", systemImage: "bolt.fill")
                .foregroundStyle(.yellow)
                .contentTransition(.numericText(value: Double(xp)))
            if !embedded {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark").font(.headline).frame(width: 34, height: 34)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
            }
        }
        .font(.subheadline.weight(.bold).monospacedDigit())
        .padding(.bottom, 18)
    }

    private func question(_ question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let lesson = item.demoLesson {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(lesson.symbol) \(lesson.title)")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(lesson.connection)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 4)
            }
            Text("QUESTION \(index + 1) OF \(questions.count)")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(.cyan)
            HStack(spacing: 6) {
                ForEach(questions.indices, id: \.self) { i in
                    Capsule()
                        .fill(i < index ? Color.green : i == index ? .white : .white.opacity(0.25))
                        .frame(height: 4)
                }
            }

            if let label = question.label {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Text(question.prompt)
                .font(.system(size: embedded ? 24 : 28, weight: .bold, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
                .id(question.id)
                .transition(.push(from: .trailing))

            VStack(spacing: 12) {
                ForEach(Array(question.choices.enumerated()), id: \.offset) { offset, choice in
                    Button {
                        choose(offset, in: question)
                    } label: {
                        HStack(alignment: .firstTextBaseline) {
                            if item.demoLesson != nil {
                                Text(["A", "B", "C"][offset])
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.cyan)
                                    .frame(width: 18)
                            }
                            Text(choice)
                                .font(question.codeChoices ? .system(size: 13, weight: .medium, design: .monospaced) : .system(size: 14, weight: .medium))
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                            if let picked, offset == question.correct || offset == picked {
                                Image(systemName: offset == question.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(offset == question.correct ? .green : .pink)
                                    .transition(.scale)
                                    .id(picked)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(tint(for: offset, in: question), in: .rect(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                    .disabled(picked != nil)
                }
            }

            if picked != nil {
                VStack(alignment: .leading, spacing: 14) {
                    Text(question.explanation)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                    Button {
                        withAnimation(.snappy) {
                            index += 1
                            picked = nil
                        }
                    } label: {
                        Text(index + 1 < questions.count ? "Next question" : "See my score")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            Spacer(minLength: 8)
        }
        .animation(.spring(duration: 0.4), value: picked)
    }

    private var results: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 24)
            ZStack {
                Circle().stroke(.white.opacity(0.15), lineWidth: 16)
                Circle()
                    .trim(from: 0, to: questions.isEmpty ? 0 : CGFloat(score) / CGFloat(questions.count))
                    .stroke(score == questions.count ? Color.green : .orange, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(score)/\(questions.count)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
            }
            .frame(width: 180, height: 180)

            Text(score == questions.count ? "You get it. Approve with confidence." : score > 0 ? "Nearly! Maybe ask a question first." : "Worth a closer look before deciding.")
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)
            Text("+\(score * 10) XP")
                .font(.headline)
                .foregroundStyle(.yellow)
            Spacer(minLength: 24)
            Button {
                if embedded { Task { await playAgain() } } else { dismiss() }
            } label: {
                Text(embedded ? "Play again" : "Back to the reel").font(.headline).frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
        }
        .onAppear { item.quizScore = score }
    }

    private func tint(for offset: Int, in question: QuizQuestion) -> Color {
        guard let picked else { return .black.opacity(0.35) }
        if offset == question.correct { return .green.opacity(0.35) }
        if offset == picked { return .pink.opacity(0.35) }
        return .black.opacity(0.25)
    }

    private func choose(_ offset: Int, in question: QuizQuestion) {
        guard picked == nil else { return }
        picked = offset
        if offset == question.correct {
            score += 1
            streak += 1
            withAnimation { xp += 10 }
        } else {
            streak = 0
        }
    }

    private func playAgain() async {
        index = 0
        score = 0
        picked = nil
        loading = true
        await load()
    }

    private func load() async {
        defer { withAnimation { loading = false } }
        madeOnDevice = false
        if let lesson = item.demoLesson {
            questions = lesson.questions
            return
        }
        var quick = QuizMaker.quick(for: item, otherFiles: otherFiles)
        if OnDeviceAI.isAvailable, let ai = try? await OnDeviceAI.quiz(for: item.card), !ai.isEmpty {
            // Two from the model, plus the hands-on "spot the line" round when there is one.
            let spot = quick.first { $0.codeChoices }
            quick = Array(ai.prefix(spot == nil ? 3 : 2)) + (spot.map { [$0] } ?? [])
            madeOnDevice = true
        }
        questions = quick
    }
}

enum QuizMaker {
    static func quick(for item: ReelItem, otherFiles: [String]) -> [QuizQuestion] {
        let card = item.card
        var questions: [QuizQuestion] = []

        switch card.kind {
        case .checkpoint:
            questions.append(make("What happens if you don't reply?",
                                  correct: "\(card.agent.shortName) stops and waits",
                                  wrong: ["It keeps coding on its own", "It undoes its work"],
                                  explanation: "Nothing changes until you send the next instruction."))
            questions.append(make("Where did this summary come from?",
                                  correct: "The agent's own words, on your Mac",
                                  wrong: ["A cloud server", "Your iPhone's camera"],
                                  explanation: "The bridge reads it from the agent's local transcript and sends it straight to your phone, encrypted."))
        case .command:
            let kind = CommandKind.classify(card.command ?? "")
            let decoys = CommandKind.allCases.filter { $0 != kind && $0 != .other }.shuffled().prefix(2).map(\.meaning)
            questions.append(make("What will this command do?", correct: kind.meaning, wrong: Array(decoys),
                                  explanation: "`\(card.command ?? "")` — \(kind.meaning.lowercased())."))
        default:
            if let file = card.fileName {
                var decoys = Array(Set(otherFiles).subtracting([file])).shuffled()
                decoys += ["index.ts", "App.swift", "styles.css", "utils.py", "README.md"].filter { $0 != file && !decoys.contains($0) }.shuffled()
                questions.append(make("Which file is \(card.agent.shortName) changing?", correct: file, wrong: Array(decoys.prefix(2)),
                                      explanation: "It's \(card.filePath ?? file)."))
            }
            if let spot = spotTheLine(card) { questions.append(spot) }
        }

        let risks = RiskLevel.allCases.filter { $0 != item.explainer.risk }.map(\.title)
        questions.append(make("How risky is this change?", correct: item.explainer.risk.title, wrong: risks,
                              explanation: item.explainer.watchOut))

        if questions.count < 3, card.kind == .edit || card.kind == .create {
            let answer = card.additions > card.deletions * 2 ? "Mostly adding code" : card.deletions > card.additions * 2 ? "Mostly removing code" : "About even"
            questions.insert(make("Is this change mostly adding or removing code?", correct: answer,
                                  wrong: ["Mostly adding code", "Mostly removing code", "About even"].filter { $0 != answer },
                                  explanation: "+\(card.additions) lines in, −\(card.deletions) out."), at: max(questions.count - 1, 0))
        }
        return Array(questions.prefix(3))
    }

    /// Hands-on round: which of these lines is the new one?
    private static func spotTheLine(_ card: ChangeCard) -> QuizQuestion? {
        func usable(_ kinds: Set<DiffLine.Kind>) -> [String] {
            var seen = Set<String>()
            return card.lines.filter { kinds.contains($0.kind) }
                .map { $0.text.trimmingCharacters(in: .whitespaces) }
                .filter { $0.count >= 6 && $0.count <= 64 && seen.insert($0).inserted }
        }
        let added = usable([.added])
        let others = usable([.context, .removed]).filter { !added.contains($0) }
        guard let new = added.randomElement(), others.count >= 2 else { return nil }
        var question = make("Spot the new line. Which one is being added?", correct: new, wrong: Array(others.shuffled().prefix(2)),
                            explanation: "Lines marked + in green are new. The others were already there, or are being removed.")
        question.codeChoices = true
        return question
    }

    private static func make(_ prompt: String, correct: String, wrong: [String], explanation: String) -> QuizQuestion {
        let choices = ([correct] + wrong.prefix(2)).shuffled()
        return QuizQuestion(prompt: prompt, choices: choices, correct: choices.firstIndex(of: correct) ?? 0, explanation: explanation)
    }
}
