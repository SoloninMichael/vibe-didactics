import SwiftUI

@main
struct VibieApp: App {
    @State private var store = ReelStore()
    @State private var bridge = BridgeClient()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(bridge)
                .preferredColorScheme(.dark)
                .onOpenURL { url in bridge.handle(url: url) }
        }
    }
}
