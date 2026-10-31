import VibieKit
import SwiftUI

/// What Vibie does with your code, shown live rather than promised in a policy.
struct PrivacySheet: View {
    @Environment(ReelStore.self) private var store
    @Environment(BridgeClient.self) private var bridge
    @Environment(\.dismiss) private var dismiss
    var onReplayIntro: () -> Void = {}

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 40, weight: .bold))
                        .frame(width: 92, height: 92)
                        .glassEffect(.regular.tint(.mint.opacity(0.35)), in: .circle)
                        .padding(.top, 8)
                    Text("Private by design")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                    Text("No servers. No accounts. No analytics. Your code goes from your Mac to your iPhone and nowhere else.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal)

                    GlassEffectContainer(spacing: 10) {
                        VStack(spacing: 10) {
                            PrivacyRow(symbol: "apple.intelligence", tint: .purple, title: "On-device AI",
                                       detail: OnDeviceAI.statusText)
                            PrivacyRow(symbol: "key.horizontal.fill", tint: .mint, title: "End-to-end encrypted",
                                       detail: "X25519 key agreement and ChaCha20-Poly1305, with fresh keys on every connection.\(bridge.macFingerprint.map { " Mac \($0)." } ?? "")")
                            PrivacyRow(symbol: "wifi.router.fill", tint: .cyan, title: "Local network only",
                                       detail: bridge.phase == .live ? "Talking directly to \(bridge.mac?.name ?? "your Mac") right now." : "Talks directly to the bridge on your Mac. No relay in the middle.")
                            PrivacyRow(symbol: "eye.slash.fill", tint: .yellow, title: "Secrets scrubbed on your Mac",
                                       detail: "API keys, passwords and .env files are removed before anything is sent. \(store.totalRedactions) scrubbed this session.")
                            PrivacyRow(symbol: "memorychip.fill", tint: .orange, title: "Nothing saved",
                                       detail: "Reels live in memory and vanish when you close Vibie. Keys stay in this iPhone's Keychain, never iCloud.")
                            PrivacyRow(symbol: "speaker.wave.2.fill", tint: .pink, title: "Narration stays on the phone",
                                       detail: "Voice-over uses the built-in speech synthesizer, offline.")
                            PrivacyRow(symbol: "rectangle.on.rectangle.slash", tint: .indigo, title: "Hidden in the app switcher",
                                       detail: "Your code is blurred whenever Vibie isn't on screen. No passwords needed to get in.")
                        }
                    }

                    HStack(spacing: 12) {
                        Button {
                            store.wipe()
                            dismiss()
                        } label: {
                            Label("Wipe session", systemImage: "trash").frame(maxWidth: .infinity)
                        }
                        .tint(.pink)
                        Button {
                            dismiss()
                            onReplayIntro()
                        } label: {
                            Label("Replay intro", systemImage: "sparkles.tv").frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                }
                .padding()
            }
            .background(ReelBackground(palette: Palette(kind: .checkpoint, risk: .low), animate: true).opacity(0.7))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct PrivacyRow: View {
    let symbol: String
    let tint: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .glassEffect(.regular.tint(tint.opacity(0.25)), in: .circle)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.white.opacity(0.75))
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }
}
