import VibieKit
import SwiftUI

struct ReelStageLayout {
    var width: CGFloat = 320
    var height: CGFloat = 400
    var tight: Bool { width < 290 || height < 330 }
    var titleSize: CGFloat { tight ? 32 : 42 }
    var bodySize: CGFloat { tight ? 15 : 18 }
    var spacing: CGFloat { tight ? 12 : 18 }
}

private struct ReelStageLayoutKey: EnvironmentKey {
    static let defaultValue = ReelStageLayout()
}

extension EnvironmentValues {
    var reelStageLayout: ReelStageLayout {
        get { self[ReelStageLayoutKey.self] }
        set { self[ReelStageLayoutKey.self] = newValue }
    }
}

/// The big animated middle of a reel. Each beat re-mounts, so entrance animations replay.
struct BeatStage: View {
    let item: ReelItem
    let beat: Beat

    var body: some View {
        switch beat {
        case .gist: GistStage(item: item)
        case .location: LocationStage(item: item)
        case .code:
            if let command = item.card.command {
                TerminalStage(command: command, project: item.card.project)
            } else {
                CodeStage(item: item)
            }
        case .why: WhyStage(item: item)
        case .risk: RiskStage(item: item)
        case .done: DoneStage(item: item)
        case .summary: SummaryStage(item: item)
        case .next: NextStage(item: item)
        }
    }
}

private struct GistStage: View {
    @Environment(\.reelStageLayout) private var layout
    let item: ReelItem
    @State private var shown = false

    var body: some View {
        VStack(alignment: .leading, spacing: layout.spacing) {
            KindBadge(kind: item.card.kind)
            Text(item.explainer.headline)
                .font(.system(size: layout.titleSize, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(4)
                .textRenderer(RevealRenderer(progress: shown ? 1 : 0))
            Text(item.explainer.whatChanges)
                .font(.system(size: layout.bodySize, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(4)
                .opacity(shown ? 1 : 0)
                .offset(y: shown ? 0 : 14)
                .animation(.easeOut(duration: 0.6).delay(0.7), value: shown)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) { shown = true }
        }
    }
}

private struct LocationStage: View {
    @Environment(\.reelStageLayout) private var layout
    let item: ReelItem
    @State private var revealed = 0

    private var parts: [String] {
        let all = (item.card.filePath ?? item.card.tool).split(separator: "/").map(String.init)
        return all.count > 4 ? ["…"] + all.suffix(3) : all
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                let isFile = index == parts.count - 1
                HStack(spacing: 10) {
                    if index > 0 {
                        Image(systemName: "arrow.turn.down.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    Image(systemName: isFile ? "doc.text.fill" : "folder.fill")
                        .foregroundStyle(isFile ? item.palette.primary : .white.opacity(0.7))
                    Text(part)
                        .font(isFile ? .title.weight(.heavy) : .title3.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .padding(.leading, CGFloat(index) * 16)
                .padding(.vertical, 6)
                .opacity(index < revealed ? 1 : 0)
                .offset(x: index < revealed ? 0 : -24)
            }

            HStack(spacing: 12) {
                StatPill(value: item.card.additions, positive: true)
                if item.card.kind != .create {
                    StatPill(value: item.card.deletions, positive: false)
                }
            }
            .padding(.top, layout.tight ? 16 : 26)
            .opacity(revealed > parts.count ? 1 : 0)

            if let language = item.card.language {
                Text(language + (item.card.kind == .create ? " · brand-new file" : ""))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 12)
                    .opacity(revealed > parts.count ? 1 : 0)
            }
        }
        .task {
            for step in 1...(parts.count + 1) {
                withAnimation(.spring(duration: 0.5)) { revealed = step }
                try? await Task.sleep(for: .milliseconds(240))
            }
        }
    }
}

private struct CodeStage: View {
    @Environment(\.reelStageLayout) private var layout
    let item: ReelItem
    @State private var revealed = 0

    private var card: ChangeCard { item.card }

    /// The first cluster of changes, with a little context.
    private var spotlight: [DiffLine] {
        let lines = card.lines
        guard let first = lines.firstIndex(where: { $0.kind == .added || $0.kind == .removed }) else { return Array(lines.prefix(layout.tight ? 6 : 10)) }
        let start = max(0, first - 2)
        return Array(lines[start..<min(lines.count, start + (layout.tight ? 6 : 10))])
    }

    private var hidden: Bool {
        card.lines.count == 1 && card.lines.first?.kind == .gap
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if hidden {
                VStack(alignment: .leading, spacing: 14) {
                    Image(systemName: "lock.doc.fill")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundStyle(.yellow)
                        .symbolEffect(.bounce, value: revealed)
                    Text("Code stays on your Mac")
                        .font(.system(size: layout.titleSize, weight: .bold, design: .rounded))
                    Text("\(card.fileName ?? "This file") can hold passwords and keys, so the bridge never sends its contents to your phone.")
                        .font(.system(size: layout.bodySize, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        ForEach([Color.red, .yellow, .green], id: \.self) { Circle().fill($0.opacity(0.8)).frame(width: 9, height: 9) }
                        Spacer()
                        Text(card.fileName ?? "")
                            .font(.caption.monospaced().weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(12)
                    Divider().overlay(.white.opacity(0.15))
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(spotlight.enumerated()), id: \.offset) { index, line in
                            DiffRow(line: line, language: card.language, compact: true)
                                .opacity(index < revealed ? 1 : 0)
                                .offset(x: index < revealed ? 0 : 18)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .background(.black.opacity(0.55), in: .rect(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(.white.opacity(0.12)))

                HStack(spacing: 12) {
                    Label("Added", systemImage: "plus").foregroundStyle(.mint)
                    Label("Removed", systemImage: "minus").foregroundStyle(.pink)
                    Spacer(minLength: 0)
                    Text("Full diff in Code").foregroundStyle(.white.opacity(0.5))
                }
                .font(.system(size: 9, weight: .semibold))
            }
        }
        .task {
            for step in 1...max(spotlight.count, 1) {
                withAnimation(.snappy(duration: 0.3)) { revealed = step }
                try? await Task.sleep(for: .milliseconds(170))
            }
        }
    }
}

private struct TerminalStage: View {
    @Environment(\.reelStageLayout) private var layout
    let command: String
    let project: String
    @State private var typed = 0
    @State private var cursor = true

    var body: some View {
        VStack(alignment: .leading, spacing: layout.spacing) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    ForEach([Color.red, .yellow, .green], id: \.self) { Circle().fill($0.opacity(0.8)).frame(width: 9, height: 9) }
                    Spacer()
                    Text("zsh — \(project)").font(.caption.monospaced()).foregroundStyle(.white.opacity(0.6))
                }
                .padding(12)
                Divider().overlay(.white.opacity(0.15))
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("$").foregroundStyle(.green).fontWeight(.bold)
                    Text(String(command.prefix(typed)) + (cursor ? "▍" : " "))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.system(size: 19, weight: .medium, design: .monospaced))
                .padding(16)
            }
            .background(.black.opacity(0.6), in: .rect(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(.white.opacity(0.12)))

            Label(CommandKind.classify(command).meaning, systemImage: "info.circle.fill")
                .font(.system(size: layout.bodySize, weight: .semibold))
                .opacity(typed >= command.count ? 1 : 0)
                .animation(.easeOut, value: typed >= command.count)
        }
        .task {
            let step = max(1, command.count / 45)
            while typed < command.count {
                typed = min(command.count, typed + step)
                try? await Task.sleep(for: .milliseconds(30))
            }
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                cursor.toggle()
            }
        }
    }
}

private struct WhyStage: View {
    @Environment(\.reelStageLayout) private var layout
    let item: ReelItem
    @State private var shown = false

    /// The agent's own words when we have them; otherwise our best explanation.
    private var quote: (text: String, by: String) {
        if item.explainer.source == .quick, let intent = item.card.agentIntent {
            let sentences = QuickExplainer.sentences(intent)
            let text = sentences.prefix(2).joined(separator: ". ")
            if !text.isEmpty { return (text + ".", "\(item.card.agent.displayName), in its own words") }
        }
        return (item.explainer.why, item.explainer.source == .onDevice ? "Explained on-device" : "Vibie's read")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: layout.spacing) {
            Image(systemName: "quote.opening")
                .font(.system(size: 46, weight: .black))
                .foregroundStyle(item.palette.primary)
            Text(quote.text)
                .font(.system(size: layout.tight ? 24 : 30, weight: .semibold, design: .rounded))
                .lineLimit(8)
                .minimumScaleFactor(0.55)
                .textRenderer(RevealRenderer(progress: shown ? 1 : 0))
            Text("— \(quote.by)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
                .opacity(shown ? 1 : 0)
                .animation(.easeOut.delay(0.8), value: shown)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.6)) { shown = true }
        }
    }
}

private struct RiskStage: View {
    @Environment(\.reelStageLayout) private var layout
    let item: ReelItem
    @State private var shown = false

    var body: some View {
        VStack(alignment: .leading, spacing: layout.spacing) {
            RiskMeter(level: item.explainer.risk)
                .frame(height: layout.tight ? 90 : 120)
            Text(item.explainer.risk.title.uppercased())
                .font(.system(size: layout.titleSize, weight: .bold, design: .rounded))
                .foregroundStyle(item.explainer.risk.color)
            Text(item.explainer.watchOut)
                .font(.system(size: layout.bodySize, weight: .semibold))
                .lineLimit(4)
                .opacity(shown ? 1 : 0)
                .offset(y: shown ? 0 : 10)
            if item.card.redactions > 0 {
                Label("Secrets were scrubbed before leaving your Mac", systemImage: "lock.shield.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.yellow)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) { shown = true }
        }
    }
}

private struct DoneStage: View {
    @Environment(\.reelStageLayout) private var layout
    let item: ReelItem
    @State private var shown = false

    var body: some View {
        VStack(alignment: .leading, spacing: layout.spacing) {
            Image(systemName: "checkmark")
                .font(.system(size: 50, weight: .black))
                .frame(width: 104, height: 104)
                .background(Color.green.gradient, in: .circle)
                .shadow(color: .green.opacity(0.6), radius: 24)
                .scaleEffect(shown ? 1 : 0.3)
                .symbolEffect(.bounce, value: shown)
            Text(item.explainer.headline)
                .font(.system(size: layout.titleSize, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
                .textRenderer(RevealRenderer(progress: shown ? 1 : 0))
            Label(item.card.project, systemImage: "folder.fill")
                .font(.system(size: layout.bodySize, weight: .semibold))
                .foregroundStyle(.white.opacity(0.75))
        }
        .onAppear {
            withAnimation(.spring(duration: 0.9, bounce: 0.5)) { shown = true }
        }
    }
}

private struct SummaryStage: View {
    @Environment(\.reelStageLayout) private var layout
    let item: ReelItem
    @State private var shown = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("IN \(item.card.agent.shortName.uppercased())'S WORDS")
                .font(.caption.weight(.heavy))
                .tracking(1.5)
                .foregroundStyle(item.palette.primary)
            Text(item.card.agentIntent ?? item.explainer.whatChanges)
                .font(.system(size: layout.tight ? 19 : 24, weight: .medium, design: .rounded))
                .lineLimit(11)
                .minimumScaleFactor(0.6)
                .textRenderer(RevealRenderer(progress: shown ? 1 : 0))
        }
        .onAppear {
            withAnimation(.easeOut(duration: 2.2)) { shown = true }
        }
    }
}

private struct NextStage: View {
    @Environment(\.reelStageLayout) private var layout
    let item: ReelItem
    @Environment(ReelStore.self) private var store

    private let ideas = ["Add tests for this", "Polish the UI", "Explain what you built", "Commit this work"]

    var body: some View {
        VStack(alignment: .leading, spacing: layout.spacing) {
            Text("What should \(item.card.agent.shortName) do next?")
                .font(.system(size: layout.tight ? 28 : 36, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
            if item.status.isPending {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(ideas, id: \.self) { idea in
                        Button {
                            store.requestDecision(for: item, note: idea)
                        } label: {
                            Label(idea, systemImage: "arrow.up.right")
                                .font(.system(size: layout.tight ? 12 : 15, weight: .semibold))
                                .padding(.horizontal, 14).padding(.vertical, layout.tight ? 9 : 11)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.interactive(), in: .capsule)
                    }
                }
            }
        }
    }
}
