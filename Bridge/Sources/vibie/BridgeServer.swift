import CryptoKit
import VibieKit
import Foundation
import Network

/// Accepts the iPhone (encrypted, LAN) and hook processes (plain, loopback only),
/// and routes cards one way and decisions the other. Everything runs on `queue`.
final class BridgeServer: @unchecked Sendable {
    private struct Phone {
        let session: SecureSession
        let name: String
        let key: Data
    }

    private struct Pending {
        let card: ChangeCard
        let hook: FrameConnection
        let hookID: ObjectIdentifier
    }

    let queue = DispatchQueue(label: "vibie.bridge")
    private let home: BridgeHome
    private let identity: Curve25519.KeyAgreement.PrivateKey
    private let name: String
    private let port: UInt16
    private let controlPort: UInt16
    private let token: String
    private var trusted: [TrustedPhone]
    private var invite: PairingInvite?
    private var handshaking: [ObjectIdentifier: SecureSession] = [:]
    private var phones: [ObjectIdentifier: Phone] = [:]
    private var hooks: [ObjectIdentifier: FrameConnection] = [:]
    private var pending: [UUID: Pending] = [:]
    private var pendingOrder: [UUID] = []
    private var lastStatus: AgentStatus?
    private var listeners: [NWListener] = []

    init(home: BridgeHome, name: String, port: UInt16, controlPort: UInt16) throws {
        try home.prepare()
        self.home = home
        self.identity = try home.identity()
        self.token = try home.controlToken()
        self.trusted = home.trustedPhones()
        self.name = name
        self.port = port
        self.controlPort = controlPort
    }

    func start(forcePairing: Bool) throws {
        guard let phonePort = NWEndpoint.Port(rawValue: port), let hookPort = NWEndpoint.Port(rawValue: controlPort) else {
            throw POSIXError(.EINVAL)
        }

        let phoneListener = try NWListener(using: .tcp, on: phonePort)
        phoneListener.service = NWListener.Service(name: name, type: Vibie.bonjourType)
        phoneListener.newConnectionHandler = { [weak self] in self?.acceptPhone($0) }
        phoneListener.stateUpdateHandler = { [port] state in
            if case .failed(let error) = state {
                Console.fail("Can't listen on port \(port): \(error). Is another bridge already running?")
                exit(1)
            }
        }

        // Hooks only: bound to 127.0.0.1 so nothing on the network can reach it.
        let loopback = NWParameters.tcp
        loopback.requiredLocalEndpoint = .hostPort(host: .ipv4(.loopback), port: hookPort)
        let hookListener = try NWListener(using: loopback)
        hookListener.newConnectionHandler = { [weak self] in self?.acceptHook($0) }
        hookListener.stateUpdateHandler = { [controlPort] state in
            if case .failed(let error) = state {
                Console.fail("Can't listen for hooks on 127.0.0.1:\(controlPort): \(error)")
                exit(1)
            }
        }

        listeners = [phoneListener, hookListener]
        phoneListener.start(queue: queue)
        hookListener.start(queue: queue)

        printBanner()
        queue.async {
            if forcePairing || self.trusted.isEmpty {
                self.beginPairing()
            } else {
                Console.log("📱", "Waiting for \(self.trusted.map(\.name).joined(separator: ", ")). New phone? Restart with --pair.")
            }
        }
    }

    // MARK: Phone side

    private func acceptPhone(_ connection: NWConnection) {
        let session = SecureSession(
            connection: connection,
            role: .server(identity: identity, name: name, authorize: { [weak self] hello in
                self?.authorize(hello) ?? false
            }),
            queue: queue)
        let id = ObjectIdentifier(session)
        handshaking[id] = session
        session.onEstablished = { [weak self] key, deviceName in self?.phoneEstablished(id, key: key, deviceName: deviceName) }
        session.onMessage = { [weak self] message in self?.handle(message, from: id) }
        session.onClose = { [weak self] _ in self?.phoneClosed(id) }
        session.start()
    }

    private func authorize(_ hello: ClientHello) -> Bool {
        if trusted.contains(where: { $0.key == hello.identityKey }) { return true }
        guard let invite, invite.expires > Date(), let proof = hello.pairingProof,
              Handshake.verifyPairingProof(proof, secret: invite.secret, identityKey: hello.identityKey, ephemeralKey: hello.ephemeralKey)
        else {
            Console.warn("Turned away \(hello.deviceName): not paired. To pair a new phone, restart with --pair.")
            return false
        }
        return true
    }

    private func phoneEstablished(_ id: ObjectIdentifier, key: Data, deviceName: String) {
        guard let session = handshaking.removeValue(forKey: id) else { return }
        if !trusted.contains(where: { $0.key == key }) {
            trusted.append(TrustedPhone(key: key, name: deviceName, pairedAt: Date()))
            try? home.saveTrusted(trusted)
            invite = nil // single use
            Console.success("Paired with \(Console.bold(deviceName))  ·  phone fingerprint \(Console.cyan(Fingerprint.of(key)))")
        }
        phones[id] = Phone(session: session, name: deviceName, key: key)
        Console.log("📱", "\(deviceName) connected  \(Console.dim("(end-to-end encrypted)"))")

        session.send(.welcome(BridgeInfo(name: name)))
        for cardID in pendingOrder {
            if let entry = pending[cardID] { session.send(.card(entry.card)) }
        }
        if let lastStatus { session.send(.status(lastStatus)) }
    }

    private func phoneClosed(_ id: ObjectIdentifier) {
        handshaking.removeValue(forKey: id)
        if let phone = phones.removeValue(forKey: id) {
            Console.log("📴", "\(phone.name) disconnected" + (pending.isEmpty ? "" : " — \(pending.count) change(s) will wait for it"))
        }
    }

    private func handle(_ message: WireMessage, from id: ObjectIdentifier) {
        switch message {
        case .ping:
            phones[id]?.session.send(.pong)
        case .decision(let decision):
            resolve(decision, from: id)
        default:
            break
        }
    }

    private func resolve(_ decision: DecisionPayload, from id: ObjectIdentifier) {
        guard let entry = pending.removeValue(forKey: decision.cardID) else { return }
        pendingOrder.removeAll { $0 == decision.cardID }
        if let data = try? WireCoding.encode(ControlMessage.decision(decision)) {
            entry.hook.send(data)
        }
        let who = phones[id]?.name ?? "phone"
        let verb = entry.card.kind == .checkpoint
            ? (decision.verdict == .approve ? "sent a follow-up" : "let the agent stop")
            : (decision.verdict == .approve ? "approved" : "denied")
        broadcast(.resolved(cardID: decision.cardID, reason: "\(verb.capitalized) on \(who)"), except: id)
        let symbol = decision.verdict == .approve ? Console.green("✓") : Console.red("✗")
        Console.log(symbol, "\(who) \(verb): \(describe(entry.card))" + (decision.note.map { Console.dim("  “\($0)”") } ?? ""))
    }

    private func broadcast(_ message: WireMessage, except: ObjectIdentifier? = nil) {
        for (id, phone) in phones where id != except {
            phone.session.send(message)
        }
    }

    // MARK: Hook side

    private func acceptHook(_ connection: NWConnection) {
        let frames = FrameConnection(connection: connection, queue: queue)
        let id = ObjectIdentifier(frames)
        hooks[id] = frames
        frames.onFrame = { [weak self] data in self?.handleControl(data, hookID: id) }
        frames.onClose = { [weak self] _ in self?.hookClosed(id) }
        frames.start()
    }

    private func handleControl(_ data: Data, hookID: ObjectIdentifier) {
        guard let hook = hooks[hookID] else { return }
        guard let message = try? WireCoding.decode(ControlMessage.self, from: data) else {
            hook.close()
            return
        }

        switch message {
        case .awaitDecision(let token, let card):
            guard token == self.token else { return reject(hook) }
            guard !phones.isEmpty else {
                if let reply = try? WireCoding.encode(ControlMessage.noPhone) {
                    hook.send(reply) { [weak hook] in hook?.close() }
                }
                Console.log("💤", "No phone connected — \(card.agent.displayName) will ask in the terminal: \(describe(card))")
                return
            }
            pending[card.id] = Pending(card: card, hook: hook, hookID: hookID)
            pendingOrder.append(card.id)
            broadcast(.card(card))
            Console.log(Console.magenta("→"), "Sent to phone: \(describe(card))" + (card.redactions > 0 ? Console.yellow("  (\(card.redactions) secret(s) scrubbed)") : ""))

        case .status(let token, let status):
            guard token == self.token else { return reject(hook) }
            lastStatus = status
            broadcast(.status(status))
            hook.close()

        default:
            hook.close()
        }
    }

    private func reject(_ hook: FrameConnection) {
        Console.warn("Ignored a hook with the wrong token.")
        if let reply = try? WireCoding.encode(ControlMessage.rejected("bad token")) {
            hook.send(reply) { [weak hook] in hook?.close() }
        }
    }

    private func hookClosed(_ id: ObjectIdentifier) {
        hooks.removeValue(forKey: id)
        guard let cardID = pendingOrder.first(where: { pending[$0]?.hookID == id }),
              let entry = pending.removeValue(forKey: cardID) else { return }
        pendingOrder.removeAll { $0 == cardID }
        broadcast(.resolved(cardID: cardID, reason: "Handled in the terminal"))
        Console.log(Console.dim("↩"), "Handled in the terminal: \(describe(entry.card))")
    }

    // MARK: Pairing & output

    private func beginPairing() {
        let secret = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
        let invite = PairingInvite(
            name: name,
            bridgeKey: identity.publicKey.rawRepresentation,
            secret: secret,
            hosts: LocalNetwork.ipv4Addresses() + ["127.0.0.1"],
            port: port,
            expires: Date().addingTimeInterval(10 * 60))
        self.invite = invite

        print("")
        print(Console.bold("  Pair your iPhone"))
        print("  Open Vibie → tap the laptop icon → Scan pairing code.\n")
        if let qr = TerminalQR.render(invite.url.absoluteString) {
            print(qr)
        }
        print("  Or open this link on the phone (AirDrop / paste):")
        print("  \(Console.dim(invite.url.absoluteString))\n")
        print("  The code works once and expires in 10 minutes.\n")
        fflush(stdout)
    }

    private func printBanner() {
        let fingerprint = Fingerprint.of(identity.publicKey.rawRepresentation)
        print("""

          \(Console.bold("Vibie bridge"))  ·  \(name)
          🔒 Mac fingerprint \(Console.cyan(fingerprint))  \(Console.dim("(your phone shows the same code)"))
          📡 Phones: port \(port), Bonjour \(Vibie.bonjourType)  ·  Hooks: 127.0.0.1:\(controlPort)
          \(Console.dim("No cloud, no accounts. Ctrl-C to stop."))

        """)
        fflush(stdout)
    }

    private func describe(_ card: ChangeCard) -> String {
        switch card.kind {
        case .command: return "\(card.tool) `\(String((card.command ?? "").prefix(60)))`"
        case .checkpoint: return "turn finished in \(card.project)"
        default: return "\(card.tool) \(card.filePath ?? card.tool)  \(Console.green("+\(card.additions)")) \(Console.red("−\(card.deletions)"))"
        }
    }
}

enum LocalNetwork {
    /// IPv4 addresses the phone might reach us on: Wi-Fi/Ethernet first, then VPNs such as Tailscale.
    static func ipv4Addresses() -> [String] {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return [] }
        defer { freeifaddrs(ifaddr) }

        var preferred: [String] = []
        var others: [String] = []
        for pointer in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let entry = pointer.pointee
            let flags = Int32(entry.ifa_flags)
            guard let address = entry.ifa_addr, address.pointee.sa_family == UInt8(AF_INET),
                  flags & IFF_UP != 0, flags & IFF_LOOPBACK == 0 else { continue }
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            guard getnameinfo(address, socklen_t(address.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 else { continue }
            let ip = host.withUnsafeBufferPointer { String(cString: $0.baseAddress!) }
            guard !ip.hasPrefix("169.254.") else { continue }
            let interface = String(cString: entry.ifa_name)
            if interface.hasPrefix("en") { preferred.append(ip) } else { others.append(ip) }
        }
        return preferred + others
    }
}
