import CryptoKit
import Foundation
import Network
import Testing
@testable import VibieKit

@Suite struct LineDiffTests {
    @Test func insertionKeepsLineNumbersAndContext() {
        let old = (1...20).map { "line \($0)" }.joined(separator: "\n") + "\n"
        var newLines = (1...20).map { "line \($0)" }
        newLines.insert("brand new", at: 10)
        let result = LineDiff.diff(old: old, new: newLines.joined(separator: "\n") + "\n")

        #expect(result.additions == 1)
        #expect(result.deletions == 0)
        let added = result.lines.first { $0.kind == .added }
        #expect(added?.text == "brand new")
        #expect(added?.newNumber == 11)
        // 3 lines of context either side, gaps for the rest.
        #expect(result.lines.first?.kind == .gap)
        #expect(result.lines.last?.kind == .gap)
        #expect(result.lines.filter { $0.kind == .context }.count == 6)
    }

    @Test func replacementShowsRemovalThenAddition() {
        let result = LineDiff.diff(old: "a\nb\nc\n", new: "a\nB\nc\n")
        #expect(result.lines.map(\.kind) == [.context, .removed, .added, .context])
        #expect(result.additions == 1 && result.deletions == 1)
    }

    @Test func newFileIsAllAdditions() {
        let result = LineDiff.diff(old: "", new: "one\ntwo\n")
        #expect(result.additions == 2)
        #expect(result.lines.allSatisfy { $0.kind == .added })
    }

    @Test func identicalTextHasNoLines() {
        #expect(LineDiff.diff(old: "same\n", new: "same\n").lines.isEmpty)
    }
}

@Suite struct FramingTests {
    @Test func framesSurviveArbitrarySplits() throws {
        let payloads = [Data("hello".utf8), Data(), Data(repeating: 7, count: 70_000)]
        let stream = payloads.map(FrameBuffer.encode).reduce(Data(), +)
        var buffer = FrameBuffer()
        var out: [Data] = []
        var index = stream.startIndex
        while index < stream.endIndex {
            let end = min(index + 1_337, stream.endIndex)
            buffer.append(stream[index..<end])
            while let frame = try buffer.next() { out.append(frame) }
            index = end
        }
        #expect(out == payloads)
    }

    @Test func oversizedFrameIsRejected() {
        var buffer = FrameBuffer()
        buffer.append(Data([0x7F, 0xFF, 0xFF, 0xFF]))
        #expect(throws: FrameError.self) { try buffer.next() }
    }
}

@Suite struct CryptoTests {
    let phone = Curve25519.KeyAgreement.PrivateKey()
    let bridge = Curve25519.KeyAgreement.PrivateKey()
    let phoneEphemeral = Curve25519.KeyAgreement.PrivateKey()
    let bridgeEphemeral = Curve25519.KeyAgreement.PrivateKey()

    func serverChannel() throws -> SecureChannel {
        try Handshake.channel(isClient: false, myIdentity: bridge, myEphemeral: bridgeEphemeral,
                              peerIdentity: phone.publicKey.rawRepresentation,
                              peerEphemeral: phoneEphemeral.publicKey.rawRepresentation)
    }

    @Test func bothSidesDeriveTheSameKeys() throws {
        var client = try Handshake.channel(isClient: true, myIdentity: phone, myEphemeral: phoneEphemeral,
                                           peerIdentity: bridge.publicKey.rawRepresentation,
                                           peerEphemeral: bridgeEphemeral.publicKey.rawRepresentation)
        var server = try serverChannel()

        let first = try client.seal(Data("approve".utf8))
        #expect(try server.open(first) == Data("approve".utf8))
        let reply = try server.seal(Data("ok".utf8))
        #expect(try client.open(reply) == Data("ok".utf8))

        // Replaying an old frame fails because the nonce counter moved on.
        #expect(throws: SecureChannelError.self) { try server.open(first) }
    }

    @Test func impostorWithoutPhoneKeyCannotTalk() throws {
        let mallory = Curve25519.KeyAgreement.PrivateKey()
        var impostor = try Handshake.channel(isClient: true, myIdentity: mallory, myEphemeral: phoneEphemeral,
                                             peerIdentity: bridge.publicKey.rawRepresentation,
                                             peerEphemeral: bridgeEphemeral.publicKey.rawRepresentation)
        var server = try serverChannel()
        let forged = try impostor.seal(Data("approve".utf8))
        #expect(throws: (any Error).self) { try server.open(forged) }
    }

    @Test func pairingProofNeedsTheSecret() {
        let secret = Data(repeating: 1, count: 32)
        let id = phone.publicKey.rawRepresentation
        let eph = phoneEphemeral.publicKey.rawRepresentation
        let proof = Handshake.pairingProof(secret: secret, identityKey: id, ephemeralKey: eph)
        #expect(Handshake.verifyPairingProof(proof, secret: secret, identityKey: id, ephemeralKey: eph))
        #expect(!Handshake.verifyPairingProof(proof, secret: Data(repeating: 2, count: 32), identityKey: id, ephemeralKey: eph))
    }

    @Test func inviteRoundTripsThroughURL() {
        let invite = PairingInvite(name: "Alex's Mac", bridgeKey: bridge.publicKey.rawRepresentation,
                                   secret: Data(repeating: 9, count: 32), hosts: ["192.168.1.4", "127.0.0.1"],
                                   port: 7766, expires: Date(timeIntervalSinceReferenceDate: 800_000_000))
        #expect(PairingInvite(url: invite.url) == invite)
    }
}

@Suite struct RedactorTests {
    @Test func scrubsCommonSecrets() {
        let samples = [
            "const key = \"sk-ant-api03-abcdefghijklmnopqrstuvwxyz012345\"",
            "aws_access_key_id = AKIAIOSFODNN7EXAMPLE",
            "password = \"hunter2hunter2\"",
            "export STRIPE_SECRET_KEY=sk_live_51Habcdefghijk",
            "DATABASE_URL=postgres://admin:s3cretpw@db.example.com/app",
        ]
        for sample in samples {
            let (text, count) = Redactor.redact(sample)
            #expect(count > 0, "missed: \(sample)")
            #expect(text.contains(Redactor.mask))
        }
    }

    @Test func leavesOrdinaryCodeAlone() {
        for line in ["function login(email: string, password: string) {", "const token = await getToken();", "if (!user) return null"] {
            #expect(Redactor.redact(line).count == 0, "false positive: \(line)")
        }
    }

    @Test func sensitiveFiles() {
        #expect(Redactor.isSensitivePath("/app/.env"))
        #expect(Redactor.isSensitivePath("/app/.env.local"))
        #expect(!Redactor.isSensitivePath("/app/.env.example"))
        #expect(Redactor.isSensitivePath("~/.ssh/id_ed25519"))
        #expect(!Redactor.isSensitivePath("/app/src/env.ts"))
    }
}

private final class Holder: @unchecked Sendable {
    var sessions: [SecureSession] = []
}

@Suite struct SessionTests {
    @Test func pairAndExchangeMessagesOverLoopback() async throws {
        let queue = DispatchQueue(label: "vibie.test")
        let bridgeKey = Curve25519.KeyAgreement.PrivateKey()
        let phoneKey = Curve25519.KeyAgreement.PrivateKey()
        let secret = Data((0..<32).map { _ in UInt8.random(in: .min ... .max) })
        let holder = Holder()
        let (notes, sink) = AsyncStream<String>.makeStream()

        let listener = try NWListener(using: .tcp, on: .any)
        listener.newConnectionHandler = { connection in
            let server = SecureSession(connection: connection, role: .server(identity: bridgeKey, name: "Test Mac", authorize: { hello in
                guard let proof = hello.pairingProof else { return false }
                return Handshake.verifyPairingProof(proof, secret: secret, identityKey: hello.identityKey, ephemeralKey: hello.ephemeralKey)
            }), queue: queue)
            holder.sessions.append(server)
            server.onEstablished = { _, name in
                #expect(name == "Test Phone")
                server.send(.welcome(BridgeInfo(name: "Test Mac")))
            }
            server.onMessage = { message in
                if case .decision(let decision) = message { sink.yield(decision.note ?? "") }
            }
            server.start()
        }
        let (ports, portSink) = AsyncStream<NWEndpoint.Port>.makeStream()
        listener.stateUpdateHandler = { state in
            if case .ready = state, let port = listener.port { portSink.yield(port) }
        }
        listener.start(queue: queue)
        var portIterator = ports.makeAsyncIterator()
        let port = try #require(await portIterator.next())

        let client = SecureSession(
            connection: NWConnection(host: "127.0.0.1", port: port, using: .tcp),
            role: .client(identity: phoneKey, bridgeKey: bridgeKey.publicKey, pairingSecret: secret, deviceName: "Test Phone"),
            queue: queue)
        client.onMessage = { message in
            if case .welcome = message {
                client.send(.decision(DecisionPayload(cardID: UUID(), verdict: .approve, note: "ship it")))
            }
        }
        client.start()

        let note = try await withThrowingTaskGroup(of: String?.self) { group in
            group.addTask { var it = notes.makeAsyncIterator(); return await it.next() }
            group.addTask { try await Task.sleep(for: .seconds(5)); return nil }
            let first = try await group.next() ?? nil
            group.cancelAll()
            return first
        }
        #expect(note == "ship it")
        client.cancel()
        listener.cancel()
    }
}
