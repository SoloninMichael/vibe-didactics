import CryptoKit
import Foundation

// Handshake (both sides already know each other's long-term public key from pairing):
//
//   phone  → bridge   ClientHello  { identity key, fresh ephemeral key, pairing proof on first use }
//   bridge → phone    ServerHello  { fresh ephemeral key }
//   both derive keys from ECDH(ephemeral, ephemeral) ‖ ECDH(identity, identity)
//   phone  → bridge   encrypted ping   (proves the phone holds its identity key)
//   bridge → phone    encrypted welcome (proves the bridge holds its identity key)
//
// The ephemeral keys give forward secrecy; the identity keys authenticate both ends.
// Every frame is ChaCha20-Poly1305 with a counter nonce, so replays and reordering fail.

public struct ClientHello: Codable, Sendable {
    public var version: Int
    public var identityKey: Data
    public var ephemeralKey: Data
    public var deviceName: String
    /// HMAC of the keys under the one-time pairing secret. Only sent when pairing.
    public var pairingProof: Data?

    public init(version: Int, identityKey: Data, ephemeralKey: Data, deviceName: String, pairingProof: Data?) {
        self.version = version
        self.identityKey = identityKey
        self.ephemeralKey = ephemeralKey
        self.deviceName = deviceName
        self.pairingProof = pairingProof
    }
}

public struct ServerHello: Codable, Sendable {
    public var version: Int
    public var ephemeralKey: Data
    public var bridgeName: String

    public init(version: Int, ephemeralKey: Data, bridgeName: String) {
        self.version = version
        self.ephemeralKey = ephemeralKey
        self.bridgeName = bridgeName
    }
}

public enum SecureChannelError: Error, Sendable {
    case unauthorized
    case malformed
    case outOfOrder
    case timedOut
}

public enum Handshake {
    public static func pairingProof(secret: Data, identityKey: Data, ephemeralKey: Data) -> Data {
        let code = HMAC<SHA256>.authenticationCode(for: identityKey + ephemeralKey, using: SymmetricKey(data: secret))
        return Data(code)
    }

    public static func verifyPairingProof(_ proof: Data, secret: Data, identityKey: Data, ephemeralKey: Data) -> Bool {
        HMAC<SHA256>.isValidAuthenticationCode(proof, authenticating: identityKey + ephemeralKey, using: SymmetricKey(data: secret))
    }

    public static func channel(
        isClient: Bool,
        myIdentity: Curve25519.KeyAgreement.PrivateKey,
        myEphemeral: Curve25519.KeyAgreement.PrivateKey,
        peerIdentity: Data,
        peerEphemeral: Data
    ) throws -> SecureChannel {
        let peerStatic = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: peerIdentity)
        let peerFresh = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: peerEphemeral)
        let ee = try myEphemeral.sharedSecretFromKeyAgreement(with: peerFresh)
        let ss = try myIdentity.sharedSecretFromKeyAgreement(with: peerStatic)

        var material = Data()
        ee.withUnsafeBytes { material.append(contentsOf: $0) }
        ss.withUnsafeBytes { material.append(contentsOf: $0) }

        let mine = myIdentity.publicKey.rawRepresentation + myEphemeral.publicKey.rawRepresentation
        let theirs = peerIdentity + peerEphemeral
        let transcript = isClient ? mine + theirs : theirs + mine
        let salt = Data(SHA256.hash(data: transcript))
        let ikm = SymmetricKey(data: material)

        let toBridge = HKDF<SHA256>.deriveKey(inputKeyMaterial: ikm, salt: salt, info: Data("vibie/v1/phone->bridge".utf8), outputByteCount: 32)
        let toPhone = HKDF<SHA256>.deriveKey(inputKeyMaterial: ikm, salt: salt, info: Data("vibie/v1/bridge->phone".utf8), outputByteCount: 32)
        return isClient
            ? SecureChannel(sendKey: toBridge, receiveKey: toPhone)
            : SecureChannel(sendKey: toPhone, receiveKey: toBridge)
    }
}

public struct SecureChannel: Sendable {
    private let sendKey: SymmetricKey
    private let receiveKey: SymmetricKey
    private var sendCounter: UInt64 = 0
    private var receiveCounter: UInt64 = 0

    init(sendKey: SymmetricKey, receiveKey: SymmetricKey) {
        self.sendKey = sendKey
        self.receiveKey = receiveKey
    }

    public mutating func seal(_ plaintext: Data) throws -> Data {
        let nonce = try ChaChaPoly.Nonce(data: Self.nonce(sendCounter))
        sendCounter += 1
        return try ChaChaPoly.seal(plaintext, using: sendKey, nonce: nonce).combined
    }

    public mutating func open(_ frame: Data) throws -> Data {
        let box = try ChaChaPoly.SealedBox(combined: frame)
        guard Data(box.nonce) == Self.nonce(receiveCounter) else { throw SecureChannelError.outOfOrder }
        let plaintext = try ChaChaPoly.open(box, using: receiveKey)
        receiveCounter += 1
        return plaintext
    }

    private static func nonce(_ counter: UInt64) -> Data {
        var data = Data(count: 4)
        withUnsafeBytes(of: counter.bigEndian) { data.append(contentsOf: $0) }
        return data
    }
}

public enum Fingerprint {
    /// A short, human-comparable fingerprint of a public key, e.g. `7F3A-91C2-0B4E`.
    public static func of(_ publicKey: Data) -> String {
        let digest = Array(SHA256.hash(data: publicKey).prefix(6))
        let hex = digest.map { String(format: "%02X", $0) }.joined()
        return stride(from: 0, to: hex.count, by: 4).map { offset in
            let start = hex.index(hex.startIndex, offsetBy: offset)
            return String(hex[start..<hex.index(start, offsetBy: 4)])
        }.joined(separator: "-")
    }
}
