import CryptoKit
import VibieKit
import Foundation

struct TrustedPhone: Codable {
    var key: Data
    var name: String
    var pairedAt: Date
}

/// The bridge's private state in `~/.vibie` (or `$VIBIE_HOME`), readable only by you.
struct BridgeHome {
    let directory: URL

    init() {
        if let custom = ProcessInfo.processInfo.environment["VIBIE_HOME"], !custom.isEmpty {
            directory = URL(fileURLWithPath: custom)
        } else {
            directory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".vibie")
        }
    }

    static var defaultName: String {
        Host.current().localizedName ?? "Mac"
    }

    func prepare() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
    }

    func identity() throws -> Curve25519.KeyAgreement.PrivateKey {
        if let data = read("identity.key"), let key = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: data) {
            return key
        }
        let key = Curve25519.KeyAgreement.PrivateKey()
        try write(key.rawRepresentation, to: "identity.key")
        return key
    }

    /// Shared with hook processes so nothing else on this Mac can inject fake cards.
    func controlToken() throws -> String {
        if let token = existingControlToken() { return token }
        let token = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }.base64URLEncodedString()
        try write(Data(token.utf8), to: "control.token")
        return token
    }

    func existingControlToken() -> String? {
        read("control.token").map { String(decoding: $0, as: UTF8.self) }.flatMap { $0.isEmpty ? nil : $0 }
    }

    func trustedPhones() -> [TrustedPhone] {
        read("trusted-phones.json").flatMap { try? JSONDecoder().decode([TrustedPhone].self, from: $0) } ?? []
    }

    func saveTrusted(_ phones: [TrustedPhone]) throws {
        try prepare()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        try write(try encoder.encode(phones), to: "trusted-phones.json")
    }

    func printStatus() {
        guard let key = try? identity() else {
            Console.fail("No bridge identity yet. Run `vibie serve` first.")
            return
        }
        print("\(Console.bold("This Mac"))  \(Self.defaultName)  ·  fingerprint \(Console.cyan(Fingerprint.of(key.publicKey.rawRepresentation)))")
        print("State in \(directory.path)")
        let phones = trustedPhones()
        if phones.isEmpty {
            print("No paired phones. Run `vibie serve --pair`.")
        }
        for phone in phones {
            print("  📱 \(phone.name)  ·  \(Fingerprint.of(phone.key))  ·  paired \(phone.pairedAt.formatted(date: .abbreviated, time: .shortened))")
        }
    }

    private func read(_ name: String) -> Data? {
        try? Data(contentsOf: directory.appendingPathComponent(name))
    }

    private func write(_ data: Data, to name: String) throws {
        let url = directory.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }
}
