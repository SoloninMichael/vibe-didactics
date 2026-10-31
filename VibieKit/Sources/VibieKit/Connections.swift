import CryptoKit
import Foundation
import Network

public enum FrameError: Error, Sendable {
    case tooLarge(Int)
}

/// Length-prefixed frames: a 4-byte big-endian length, then the payload.
public struct FrameBuffer: Sendable {
    public static let maxFrameSize = 8 * 1024 * 1024
    private var storage = Data()

    public init() {}

    public mutating func append(_ data: Data) {
        storage.append(data)
    }

    public mutating func next() throws -> Data? {
        guard storage.count >= 4 else { return nil }
        let s = storage.startIndex
        let length = Int(storage[s]) << 24 | Int(storage[s + 1]) << 16 | Int(storage[s + 2]) << 8 | Int(storage[s + 3])
        guard length <= Self.maxFrameSize else { throw FrameError.tooLarge(length) }
        guard storage.count >= 4 + length else { return nil }
        let frame = Data(storage[(s + 4)..<(s + 4 + length)])
        storage = Data(storage[(s + 4 + length)...])
        return frame
    }

    public static func encode(_ payload: Data) -> Data {
        var out = Data(capacity: payload.count + 4)
        withUnsafeBytes(of: UInt32(payload.count).bigEndian) { out.append(contentsOf: $0) }
        out.append(payload)
        return out
    }
}

/// Sends and receives frames over an `NWConnection`. All callbacks run on `queue`.
public final class FrameConnection: @unchecked Sendable {
    public let queue: DispatchQueue
    public var onReady: (@Sendable () -> Void)?
    public var onFrame: (@Sendable (Data) -> Void)?
    public var onClose: (@Sendable (Error?) -> Void)?

    private let connection: NWConnection
    private var buffer = FrameBuffer()
    private var closed = false

    public init(connection: NWConnection, queue: DispatchQueue) {
        self.connection = connection
        self.queue = queue
    }

    public var remoteEndpoint: NWEndpoint { connection.endpoint }

    public func start() {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                self.onReady?()
                self.receive()
            case .waiting(let error), .failed(let error):
                // Treat "waiting" (refused, unreachable, permission pending) as a
                // failure so callers can fall back to the next address.
                self.close(error)
            case .cancelled:
                self.close(nil)
            default:
                break
            }
        }
        connection.start(queue: queue)
    }

    public func send(_ payload: Data, completion: (@Sendable () -> Void)? = nil) {
        connection.send(content: FrameBuffer.encode(payload), completion: .contentProcessed { [weak self] error in
            if let error { self?.close(error) }
            completion?()
        })
    }

    public func close(_ error: Error? = nil) {
        guard !closed else { return }
        closed = true
        connection.cancel()
        onClose?(error)
    }

    private func receive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1 << 16) { [weak self] data, _, isComplete, error in
            guard let self, !self.closed else { return }
            if let data, !data.isEmpty {
                self.buffer.append(data)
                do {
                    while !self.closed, let frame = try self.buffer.next() {
                        self.onFrame?(frame)
                    }
                } catch {
                    self.close(error)
                    return
                }
            }
            if let error { self.close(error); return }
            if isComplete { self.close(nil); return }
            self.receive()
        }
    }
}

/// An end-to-end encrypted, mutually authenticated session between the phone and the bridge.
public final class SecureSession: @unchecked Sendable {
    public enum Role: @unchecked Sendable {
        case client(identity: Curve25519.KeyAgreement.PrivateKey, bridgeKey: Curve25519.KeyAgreement.PublicKey, pairingSecret: Data?, deviceName: String)
        case server(identity: Curve25519.KeyAgreement.PrivateKey, name: String, authorize: @Sendable (ClientHello) -> Bool)
    }

    /// Called once the peer has proven it holds its identity key.
    public var onEstablished: (@Sendable (_ peerIdentity: Data, _ peerName: String) -> Void)?
    public var onMessage: (@Sendable (WireMessage) -> Void)?
    public var onClose: (@Sendable (Error?) -> Void)?
    public let queue: DispatchQueue

    private let frames: FrameConnection
    private let role: Role
    private let ephemeral = Curve25519.KeyAgreement.PrivateKey()
    private var channel: SecureChannel?
    private var confirmed = false
    private var peerIdentity = Data()
    private var peerName = ""

    public init(connection: NWConnection, role: Role, queue: DispatchQueue) {
        self.queue = queue
        self.role = role
        self.frames = FrameConnection(connection: connection, queue: queue)
    }

    public var remoteEndpoint: NWEndpoint { frames.remoteEndpoint }

    public func start(handshakeTimeout: TimeInterval = 10) {
        frames.onReady = { [weak self] in self?.sendClientHello() }
        frames.onFrame = { [weak self] data in self?.receive(data) }
        frames.onClose = { [weak self] error in self?.onClose?(error) }
        frames.start()
        queue.asyncAfter(deadline: .now() + handshakeTimeout) { [weak self] in
            guard let self, !self.confirmed else { return }
            self.frames.close(SecureChannelError.timedOut)
        }
    }

    public func send(_ message: WireMessage) {
        queue.async { [weak self] in self?.sendNow(message) }
    }

    public func cancel() {
        queue.async { [weak self] in self?.frames.close(nil) }
    }

    private func sendNow(_ message: WireMessage) {
        guard channel != nil,
              let plaintext = try? WireCoding.encode(message),
              let sealed = try? channel?.seal(plaintext)
        else { return }
        frames.send(sealed)
    }

    private func sendClientHello() {
        guard case .client(let identity, _, let secret, let deviceName) = role else { return }
        let identityKey = identity.publicKey.rawRepresentation
        let ephemeralKey = ephemeral.publicKey.rawRepresentation
        let proof = secret.map { Handshake.pairingProof(secret: $0, identityKey: identityKey, ephemeralKey: ephemeralKey) }
        let hello = ClientHello(version: Vibie.protocolVersion, identityKey: identityKey, ephemeralKey: ephemeralKey, deviceName: deviceName, pairingProof: proof)
        guard let data = try? WireCoding.encode(hello) else { return }
        frames.send(data)
    }

    private func receive(_ data: Data) {
        if channel != nil {
            do {
                guard let plaintext = try channel?.open(data) else { return }
                let message = try WireCoding.decode(WireMessage.self, from: plaintext)
                if !confirmed {
                    confirmed = true
                    onEstablished?(peerIdentity, peerName)
                }
                onMessage?(message)
            } catch {
                frames.close(error)
            }
            return
        }

        do {
            switch role {
            case .server(let identity, let name, let authorize):
                let hello = try WireCoding.decode(ClientHello.self, from: data)
                guard hello.version == Vibie.protocolVersion, authorize(hello) else {
                    throw SecureChannelError.unauthorized
                }
                channel = try Handshake.channel(isClient: false, myIdentity: identity, myEphemeral: ephemeral, peerIdentity: hello.identityKey, peerEphemeral: hello.ephemeralKey)
                peerIdentity = hello.identityKey
                peerName = hello.deviceName
                let reply = ServerHello(version: Vibie.protocolVersion, ephemeralKey: ephemeral.publicKey.rawRepresentation, bridgeName: name)
                frames.send(try WireCoding.encode(reply))

            case .client(let identity, let bridgeKey, _, _):
                let hello = try WireCoding.decode(ServerHello.self, from: data)
                channel = try Handshake.channel(isClient: true, myIdentity: identity, myEphemeral: ephemeral, peerIdentity: bridgeKey.rawRepresentation, peerEphemeral: hello.ephemeralKey)
                peerIdentity = bridgeKey.rawRepresentation
                peerName = hello.bridgeName
                // Key confirmation: only the real phone can produce this frame.
                sendNow(.ping)
            }
        } catch {
            frames.close(error)
        }
    }
}
