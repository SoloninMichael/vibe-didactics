import Foundation

enum Console {
    static let isTerminal = isatty(STDOUT_FILENO) != 0

    static func style(_ text: String, _ code: String) -> String {
        isTerminal ? "\u{1B}[\(code)m\(text)\u{1B}[0m" : text
    }

    static func bold(_ text: String) -> String { style(text, "1") }
    static func dim(_ text: String) -> String { style(text, "2") }
    static func green(_ text: String) -> String { style(text, "32") }
    static func red(_ text: String) -> String { style(text, "31") }
    static func yellow(_ text: String) -> String { style(text, "33") }
    static func cyan(_ text: String) -> String { style(text, "36") }
    static func magenta(_ text: String) -> String { style(text, "35") }

    static func log(_ symbol: String, _ message: String) {
        let time = Date().formatted(date: .omitted, time: .standard)
        print("\(dim(time))  \(symbol)  \(message)")
        fflush(stdout)
    }

    static func success(_ message: String) { log(green("✓"), message) }
    static func warn(_ message: String) { log(yellow("!"), message) }
    static func fail(_ message: String) { log(red("✗"), message) }
}
