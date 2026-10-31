import VibieKit
import SwiftUI

/// Slowly drifting mesh gradient behind every reel, tinted by the kind of change and its risk.
struct ReelBackground: View {
    let palette: Palette
    let animate: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !animate)) { context in
            let t = Float(context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10_000))
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    SIMD2<Float>(0, 0), SIMD2<Float>(0.5, 0), SIMD2<Float>(1, 0),
                    SIMD2<Float>(0, 0.45 + 0.08 * sin(t * 0.6)),
                    SIMD2<Float>(0.5 + 0.18 * cos(t * 0.45), 0.5 + 0.14 * sin(t * 0.7)),
                    SIMD2<Float>(1, 0.55 + 0.08 * cos(t * 0.5)),
                    SIMD2<Float>(0, 1), SIMD2<Float>(0.5, 1), SIMD2<Float>(1, 1),
                ],
                colors: [
                    .black, palette.secondary.opacity(0.24), .black,
                    palette.primary.opacity(0.22), palette.secondary.opacity(0.42), palette.primary.opacity(0.16),
                    .black, palette.primary.opacity(0.08), .black,
                ])
        }
        .background(Color(red: 0.025, green: 0.035, blue: 0.065))
        .overlay {
            LinearGradient(colors: [.black.opacity(0.35), .clear, .clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
        }
        .ignoresSafeArea()
    }
}

/// Fades, lifts and un-blurs text glyph by glyph as `progress` animates from 0 to 1.
nonisolated struct RevealRenderer: TextRenderer, Animatable {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        var slices: [Text.Layout.RunSlice] = []
        for line in layout {
            for run in line {
                for slice in run { slices.append(slice) }
            }
        }
        let count = Double(max(slices.count, 1))
        for (index, slice) in slices.enumerated() {
            let start = Double(index) / count * 0.6
            let local = min(max((progress - start) / 0.4, 0), 1)
            var copy = context
            copy.opacity = local
            copy.translateBy(x: 0, y: (1 - local) * 10)
            if local < 1 { copy.addFilter(.blur(radius: (1 - local) * 5)) }
            copy.draw(slice)
        }
    }
}

struct RailButton: View {
    let symbol: String
    let label: String
    var badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 21, weight: .semibold))
                    .frame(width: 50, height: 50)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .overlay(alignment: .topTrailing) {
                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.heavy))
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(.green, in: .capsule)
                                .offset(x: 6, y: -4)
                        }
                    }
                Text(label)
                    .font(.caption2.weight(.bold))
                    .shadow(radius: 3)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct CircleGlassButton: View {
    let symbol: String
    var dot: Color?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 42, height: 42)
                .glassEffect(.regular.interactive(), in: .circle)
                .overlay(alignment: .topTrailing) {
                    if let dot {
                        Circle().fill(dot).frame(width: 10, height: 10)
                            .overlay(Circle().stroke(.black, lineWidth: 2))
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

struct KindBadge: View {
    let kind: ChangeKind
    var small = false

    var body: some View {
        Label(kind.label, systemImage: kind.symbol)
            .font(small ? .caption2.weight(.heavy) : .caption.weight(.heavy))
            .tracking(1.2)
            .padding(.horizontal, small ? 8 : 12)
            .padding(.vertical, small ? 4 : 7)
            .glassEffect(.regular, in: .capsule)
    }
}

struct AIBadge: View {
    var body: some View {
        Label("On-device AI", systemImage: "apple.intelligence")
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .glassEffect(.regular.tint(.purple.opacity(0.35)), in: .capsule)
    }
}

struct StatPill: View {
    let value: Int
    let positive: Bool
    @State private var shown = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(positive ? "+" : "−")\(shown)")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .contentTransition(.numericText(value: Double(shown)))
                .foregroundStyle(positive ? Color.green : Color.pink)
            Text(positive ? "lines added" : "lines removed")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
        .task {
            try? await Task.sleep(for: .milliseconds(350))
            withAnimation(.snappy(duration: 0.8)) { shown = value }
        }
    }
}

struct RiskMeter: View {
    let level: RiskLevel
    @State private var value = 0.0

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width, geo.size.height * 2)
            ZStack(alignment: .bottom) {
                Circle()
                    .trim(from: 0.5, to: 1)
                    .stroke(
                        AngularGradient(colors: [.mint, .yellow, .orange, .pink], center: .center,
                                        startAngle: .degrees(180), endAngle: .degrees(360)),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .frame(width: width - 16, height: width - 16)
                    .frame(width: width, height: width / 2, alignment: .top)
                    .offset(y: 8)
                    .clipped()
                Capsule()
                    .fill(.white)
                    .frame(width: 5, height: width * 0.38)
                    .rotationEffect(.degrees(-90 + value * 180), anchor: .bottom)
                    .shadow(radius: 4)
                Circle().fill(.white).frame(width: 18, height: 18).offset(y: 9)
            }
            .frame(width: width, height: width / 2)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            withAnimation(.spring(response: 1.1, dampingFraction: 0.5).delay(0.15)) { value = level.gauge }
        }
        .onChange(of: level) { _, new in
            withAnimation(.spring) { value = new.gauge }
        }
    }
}

struct ToastView: View {
    let toast: Toast

    var body: some View {
        Label(toast.text, systemImage: toast.symbol)
            .font(.subheadline.weight(.semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.white)
            .padding(.horizontal, 18).padding(.vertical, 12)
            .glassEffect(.regular.tint(toast.tint.opacity(0.35)), in: .capsule)
            .padding(.horizontal, 24)
    }
}

/// A soft glowing orb that breathes differently depending on what the agent is doing.
struct AgentOrb: View {
    let state: AgentStatus.State

    private var colors: [Color] {
        switch state {
        case .working: [.purple, .cyan, .indigo]
        case .waiting: [.orange, .pink, .yellow]
        case .idle: [.indigo, .blue, .teal]
        }
    }

    private var symbol: String {
        switch state {
        case .working: "sparkles"
        case .waiting: "hand.raised.fill"
        case .idle: "moon.zzz.fill"
        }
    }

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let speed = state == .working ? 1.6 : 0.6
            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(colors[index].gradient)
                        .frame(width: 120, height: 120)
                        .offset(x: cos(t * speed + Double(index) * 2.1) * 26, y: sin(t * speed * 0.8 + Double(index) * 2.1) * 26)
                        .blur(radius: 26)
                        .opacity(0.85)
                }
                Image(systemName: symbol)
                    .font(.system(size: 38, weight: .bold))
                    .symbolEffect(.pulse, isActive: state == .working)
            }
            .scaleEffect(1 + 0.05 * sin(t * speed * 2))
        }
        .frame(width: 200, height: 200)
    }
}
