import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                PlaceholderTabView(
                    icon: "doc.text.magnifyingglass",
                    title: "AI Code / PR",
                    subtitle: "Upload a code snippet, screenshot, or PR link to deconstruct and learn"
                )
                .navigationTitle("Vibe Didactics")
            }
            .tabItem {
                Label("Code", systemImage: "chevron.left.forwardslash.chevron.right")
            }

            NavigationStack {
                PlaceholderTabView(
                    icon: "cube.transparent.fill",
                    title: "3D Scene & Metaphor",
                    subtitle: "Interactive 3D visual explanation and 'Break It' counterfactual toggle"
                )
                .navigationTitle("3D Explorer")
            }
            .tabItem {
                Label("3D Scene", systemImage: "cube.fill")
            }

            NavigationStack {
                PlaceholderTabView(
                    icon: "rectangle.on.rectangle.angled",
                    title: "Flip Cards",
                    subtitle: "Active recall cards & Socratic questions to verify implementation understanding"
                )
                .navigationTitle("Flip Cards")
            }
            .tabItem {
                Label("Cards", systemImage: "rectangle.stack.fill")
            }

            NavigationStack {
                PlaceholderTabView(
                    icon: "mic.circle.fill",
                    title: "Feynman Voice Check",
                    subtitle: "Explain the AI solution out loud to the Rubber Duck and get instant feedback"
                )
                .navigationTitle("Feynman Check")
            }
            .tabItem {
                Label("Voice", systemImage: "waveform.and.mic")
            }
        }
    }
}

struct PlaceholderTabView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text(title)
                .font(.title2.bold())

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    ContentView()
}
