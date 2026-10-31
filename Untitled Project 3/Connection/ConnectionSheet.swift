import AVFoundation
import VibieKit
import SwiftUI
import UIKit

/// Pairing, connection status and Mac setup instructions.
struct ConnectionSheet: View {
    @Environment(BridgeClient.self) private var bridge
    @Environment(ReelStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var scanning = false
    @State private var confirmForget = false
    @State private var pasteProblem: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    statusHeader
                }
                .listRowBackground(Color.clear)

                if let mac = bridge.mac {
                    Section {
                        LabeledContent("Mac", value: mac.name)
                        LabeledContent("Mac fingerprint", value: bridge.macFingerprint ?? "—")
                        LabeledContent("This iPhone", value: bridge.deviceFingerprint)
                    } header: {
                        Text("Paired")
                    } footer: {
                        Text("Your Mac's terminal shows the same two codes. If they match, nobody is listening in between.")
                    }
                    .monospacedDigit()
                }

                Section {
                    Button {
                        scanning = true
                    } label: {
                        Label("Scan pairing code", systemImage: "qrcode.viewfinder")
                    }
                    PasteButton(payloadType: String.self) { strings in
                        let text = strings.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        Task { @MainActor in
                            if let url = URL(string: text), bridge.handle(url: url) {
                                pasteProblem = nil
                            } else {
                                pasteProblem = "That isn't a Vibie pairing link. It starts with vibie://pair"
                            }
                        }
                    }
                    if let pasteProblem {
                        Text(pasteProblem).font(.footnote).foregroundStyle(.pink)
                    }
                    if bridge.isPaired, bridge.phase != .live {
                        Button {
                            bridge.connect()
                        } label: {
                            Label("Reconnect now", systemImage: "arrow.clockwise")
                        }
                    }
                } header: {
                    Text(bridge.isPaired ? "Pair again" : "Pair")
                }

                Section {
                    Toggle(isOn: Binding(
                        get: { store.mode == .demo },
                        set: { $0 ? store.startDemo() : store.leaveDemo() })) {
                        Label("Demo feed", systemImage: "play.rectangle.on.rectangle")
                    }
                } footer: {
                    Text("Plays a scripted Claude Code session so you can try Vibie without a Mac.")
                }

                Section("Set up your Mac") {
                    SetupStep(number: 1, text: "Build the bridge (in this repo's Bridge folder):", command: "swift build -c release")
                    SetupStep(number: 2, text: "Hook it into your project:", command: ".build/release/vibie install-hooks ~/code/my-app")
                    SetupStep(number: 3, text: "Start it, then scan the code it shows:", command: ".build/release/vibie serve")
                }

                if bridge.mac != nil {
                    Section {
                        Button("Forget this Mac", role: .destructive) { confirmForget = true }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(ReelBackground(palette: Palette(kind: .create, risk: .low), animate: true).opacity(0.6))
            .navigationTitle("Your Mac")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $scanning) {
                ScannerSheet { url in
                    scanning = false
                    bridge.handle(url: url)
                }
            }
            .confirmationDialog("Forget \(bridge.mac?.name ?? "this Mac")?", isPresented: $confirmForget, titleVisibility: .visible) {
                Button("Forget", role: .destructive) {
                    bridge.forget()
                    store.startDemo()
                }
            } message: {
                Text("You'll need to scan a new pairing code to reconnect.")
            }
        }
    }

    private var statusHeader: some View {
        HStack(spacing: 16) {
            Image(systemName: statusSymbol)
                .font(.system(size: 30, weight: .semibold))
                .symbolEffect(.pulse, isActive: bridge.phase == .connecting)
                .frame(width: 64, height: 64)
                .glassEffect(.regular.tint(statusColor.opacity(0.4)), in: .circle)
            VStack(alignment: .leading, spacing: 4) {
                Text(statusTitle).font(.headline)
                Text(statusDetail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private var statusSymbol: String {
        switch bridge.phase {
        case .live: "lock.shield.fill"
        case .connecting: "antenna.radiowaves.left.and.right"
        case .unpaired: "laptopcomputer"
        case .offline, .failed: "wifi.exclamationmark"
        }
    }

    private var statusColor: Color {
        switch bridge.phase {
        case .live: .green
        case .connecting: .yellow
        case .unpaired: .gray
        case .offline, .failed: .red
        }
    }

    private var statusTitle: String {
        switch bridge.phase {
        case .live: "Connected to \(bridge.mac?.name ?? "your Mac")"
        case .connecting: "Connecting…"
        case .unpaired: "No Mac paired"
        case .offline: "\(bridge.mac?.name ?? "Mac") is offline"
        case .failed: "Couldn't connect"
        }
    }

    private var statusDetail: String {
        switch bridge.phase {
        case .live: "End-to-end encrypted over your local network."
        case .connecting: "Looking for the bridge on your network."
        case .unpaired: "Run the bridge on your Mac and scan its code."
        case .offline: "Start `vibie serve` and it'll reconnect."
        case .failed(let message): message
        }
    }
}

private struct SetupStep: View {
    let number: Int
    let text: String
    let command: String
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(number). \(text)").font(.subheadline)
            HStack {
                Text(command)
                    .font(.caption.monospaced())
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    UIPasteboard.general.string = command
                    copied = true
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.borderless)
            }
            .padding(10)
            .background(.black.opacity(0.35), in: .rect(cornerRadius: 10))
        }
        .padding(.vertical, 4)
    }
}

private struct ScannerSheet: View {
    var onURL: (URL) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var problem: String?

    var body: some View {
        ZStack {
            QRScannerView { code in
                if let url = URL(string: code), PairingInvite(url: url) != nil {
                    onURL(url)
                } else {
                    problem = "That QR code isn't a Vibie pairing code."
                }
            } onUnavailable: { reason in
                problem = reason
            }
            .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.headline).frame(width: 40, height: 40)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                }
                Spacer()
                RoundedRectangle(cornerRadius: 32)
                    .strokeBorder(.white.opacity(0.85), style: StrokeStyle(lineWidth: 4, dash: [24, 14]))
                    .frame(width: 250, height: 250)
                Spacer()
                Text(problem ?? "Point at the QR code in your Mac's terminal")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(16)
                    .glassEffect(.regular, in: .rect(cornerRadius: 20))
            }
            .padding(24)
        }
        .background(.black)
    }
}

struct QRScannerView: UIViewControllerRepresentable {
    var onCode: (String) -> Void
    var onUnavailable: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerController {
        let controller = ScannerController()
        controller.onCode = onCode
        controller.onUnavailable = onUnavailable
        return controller
    }

    func updateUIViewController(_ controller: ScannerController, context: Context) {}
}

final class ScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCode: ((String) -> Void)?
    var onUnavailable: ((String) -> Void)?
    private let session = AVCaptureSession()
    private var preview: AVCaptureVideoPreviewLayer?
    private var lastCode: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configure()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    granted ? self.configure() : self.onUnavailable?("Camera access is off. You can paste the pairing link instead.")
                }
            }
        default:
            onUnavailable?("Camera access is off. Allow it in Settings, or paste the pairing link instead.")
        }
    }

    private func configure() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            onUnavailable?("No camera here. Copy the vibie:// link from your Mac and use Paste instead.")
            return
        }
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        preview = layer
        let session = session
        DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let session = session
        DispatchQueue.global(qos: .userInitiated).async { session.stopRunning() }
    }

    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        let code = (metadataObjects.first as? AVMetadataMachineReadableCodeObject)?.stringValue
        MainActor.assumeIsolated {
            guard let code, code != lastCode else { return }
            lastCode = code
            onCode?(code)
        }
    }
}
