import SwiftUI

// 270° arc knob with vertical-drag, matched to the Aether app's control style.
struct LKnob: View {
    @Binding var value: Double
    var label: String
    var short: String
    var accent: Color
    var size: CGFloat = 66
    var interactive: Bool = true

    private let sweep = 0.75           // 270° of a full circle
    private let travel: CGFloat = 180
    @State private var startValue: Double? = nil

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .trim(from: 0, to: sweep)
                    .stroke(Color.white.opacity(0.08),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(135))
                Circle()
                    .trim(from: 0, to: sweep * value)
                    .stroke(accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(135))
                Text(short)
                    .mono(9, .medium)
                    .foregroundColor(Theme.textDim)
                    .tracking(0.5)
            }
            .frame(width: size, height: size)
            .contentShape(Rectangle())
            .highPriorityGesture(interactive ? drag : nil)

            Text(label)
                .ui(11, .medium)
                .foregroundColor(Theme.textMuted)
        }
        .opacity(interactive ? 1 : 0.6)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { g in
                if startValue == nil { startValue = value }
                let base = startValue ?? value
                value = min(1, max(0, base + Double(-g.translation.height / travel)))
            }
            .onEnded { _ in startValue = nil }
    }
}
