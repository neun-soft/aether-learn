import SwiftUI

// One visual per effects lesson. Each one has to make its idea visible with a single knob moving,
// for someone who has never seen a synthesiser.

// MARK: - Delay: the same hit, arriving again later

/// A timeline. The note you play is the tall bar on the left; every repeat after it is drawn at
/// the distance the Time knob sets and the height the Feedback knob leaves it. The point the
/// picture has to make is that nothing new is being created — it is the same hit, arriving again.
struct DelayView: View {
    var time: Double        // 0…1, maps the same way the engine does
    var feedback: Double
    var mix: Double
    var accent: Color

    /// Matches SynthEngine: 0.02 + time² × 0.9 seconds.
    private var seconds: Double { 0.02 + pow(clamp01(time), 2) * 0.9 }
    private let windowSeconds = 2.0

    /// How many repeats are still tall enough to be worth drawing.
    private var repeats: [(t: Double, level: Double)] {
        var out: [(Double, Double)] = []
        var t = seconds
        var level = min(0.92, max(0, feedback))
        var guardCount = 0
        while t < windowSeconds, level > 0.03, guardCount < 40 {
            out.append((t, level))
            t += seconds
            level *= min(0.92, max(0, feedback))
            guardCount += 1
        }
        return out
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("WHAT YOU HEAR, OVER TIME").mono(9, .semibold).tracking(1.2)
                    .foregroundColor(Theme.textDim)
                Spacer()
                Text(mix < 0.02 ? "turn ECHO up" : "\(repeats.count) repeat\(repeats.count == 1 ? "" : "s")")
                    .mono(9).foregroundColor(Theme.textMuted)
            }

            GeometryReader { g in
                ZStack(alignment: .bottomLeading) {
                    // The original.
                    bar(in: g, at: 0, level: 1, isOriginal: true)

                    // Its repeats, fading.
                    ForEach(Array(repeats.enumerated()), id: \.offset) { _, r in
                        bar(in: g, at: r.t, level: r.level * max(0.05, mix), isOriginal: false)
                    }

                    // The gap between the first two bars is what Time means, drawn as a measured
                    // span rather than left for the reader to infer.
                    if mix > 0.02, seconds / windowSeconds < 0.9 {
                        let x0 = g.size.width * 0.02
                        let x1 = g.size.width * (seconds / windowSeconds)
                        Path { p in
                            p.move(to: CGPoint(x: x0, y: 12))
                            p.addLine(to: CGPoint(x: x1, y: 12))
                        }
                        .stroke(Theme.textDim, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        Text(String(format: "%.0f ms", seconds * 1000))
                            .mono(9).foregroundColor(Theme.textMuted)
                            .position(x: (x0 + x1) / 2, y: 4)
                    }
                }
            }
            .frame(height: 132)
            .background(Theme.inset)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack {
                Text("you play here").mono(9).foregroundColor(Theme.textDim)
                Spacer()
                Text("2 seconds later").mono(9).foregroundColor(Theme.textDim)
            }
        }
    }

    @ViewBuilder private func bar(in g: GeometryProxy, at t: Double, level: Double, isOriginal: Bool) -> some View {
        let x = g.size.width * (0.02 + (t / windowSeconds) * 0.96)
        RoundedRectangle(cornerRadius: 2)
            .fill(isOriginal ? Theme.textPrimary.opacity(0.85) : accent)
            .frame(width: isOriginal ? 5 : 4,
                   height: max(3, (g.size.height - 26) * clamp01(level)))
            .position(x: x, y: g.size.height - max(3, (g.size.height - 26) * clamp01(level)) / 2)
    }
}

// MARK: - Comb: two copies close enough to interfere

/// Top: the original wave and its slightly-late copy, drawn over each other so you can see where
/// they push the same way and where they fight. Bottom: what that does to the spectrum, which is
/// the row of notches the effect is named after.
struct CombView: View {
    var time: Double        // 0…1
    var feedback: Double
    var accent: Color

    private var seconds: Double { 0.02 + pow(clamp01(time), 2) * 0.9 }
    private var isShort: Bool { seconds < 0.03 }

    /// Offset of the copy, in cycles of the drawn wave. Kept in a readable range so the fighting
    /// is visible rather than a blur.
    private var offsetCycles: Double { min(0.9, seconds * 60) }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("THE SOUND AND ITS LATE COPY").mono(9, .semibold).tracking(1.2)
                    .foregroundColor(Theme.textDim)
                Spacer()
                Text(isShort ? "too close to hear apart" : "far enough apart to hear twice")
                    .mono(9).foregroundColor(isShort ? accent : Theme.textMuted)
            }

            GeometryReader { g in
                ZStack {
                    wave(in: g, phase: 0)
                        .stroke(Theme.textDim.opacity(0.65), lineWidth: 1.4)
                    wave(in: g, phase: offsetCycles)
                        .stroke(accent.opacity(0.9), lineWidth: 1.4)
                    // Where they add up and where they cancel.
                    wave(in: g, phase: 0, combinedWith: offsetCycles)
                        .stroke(Theme.textPrimary, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                }
            }
            .frame(height: 92)
            .background(Theme.inset)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack(spacing: 12) {
                legend(Theme.textDim.opacity(0.7), "original")
                legend(accent.opacity(0.9), "late copy")
                legend(Theme.textPrimary, "what you hear")
            }

            Text("WHICH FREQUENCIES SURVIVE").mono(9, .semibold).tracking(1.2)
                .foregroundColor(Theme.textDim)
                .frame(maxWidth: .infinity, alignment: .leading)

            // The comb itself: frequencies that line up survive, ones that oppose cancel.
            GeometryReader { g in
                let n = 40
                HStack(alignment: .bottom, spacing: 1) {
                    ForEach(0..<n, id: \.self) { i in
                        let f = Double(i) / Double(n - 1)
                        // |cos| of the delay in cycles at that frequency: the classic comb.
                        let teeth = abs(cos(.pi * f * (2 + offsetCycles * 14)))
                        let h = 0.12 + 0.88 * pow(teeth, 0.7) * (0.35 + 0.65 * min(0.92, feedback))
                        RoundedRectangle(cornerRadius: 1)
                            .fill(accent.opacity(0.35 + 0.55 * h))
                            .frame(width: max(1, g.size.width / CGFloat(n) - 1),
                                   height: max(2, g.size.height * h))
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(height: 66)
            .background(Theme.inset)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(isShort ? "The gaps are frequencies that cancelled out. That row of gaps is the comb."
                         : "Shorten TIME until the gaps appear.")
                .mono(9).foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity)
        }
    }

    private func wave(in g: GeometryProxy, phase: Double, combinedWith other: Double? = nil) -> Path {
        Path { p in
            let n = 200
            for i in 0...n {
                let t = Double(i) / Double(n)
                var v = sin(2 * .pi * (t * 3 - phase))
                if let o = other { v = (v + sin(2 * .pi * (t * 3 - o))) * 0.5 }
                let pt = CGPoint(x: g.size.width * t, y: g.size.height * (0.5 - v * 0.4))
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
        }
    }

    private func legend(_ c: Color, _ label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 1).fill(c).frame(width: 13, height: 2.5)
            Text(label).mono(9).foregroundColor(Theme.textDim)
        }
    }
}

// MARK: - Reverb: one sound arriving thousands of times

/// A room seen from above, with the straight path drawn to the listener and the bounced paths
/// drawn behind it, then the same thing as a timeline: one spike for the direct sound, a few
/// early bounces, then a smear too dense to count. Size moves the walls; Mix fades the bounces.
struct RoomView: View {
    var size: Double        // 0…1
    var mix: Double
    var accent: Color

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("THE ROOM, FROM ABOVE").mono(9, .semibold).tracking(1.2)
                    .foregroundColor(Theme.textDim)
                Spacer()
                Text(mix < 0.02 ? "turn MIX up" : (size < 0.4 ? "a small room" : (size < 0.75 ? "a hall" : "a cathedral")))
                    .mono(9).foregroundColor(Theme.textMuted)
            }

            GeometryReader { g in
                // The walls move outward with Size, so a bigger room is visibly bigger.
                let inset = (1 - clamp01(size)) * 0.22 + 0.04
                let rect = CGRect(x: g.size.width * inset, y: g.size.height * inset * 1.4,
                                  width: g.size.width * (1 - inset * 2),
                                  height: g.size.height * (1 - inset * 2.8))
                let source = CGPoint(x: rect.minX + rect.width * 0.22, y: rect.midY)
                let ear = CGPoint(x: rect.minX + rect.width * 0.80, y: rect.midY)

                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Theme.textDim.opacity(0.6), lineWidth: 1)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)

                    // Bounced paths: off the top wall, the bottom wall, and the far wall.
                    ForEach([0.16, 0.84], id: \.self) { yf in
                        Path { p in
                            let bounce = CGPoint(x: rect.midX, y: rect.minY + rect.height * yf)
                            p.move(to: source); p.addLine(to: bounce); p.addLine(to: ear)
                        }
                        .stroke(accent.opacity(0.30 + 0.5 * clamp01(mix)), lineWidth: 1)
                    }
                    Path { p in
                        let bounce = CGPoint(x: rect.maxX - 3, y: rect.midY - rect.height * 0.18)
                        p.move(to: source); p.addLine(to: bounce); p.addLine(to: ear)
                    }
                    .stroke(accent.opacity(0.22 + 0.45 * clamp01(mix)), lineWidth: 1)

                    // The straight path is always there, whatever the reverb is doing.
                    Path { p in p.move(to: source); p.addLine(to: ear) }
                        .stroke(Theme.textPrimary.opacity(0.9), lineWidth: 2)

                    Circle().fill(Theme.textPrimary).frame(width: 8, height: 8).position(source)
                    Circle().fill(accent).frame(width: 8, height: 8).position(ear)
                    Text("sound").mono(8).foregroundColor(Theme.textDim)
                        .position(x: source.x, y: source.y - 14)
                    Text("you").mono(8).foregroundColor(Theme.textDim)
                        .position(x: ear.x, y: ear.y - 14)
                }
            }
            .frame(height: 116)
            .background(Theme.inset)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            // Arrivals over time: direct, a few countable bounces, then a wash.
            GeometryReader { g in
                ZStack(alignment: .bottomLeading) {
                    let spread = 0.28 + clamp01(size) * 0.66
                    ForEach(0..<70, id: \.self) { i in
                        let seeded = Double((i &* 7919) % 1000) / 1000.0
                        let t = i == 0 ? 0.02 : (0.10 + pow(Double(i) / 70, 0.75) * spread)
                        let level = i == 0 ? 1.0
                            : max(0, (1 - Double(i) / 70)) * (0.35 + seeded * 0.5) * clamp01(mix)
                        RoundedRectangle(cornerRadius: 0.5)
                            .fill(i == 0 ? Theme.textPrimary.opacity(0.9) : accent.opacity(0.75))
                            .frame(width: i == 0 ? 3 : 1.5, height: max(1, g.size.height * level))
                            .position(x: g.size.width * min(0.98, t),
                                      y: g.size.height - max(1, g.size.height * level) / 2)
                    }
                }
            }
            .frame(height: 56)
            .background(Theme.inset)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text("One straight arrival, then thousands of bounces too close together to count.")
                .mono(9).foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity)
        }
    }
}
