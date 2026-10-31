import Foundation

/// A small line-based diff, good enough for showing an agent's edits on a phone.
public enum LineDiff {
    public struct Result: Sendable, Equatable {
        public var lines: [DiffLine]
        public var additions: Int
        public var deletions: Int
        public var truncated: Bool
    }

    private enum Op {
        case same(Int, Int)
        case removed(Int)
        case added(Int)
    }

    public static func lines(of text: String) -> [String] {
        guard !text.isEmpty else { return [] }
        var parts = text.components(separatedBy: "\n")
        if parts.last == "" { parts.removeLast() }
        return parts
    }

    public static func diff(
        old: String,
        new: String,
        oldStart: Int = 1,
        newStart: Int = 1,
        context: Int = 3,
        maxLines: Int = 400
    ) -> Result {
        let a = lines(of: old)
        let b = lines(of: new)

        var prefix = 0
        while prefix < a.count, prefix < b.count, a[prefix] == b[prefix] { prefix += 1 }
        var suffix = 0
        while suffix < a.count - prefix, suffix < b.count - prefix,
              a[a.count - 1 - suffix] == b[b.count - 1 - suffix] { suffix += 1 }

        var ops: [Op] = (0..<prefix).map { .same($0, $0) }
        ops += middle(Array(a[prefix..<(a.count - suffix)]), Array(b[prefix..<(b.count - suffix)]), offset: prefix)
        ops += (0..<suffix).map { .same(a.count - suffix + $0, b.count - suffix + $0) }

        var full: [DiffLine] = []
        var additions = 0
        var deletions = 0
        for op in ops {
            switch op {
            case .same(let i, let j):
                full.append(DiffLine(kind: .context, text: a[i], oldNumber: oldStart + i, newNumber: newStart + j))
            case .removed(let i):
                deletions += 1
                full.append(DiffLine(kind: .removed, text: a[i], oldNumber: oldStart + i))
            case .added(let j):
                additions += 1
                full.append(DiffLine(kind: .added, text: b[j], newNumber: newStart + j))
            }
        }

        var lines = collapse(full, context: context)
        let truncated = lines.count > maxLines
        if truncated { lines = Array(lines.prefix(maxLines)) }
        return Result(lines: lines, additions: additions, deletions: deletions, truncated: truncated)
    }

    /// Longest-common-subsequence diff of the part that differs. Falls back to
    /// "remove everything, add everything" when the region is too big to compare.
    private static func middle(_ a: [String], _ b: [String], offset: Int) -> [Op] {
        let n = a.count, m = b.count
        if n == 0 { return (0..<m).map { .added(offset + $0) } }
        if m == 0 { return (0..<n).map { .removed(offset + $0) } }
        guard n * m <= 2_000_000 else {
            return (0..<n).map { .removed(offset + $0) } + (0..<m).map { .added(offset + $0) }
        }

        let width = m + 1
        var table = [Int32](repeating: 0, count: (n + 1) * width)
        for i in stride(from: n - 1, through: 0, by: -1) {
            for j in stride(from: m - 1, through: 0, by: -1) {
                table[i * width + j] = a[i] == b[j]
                    ? table[(i + 1) * width + j + 1] + 1
                    : max(table[(i + 1) * width + j], table[i * width + j + 1])
            }
        }

        var ops: [Op] = []
        var i = 0, j = 0
        while i < n, j < m {
            if a[i] == b[j] {
                ops.append(.same(offset + i, offset + j)); i += 1; j += 1
            } else if table[(i + 1) * width + j] >= table[i * width + j + 1] {
                ops.append(.removed(offset + i)); i += 1
            } else {
                ops.append(.added(offset + j)); j += 1
            }
        }
        while i < n { ops.append(.removed(offset + i)); i += 1 }
        while j < m { ops.append(.added(offset + j)); j += 1 }
        return ops
    }

    /// Keeps `context` unchanged lines around each change and folds the rest into gaps.
    private static func collapse(_ lines: [DiffLine], context: Int) -> [DiffLine] {
        let changed = lines.indices.filter { lines[$0].kind != .context }
        guard !changed.isEmpty else { return [] }

        var keep = [Bool](repeating: false, count: lines.count)
        for index in changed {
            for k in max(0, index - context)...min(lines.count - 1, index + context) { keep[k] = true }
        }

        var out: [DiffLine] = []
        var skipped = 0
        for (index, line) in lines.enumerated() {
            if keep[index] {
                if skipped > 0 { out.append(gap(skipped)); skipped = 0 }
                out.append(line)
            } else {
                skipped += 1
            }
        }
        if skipped > 0 { out.append(gap(skipped)) }
        return out
    }

    private static func gap(_ count: Int) -> DiffLine {
        DiffLine(kind: .gap, text: count == 1 ? "1 unchanged line" : "\(count) unchanged lines")
    }
}
