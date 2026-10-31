import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                PlaceholderTabView(
                    icon: "doc.text.magnifyingglass",
                    title: "AI Код / PR",
                    subtitle: "Сюда будем загружать код, скриншот или ссылку на PR для разбора"
                )
                .navigationTitle("Vibe Didactics")
            }
            .tabItem {
                Label("Код", systemImage: "chevron.left.forwardslash.chevron.right")
            }

            NavigationStack {
                PlaceholderTabView(
                    icon: "cube.transparent.fill",
                    title: "3D Мультик / Сцена",
                    subtitle: "Здесь будет интерактивная 3D-метафора и тумблер «Сломай игрушку»"
                )
                .navigationTitle("3D Разбор")
            }
            .tabItem {
                Label("3D Сцена", systemImage: "cube.fill")
            }

            NavigationStack {
                PlaceholderTabView(
                    icon: "rectangle.on.rectangle.angled",
                    title: "Флип-карточки",
                    subtitle: "Здесь будут карточки для проверки понимания кода и архитектуры"
                )
                .navigationTitle("Карточки")
            }
            .tabItem {
                Label("Карточки", systemImage: "rectangle.stack.fill")
            }

            NavigationStack {
                PlaceholderTabView(
                    icon: "mic.circle.fill",
                    title: "Метод Фейнмана",
                    subtitle: "Объясни решение голосом «плюшевой уточке» и проверь себя"
                )
                .navigationTitle("Фейнман")
            }
            .tabItem {
                Label("Голос", systemImage: "waveform.and.mic")
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
