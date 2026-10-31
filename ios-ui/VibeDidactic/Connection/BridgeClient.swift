import CryptoKit
import VibieKit
import Foundation
import Network
import UIKit

struct PairedMac: Codable, Equatable {
    var name: String
    var bridgeKey: Data
    var hosts: [String]
    var port: UInt16
    var pairedAt: Date
}

/// The phone's end of the encrypted link to the Mac bridge.
/// Keys live in the Keychain, bound to this device and never synced to iCloud.
@Observable
final class BridgeClient {
    enum Phase: Equatable {
        case unpaired, offline, connecting, live
        case failed(String)
    }

    private(set) var phase: Phase = .unpaired
    private(set) var mac: PairedMac?

    @ObservationIgnored var onMessage: ((WireMessage) -> Void)?
    @ObservationIgnored private let identity: Curve25519.KeyAgreement.PrivateKey
    @ObservationIgnored private let queue = DispatchQueue(label: "vibie.client")
    @ObservationIgnored private var session: SecureSession?
    @ObservationIgnored private var pairingSecret: Data?
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var retryTask: Task<Void, Never>?
    @ObservationIgnored private var pingTask: Task<Void, Never>?
    @ObservationIgnored private var lastPong = Date()

    init() {
        if let raw = Keychain.data("identity"), let key = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: raw) {
            identity = key
        } else {
            identity = Curve25519.KeyAgreement.PrivateKey()
            Keychain.set(identity.rawRepresentation, for: "identity")
        }
        if let data = Keychain.data("paired-mac"), let saved = try? JSONDecoder().decode(PairedMac.self, from: data) {
            mac = saved
            phase = .offline
        }
    }

    var isPaired: Bool { mac != nil && pairingSecret == nil }
    var deviceFingerprint: String { Fingerprint.of(identity.publicKey.rawRepresentation) }
    var macFingerprint: String? { mac.map { Fingerprint.of($0.bridgeKey) } }

    // MARK: Pairing

    @discardableResult
    func handle(url: URL) -> Bool {
        guard let invite = PairingInvite(url: url) else { return false }
        pair(with: invite)
        return true
    }

    func pair(with invite: PairingInvite) {
        disconnect()
        guard invite.expires > Date() else {
            phase = .failed("That pairing code expired. Run `vibie serve --pair` on your Mac for a fresh one.")
            return
        }
        mac = PairedMac(name: invite.name, bridgeKey: invite.bridgeKey, hosts: invite.hosts, port: invite.port, pairedAt: Date())
        pairingSecret = invite.secret
        connect()
    }

    func forget() {
        disconnect()
        mac = nil
        pairingSecret = nil
        Keychain.delete("paired-mac")
        phase = .unpaired
    }

    // MARK: Connection

    func connect() {
        guard let mac else { phase = .unpaired; return }
        guard phase != .connecting, phase != .live else { return }
        retryTask?.cancel()
        generation += 1
        phase = .connecting
        attempt(endpoints(for: mac), index: 0, generation: generation)
    }

    /// Called when the app comes back to the foreground.
    func resume() {
        guard mac != nil, phase != .live, phase != .connecting else { return }
        connect()
    }

    func disconnect() {
        generation += 1
        retryTask?.cancel()
        pingTask?.cancel()
        session?.cancel()
        session = nil
        if mac != nil { phase = .offline }
    }

    func send(_ message: WireMessage) {
        session?.send(message)
    }

    /// Bonjour by name first (survives IP changes), then each address from the QR code.
    private func endpoints(for mac: PairedMac) -> [NWEndpoint] {
        var list: [NWEndpoint] = [.service(name: mac.name, type: Vibie.bonjourType, domain: "local.", interface: nil)]
        if let port = NWEndpoint.Port(rawValue: mac.port) {
            list += mac.hosts.map { .hostPort(host: NWEndpoint.Host($0), port: port) }
        }
        return list
    }

    private func attempt(_ endpoints: [NWEndpoint], index: Int, generation: Int) {
        guard generation == self.generation, let mac else { return }
        guard index < endpoints.count else {
            session = nil
            phase = .failed("Can't reach \(mac.name). Is `vibie serve` running, and are you on the same network?")
            scheduleRetry(after: 5)
            return
        }
        guard let bridgeKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: mac.bridgeKey) else {
            phase = .failed("This pairing looks damaged. Forget the Mac and pair again.")
            return
        }

        let session = SecureSession(
            connection: NWConnection(to: endpoints[index], using: .tcp),
            role: .client(identity: identity, bridgeKey: bridgeKey, pairingSecret: pairingSecret, deviceName: UIDevice.current.name),
            queue: queue)
        self.session = session
        session.onEstablished = { [weak self, weak session] _, _ in
            DispatchQueue.main.async {
                guard let self, let session else { return }
                self.established(session, generation: generation)
            }
        }
        session.onMessage = { [weak self, weak session] message in
            DispatchQueue.main.async {
                guard let self, let session, self.session === session else { return }
                if case .pong = message { self.lastPong = Date(); return }
                self.onMessage?(message)
            }
        }
        session.onClose = { [weak self, weak session] _ in
            DispatchQueue.main.async {
                guard let self, let session else { return }
                self.closed(session, endpoints: endpoints, index: index, generation: generation)
            }
        }
        session.start(handshakeTimeout: 5)
    }

    private func established(_ session: SecureSession, generation: Int) {
        guard generation == self.generation, self.session === session else { return }
        phase = .live
        lastPong = Date()
        if pairingSecret != nil, let mac, let data = try? JSONEncoder().encode(mac) {
            Keychain.set(data, for: "paired-mac")
            pairingSecret = nil
        }
        startPings(session)
    }

    private func closed(_ session: SecureSession, endpoints: [NWEndpoint], index: Int, generation: Int) {
        guard generation == self.generation, self.session === session else { return }
        pingTask?.cancel()
        if phase == .live {
            self.session = nil
            phase = .offline
            scheduleRetry(after: 1)
        } else {
            attempt(endpoints, index: index + 1, generation: generation)
        }
    }

    private func scheduleRetry(after seconds: Double) {
        retryTask?.cancel()
        retryTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled, let self, UIApplication.shared.applicationState == .active else { return }
            self.connect()
        }
    }

    private func startPings(_ session: SecureSession) {
        pingTask?.cancel()
        pingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                guard let self, self.session === session else { return }
                if Date().timeIntervalSince(self.lastPong) > 40 {
                    session.cancel()
                    return
                }
                session.send(.ping)
            }
        }
    }
}
