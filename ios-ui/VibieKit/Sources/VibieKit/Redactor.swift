import Foundation

/// Scrubs likely secrets on the Mac before anything is sent to the phone.
public enum Redactor {
    public static let mask = "•••redacted•••"

    private static let rules: [(NSRegularExpression, String)] = {
        let specs: [(String, String)] = [
            // Provider-shaped keys: OpenAI / Anthropic / Stripe style, AWS, GitHub, Slack, Google, JWTs.
            (#"\b(?:sk|pk|rk)[-_](?:live|test|proj|ant)?[-_]?[A-Za-z0-9_\-]{16,}"#, mask),
            (#"\bAKIA[0-9A-Z]{16}\b"#, mask),
            (#"\bgh[pousr]_[A-Za-z0-9]{30,}\b"#, mask),
            (#"\bgithub_pat_[A-Za-z0-9_]{30,}\b"#, mask),
            (#"\bxox[abposr]-[A-Za-z0-9-]{10,}"#, mask),
            (#"\bAIza[0-9A-Za-z_\-]{35}\b"#, mask),
            (#"\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}"#, mask),
            (#"-----BEGIN [A-Z ]*PRIVATE KEY-----"#, "-----BEGIN PRIVATE KEY----- " + mask),
            // password = "hunter22", apiKey: 'abc…' (quoted values only, so `password: string` survives)
            (#"(?i)((?:api[_-]?key|secret|token|passw(?:or)?d|private[_-]?key|client[_-]?secret)[\w-]*["']?\s*[:=]\s*)(["'])[^"'\s]{6,}\2"#, "$1$2" + mask + "$2"),
            // SESSION_SECRET=abc123 (env-style assignments)
            (#"\b([A-Z][A-Z0-9_]*(?:KEY|SECRET|TOKEN|PASSWORD|PASSWD)[A-Z0-9_]*\s*=\s*)[^\s"']{6,}"#, "$1" + mask),
            // postgres://user:password@host
            (#"(\b[a-z][a-z0-9+.-]*://[^:/\s]+:)[^@\s]+(@)"#, "$1" + mask + "$2"),
        ]
        return specs.compactMap { pattern, template in
            (try? NSRegularExpression(pattern: pattern)).map { ($0, template) }
        }
    }()

    /// Returns the scrubbed text and how many secrets were removed.
    public static func redact(_ text: String) -> (text: String, count: Int) {
        var result = text
        var count = 0
        for (regex, template) in rules {
            let range = NSRange(result.startIndex..., in: result)
            let matches = regex.numberOfMatches(in: result, range: range)
            guard matches > 0 else { continue }
            count += matches
            result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: template)
        }
        return (result, count)
    }

    /// Files whose contents never leave the Mac.
    public static func isSensitivePath(_ path: String) -> Bool {
        let name = (path as NSString).lastPathComponent.lowercased()
        let ext = (name as NSString).pathExtension
        if name == ".env" { return true }
        if name.hasPrefix(".env.") {
            return !["example", "sample", "template", "dist"].contains(ext)
        }
        if ["pem", "key", "p12", "pfx", "keystore", "jks", "mobileprovision", "p8"].contains(ext) { return true }
        return ["id_rsa", "id_ed25519", "id_ecdsa", ".npmrc", ".pypirc", ".netrc", "credentials",
                "secrets.json", "secrets.yml", "secrets.yaml", "serviceaccount.json"].contains(name)
    }
}
