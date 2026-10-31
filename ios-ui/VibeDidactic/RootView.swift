import SwiftUI
import VibieKit

struct RootView: View {
    enum Panel: String, Identifiable {
        case privacy, connection
        var id: String { rawValue }
    }

    @Environment(ReelStore.self) private var store
    @Environment(BridgeClient.self) private var bridge
    @Environment(\.scenePhase) private var scenePhase
    @State private var panel: Panel?

    var body: some View {
        GeometryReader { geo in
            let studio = geo.size.width >= 600
            Group {
                if studio {
                    StudioLayout(onPrivacy: { panel = .privacy }, onConnection: { panel = .connection })
                } else {
                    compact
                }
            }
            .onAppear { store.studio = studio }
            .onChange(of: studio) { _, wide in store.studio = wide }
        }
        .background(Color(red: 0.025, green: 0.035, blue: 0.065))
        .overlay(alignment: .top) {
            if let toast = store.toast {
                ToastView(toast: toast)
                    .padding(.top, 58)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .overlay {
            if let request = store.prompt, !store.studio {
                DecisionPrompt(request: request)
                    .id(request.id)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay {
            if store.showIntro {
                WelcomeView(
                    onDemo: {
                        store.finishIntro()
                        if store.mode == .demo { store.startDemo() }
                    },
                    onPair: {
                        store.finishIntro()
                        panel = .connection
                    })
                .transition(.opacity.combined(with: .scale(scale: 1.04)))
            }
        }
        .overlay {
            if scenePhase != .active { PrivacyShield() }
        }
        .animation(.spring(duration: 0.45), value: store.prompt?.id)
        .animation(.spring(duration: 0.4), value: store.toast)
        .animation(.easeInOut(duration: 0.5), value: store.showIntro)
        .sheet(item: $panel) { panel in
            Group {
                switch panel {
                case .privacy: PrivacySheet(onReplayIntro: store.replayIntro)
                case .connection: ConnectionSheet()
                }
            }
            .environment(store)
            .environment(bridge)
            .preferredColorScheme(.dark)
        }
        .onChange(of: panel) { _, open in store.panelOpen = open != nil }
        .onChange(of: store.showIntro) { _, showing in store.panelOpen = showing }
        .task {
            store.connect(bridge)
            store.panelOpen = store.showIntro
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { bridge.resume() }
        }
    }

    private var compact: some View {
        VStack(spacing: 12) {
            FeedHeader(onPrivacy: { panel = .privacy }, onConnection: { panel = .connection })
            if let step = store.coach {
                CoachTipView(step: step)
            }
            ReelFeedView(onPair: { panel = .connection }, clearance: EdgeInsets())
                .clipShape(.rect(cornerRadius: 30))
                .overlay(RoundedRectangle(cornerRadius: 30).strokeBorder(.white.opacity(0.1)))
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
        }
        .animation(.spring(duration: 0.4), value: store.coach)
    }
}
