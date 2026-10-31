import VibieKit
import SwiftUI

/// A tiny tokenizer that colours keywords, strings, numbers, types and comments.
enum SyntaxTint {
    private static let keywords: Set<String> = [
        "import", "export", "from", "function", "return", "const", "let", "var", "if", "else", "for", "while", "await",
        "async", "class", "struct", "enum", "func", "def", "self", "this", "new", "throw", "throws", "try", "catch", "true",
        "false", "nil", "null", "undefined", "public", "private", "static", "interface", "type", "extends", "implements",
        "guard", "switch", "case", "default", "in", "of", "as", "package", "fn", "pub", "mut", "impl", "yield", "with",
        "lambda", "None", "True", "False", "and", "or", "not", "is", "typeof", "echo", "then", "fi", "do", "done", "sudo",
    ]
    private static let hashComment: Set<String> = ["Python", "Shell", "Ruby", "YAML", "TOML", "Env", "Docker"]
    private static let base = Color.white.opacity(0.92)
    private static let keyword = Color(red: 1.0, green: 0.45, blue: 0.75)
    private static let string = Color(red: 1.0, green: 0.78, blue: 0.45)
    private static let number = Color(red: 0.55, green: 0.85, blue: 1.0)
    private static let typeName = Color(red: 0.55, green: 1.0, blue: 0.85)

    static func attributed(_ line: String, language: String?) -> AttributedString {
        var result = AttributedString()
        func append<S: Sequence>(_ characters: S, _ color: Color) where S.Element == Character {
            var piece = AttributedString(String(characters))
            piece.foregroundColor = color
            result += piece
        }

        let chars = Array(line)
        let hashes = language.map(hashComment.contains) ?? false
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if (c == "/" && i + 1 < chars.count && chars[i + 1] == "/") || (hashes && c == "#") {
                append(chars[i...], .gray)
                break
            }
            if c == "\"" || c == "'" || c == "`" {
                var j = i + 1
                while j < chars.count, chars[j] != c {
                    if chars[j] == "\\" { j += 1 }
                    j += 1
                }
                let end = min(j + 1, chars.count)
                append(chars[i..<end], string)
                i = end
                continue
            }
            if c.isLetter || c == "_" || c == "$" || c == "@" {
                var j = i
                while j < chars.count, chars[j].isLetter || chars[j].isNumber || chars[j] == "_" || chars[j] == "$" || chars[j] == "@" { j += 1 }
                let word = String(chars[i..<j])
                append(word, keywords.contains(word) ? keyword : (word.first?.isUppercase == true ? typeName : base))
                i = j
                continue
            }
            if c.isNumber {
                var j = i
                while j < chars.count, chars[j].isNumber || chars[j] == "." { j += 1 }
                append(chars[i..<j], number)
                i = j
                continue
            }
            var j = i + 1
            while j < chars.count, !(chars[j].isLetter || chars[j].isNumber || "\"'`/#_$@".contains(chars[j])) { j += 1 }
            append(chars[i..<j], base)
            i = j
        }
        return result
    }
}

struct DiffRow: View {
    let line: DiffLine
    let language: String?
    var compact = false

    var body: some View {
        if line.kind == .gap {
            Label(line.text, systemImage: "ellipsis")
                .font(.caption2.monospaced())
                .foregroundStyle(.white.opacity(0.45))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 5)
                .padding(.leading, compact ? 12 : 56)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if !compact {
                    Text((line.newNumber ?? line.oldNumber).map(String.init) ?? "")
                        .frame(width: 34, alignment: .trailing)
                        .foregroundStyle(.white.opacity(0.3))
                }
                Text(marker)
                    .fontWeight(.bold)
                    .foregroundStyle(markerColor)
                    .frame(width: 10)
                Text(SyntaxTint.attributed(line.text, language: language))
                    .opacity(line.kind == .removed ? 0.7 : 1)
                    .lineLimit(compact ? 2 : nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.system(size: compact ? 13 : 12, design: .monospaced))
            .padding(.vertical, compact ? 3 : 2)
            .padding(.horizontal, 10)
            .background(background)
        }
    }

    private var marker: String {
        switch line.kind {
        case .added: "+"
        case .removed: "−"
        default: " "
        }
    }

    private var markerColor: Color {
        line.kind == .added ? .green : .pink
    }

    private var background: Color {
        switch line.kind {
        case .added: .green.opacity(0.16)
        case .removed: .pink.opacity(0.16)
        default: .clear
        }
    }
}

struct CommandBlock: View {
    let command: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("$").foregroundStyle(.green).fontWeight(.bold)
            Text(SyntaxTint.attributed(command, language: "Shell"))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.system(size: 15, design: .monospaced))
        .padding(16)
        .background(.black.opacity(0.5), in: .rect(cornerRadius: 16))
    }
}

/// The whole change, every line.
struct CodePanel: View {
    let item: ReelItem

    private var card: ChangeCard { item.card }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        KindBadge(kind: card.kind, small: true)
                        Spacer(minLength: 4)
                        Text(item.explainer.risk.title)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(item.explainer.risk.color)
                    }
                    Text(item.explainer.headline)
                        .font(.system(size: 23, weight: .semibold, design: .rounded))
                        .tracking(-0.5)
                        .fixedSize(horizontal: false, vertical: true)
                    if let path = card.filePath {
                        Label(path, systemImage: "doc.text")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    if card.kind == .edit || card.kind == .create {
                        HStack(spacing: 12) {
                            Text("+\(card.additions)").foregroundStyle(.green)
                            Text("−\(card.deletions)").foregroundStyle(.pink)
                            if let language = card.language { Text(language).foregroundStyle(.secondary) }
                        }
                        .font(.subheadline.weight(.bold).monospacedDigit())
                    }
                }

                Text(item.explainer.whatChanges)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineSpacing(3)

                if let command = card.command { CommandBlock(command: command) }

                if card.kind == .checkpoint, let summary = card.agentIntent {
                    Text(summary).font(.body)
                }

                if !card.lines.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(card.lines.enumerated()), id: \.offset) { _, line in
                            DiffRow(line: line, language: card.language)
                        }
                    }
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.45), in: .rect(cornerRadius: 16))
                    .clipShape(.rect(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.07)))
                }

                VStack(alignment: .leading, spacing: 6) {
                    if card.truncated {
                        Label("Very long change — only the first part is shown here.", systemImage: "scissors")
                    }
                    if card.redactions > 0 {
                        Label("\(card.redactions) secret\(card.redactions == 1 ? " was" : "s were") scrubbed on your Mac before this reached your phone.", systemImage: "lock.fill")
                            .foregroundStyle(.yellow)
                    }
                    if !card.lines.isEmpty {
                        Label("Green + lines are new, pink − lines are removed, grey lines are unchanged context.", systemImage: "info.circle")
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding(6)
            .padding(.vertical, 8)
            .textSelection(.enabled)
        }
        .scrollIndicators(.hidden)
    }
}

struct CodeSheet: View {
    let item: ReelItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            CodePanel(item: item)
                .padding(16)
                .navigationTitle(item.card.fileName ?? item.card.tool)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}
