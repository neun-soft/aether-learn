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

/// Top: a short burst scrolling past, with its late copy behind it, and underneath the two added
/// together — which is the only one you actually hear. Long waits show two separate arrivals.
/// Shorten the wait and the copy slides into the original until they overlap and start fighting.
/// Bottom: what that fight does to the spectrum, which is the row of gaps the effect is named for.
///
/// Both panels used to be frozen: the copy's offset was clamped before the knob could touch it,
/// so TIME moved nothing. They are driven by the delay in seconds now.
struct CombView: View {
    var time: Double        // 0…1
    var feedback: Double
    var accent: Color

    /// The window drawn across the panel, and the burst that scrolls through it.
    private let window = 0.6        // seconds visible, oldest on the left
    private let repeatEvery = 0.85  // seconds between bursts
    private let carrierHz = 42.0    // slow enough to draw, fast enough to interfere visibly

    private var seconds: Double { 0.02 + pow(clamp01(time), 2) * 0.9 }
    private var isShort: Bool { seconds < 0.03 }

    /// How many copies to draw. Feedback is what sends the sound round again, so it is what puts
    /// more of them on the screen.
    private var copies: Int { 1 + Int(clamp01(feedback) * 2.99) }

    /// The shape of one arrival: a short swell that dies away, so an arrival is a thing you can
    /// point at on the screen.
    private func envelope(_ t: Double) -> Double {
        guard t > 0 else { return 0 }
        let u = t.truncatingRemainder(dividingBy: repeatEvery)
        guard u < 0.3 else { return 0 }
        return exp(-u * 14) * (1 - exp(-u * 120))
    }

    /// The arrival as an actual wave. The top lane draws only the envelopes, because there the
    /// question is *when* each copy lands; the bottom lane needs the wave, because that is where
    /// pushing together and pulling apart happens.
    private func burst(_ t: Double) -> Double {
        envelope(t) * sin(2 * .pi * carrierHz * t)
    }

    /// The original plus every copy: the sum is the only signal that reaches an ear.
    private func heard(_ t: Double) -> Double {
        var v = burst(t)
        for k in 1...copies {
            v += burst(t - seconds * Double(k)) * pow(0.55 + 0.4 * clamp01(feedback), Double(k))
        }
        return v
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("THE SOUND AND ITS LATE COPY").mono(9, .semibold).tracking(1.2)
                    .foregroundColor(Theme.textDim)
                Spacer()
                Text(isShort ? "too close to hear apart" : "far enough apart to hear twice")
                    .mono(9).foregroundColor(isShort ? accent : Theme.textMuted)
            }

            TimelineView(.animation) { ctx in
                let now = ctx.date.timeIntervalSinceReferenceDate
                GeometryReader { g in
                    ZStack {
                        Rectangle().fill(Theme.inset)
                        // Every arrival as a hump on one line: the original, then the copies
                        // trailing it by the wait. This lane is about *when*, so no wave is drawn.
                        trace(in: g, now: now, amp: 0.30, offset: -0.14) { envelope($0) }
                            .stroke(Theme.textDim.opacity(0.85), lineWidth: 1.6)
                        ForEach(1...copies, id: \.self) { k in
                            trace(in: g, now: now, amp: 0.30, offset: -0.14) {
                                envelope($0 - seconds * Double(k)) * pow(0.62, Double(k - 1))
                            }
                            .fill(accent.opacity(0.30 * pow(0.65, Double(k - 1))))
                        }
                        // Their sum, on its own line underneath, wave and all: this is the one
                        // that reaches an ear, and the only one where cancelling shows up.
                        trace(in: g, now: now, amp: 0.24, offset: 0.28) { heard($0) }
                            .stroke(Theme.textPrimary, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                    }
                }
            }
            .frame(height: 104)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack(spacing: 12) {
                legend(Theme.textDim.opacity(0.85), "original")
                legend(accent.opacity(0.9), "late copy")
                legend(Theme.textPrimary, "what you hear")
            }

            Text("WHICH FREQUENCIES SURVIVE").mono(9, .semibold).tracking(1.2)
                .foregroundColor(Theme.textDim)
                .frame(maxWidth: .infinity, alignment: .leading)

            // The comb itself. The gaps sit 1/wait apart, so a short wait spreads them wide and a
            // long one packs them too close to pick out — which is the point the lesson makes:
            // down at the bottom of the knob you stop hearing an echo and start hearing a filter.
            GeometryReader { g in
                let n = 64
                let gaps = min(22.0, 2.2 + seconds * 22)
                HStack(alignment: .bottom, spacing: 1) {
                    ForEach(0..<n, id: \.self) { i in
                        let f = Double(i) / Double(n - 1)
                        let teeth = abs(cos(.pi * f * gaps))
                        let h = 0.10 + 0.90 * pow(teeth, 0.7) * (0.35 + 0.65 * min(0.92, feedback))
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
                         : "Shorten TIME until the copy slides into the original and the gaps spread out.")
                .mono(9).foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity)
        }
    }

    /// Draws a signal across the panel with time running left to right: the left edge is `window`
    /// seconds ago, the right edge is now, so everything scrolls.
    private func trace(in g: GeometryProxy, now: Double, amp: Double, offset: Double,
                       _ value: (Double) -> Double) -> Path {
        Path { p in
            let n = 220
            let mid = g.size.height * (0.5 + offset)
            for i in 0...n {
                let u = Double(i) / Double(n)
                let t = now - window * (1 - u)
                let v = max(-1.6, min(1.6, value(t)))
                let pt = CGPoint(x: g.size.width * u, y: mid - g.size.height * amp * v)
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

/// Just the arrivals, on a timeline. Everybody has already stood in a church or an empty car park,
/// so reverb needs no diagram to explain what it is — what a picture can add is the one thing an
/// ear cannot separate: that the wash is thousands of copies of the same sound, arriving late.
/// One tall line for the sound that reached you straight, a few countable early bounces, then a
/// smear. SIZE spreads it out; MIX raises everything except the straight line.
struct RoomView: View {
    var size: Double        // 0…1
    var mix: Double
    var accent: Color

    private var roomName: String {
        if mix < 0.02 { return "turn MIX up" }
        return size < 0.4 ? "a small room" : (size < 0.75 ? "a hall" : "a cathedral")
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("EVERY ARRIVAL, IN ORDER").mono(9, .semibold).tracking(1.2)
                    .foregroundColor(Theme.textDim)
                Spacer()
                Text(roomName).mono(9).foregroundColor(Theme.textMuted)
            }

            GeometryReader { g in
                ZStack(alignment: .bottomLeading) {
                    // Bigger rooms put more distance between the bounces, so the tail stretches
                    // further to the right and takes longer to die away.
                    let spread = 0.28 + clamp01(size) * 0.66
                    ForEach(0..<110, id: \.self) { i in
                        let seeded = Double((i &* 7919) % 1000) / 1000.0
                        let t = i == 0 ? 0.02 : (0.10 + pow(Double(i) / 110, 0.75) * spread)
                        let level = i == 0 ? 1.0
                            : max(0, (1 - Double(i) / 110)) * (0.35 + seeded * 0.5) * clamp01(mix)
                        RoundedRectangle(cornerRadius: 0.5)
                            .fill(i == 0 ? Theme.textPrimary.opacity(0.9) : accent.opacity(0.75))
                            .frame(width: i == 0 ? 3 : 1.5, height: max(1, g.size.height * level))
                            .position(x: g.size.width * min(0.98, t),
                                      y: g.size.height - max(1, g.size.height * level) / 2)
                    }
                }
            }
            .frame(height: 120)
            .padding(.vertical, 6)
            .background(Theme.inset)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack {
                Text("straight to you").mono(9).foregroundColor(Theme.textPrimary)
                Spacer()
                Text("off one wall").mono(9).foregroundColor(Theme.textDim)
                Spacer()
                Text("off everything").mono(9).foregroundColor(Theme.textDim)
            }

            Text("One straight arrival, then thousands of bounces too close together to count.")
                .mono(9).foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity)
        }
    }
}
