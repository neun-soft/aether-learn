import SwiftUI

// Visuals built for one lesson each. The rule here is that the picture has to carry the idea on
// its own, before the words: someone who scrolls past the theory and lands on the exercise should
// still be able to work out what is happening by moving the one knob and watching.

// MARK: - Noise: the values themselves, and what tilting them does

/// Two rows, and neither of them uses colour to make its point.
///
/// The top row is the sound itself: one dot per value, newest on the right, scrolling left. That
/// is the whole definition of noise made visible — a brand new random number every instant, with
/// nothing coming back around. Move COLOUR and the dots change *behaviour*: white ignores the
/// value before it and scatters over the full height, pink stays near the value before it and
/// wanders. Slow wandering is exactly what "more low than high" looks like in time.
///
/// The bottom row is the same sound counted up by frequency. Flat when white, tilted down at the
/// high end when pink. The pink/white names come from light, which is why the theory explains
/// them — but the exercise has no reason to be coloured, so it isn't.
struct NoiseColorView: View {
    var color: Double          // 0 white → 1 pink
    var level: Double          // how much noise is in the sound at all
    var accent: Color

    private let bands = 18
    private let dots = 96

    @State private var samples: [Double] = []
    @State private var carry: Double = 0
    @State private var lastTick: Date?
    // The same xorshift the engine uses, so the picture is generated the way the sound is.
    @State private var rng: UInt32 = 0x9E37_79B9
    @State private var p0 = 0.0
    @State private var p1 = 0.0
    @State private var p2 = 0.0

    private func white() -> Double {
        rng ^= rng << 13; rng ^= rng >> 17; rng ^= rng << 5
        return Double(Int32(bitPattern: rng)) / Double(Int32.max)
    }

    /// The same tilt as `Noise.render` — three stacked one-poles summed — but with the poles moved
    /// to this picture's own rate. The engine's coefficients are tuned for 44,100 values a second;
    /// at the three dozen a second drawn here they would leave the wander far below the window and
    /// the two settings would look identical. Each pole is normalised so the result keeps its
    /// height and only its *behaviour* changes, which is the thing being taught.
    private func next() -> Double {
        let w = white()
        p0 = 0.985 * p0 + w * 0.1725 * 1.00
        p1 = 0.900 * p1 + w * 0.4359 * 0.75
        p2 = 0.550 * p2 + w * 0.8352 * 0.55
        let pink = (p0 + p1 + p2) * 0.62
        return max(-1, min(1, lerp(w, pink, clamp01(color))))
    }

    private func advance(to now: Date) {
        let dt = min(lastTick.map { now.timeIntervalSince($0) } ?? 0, 1.0 / 20)
        lastTick = now
        // A fixed rate, slow enough to read a single dot and fast enough to look alive.
        carry += dt * 34
        let n = min(Int(carry), dots)
        guard n > 0 else { return }
        carry -= Double(n)
        var next = samples
        if next.count < dots { next = [Double](repeating: 0, count: dots) }
        next.removeFirst(n)
        for _ in 0..<n { next.append(self.next()) }
        samples = next
    }

    /// How much of band `i` is present. Flat when white; tilted away from the high end when pink.
    private func amount(_ i: Int) -> Double {
        let t = Double(i) / Double(bands - 1)
        return lerp(1.0, pow(1.0 - t, 0.9) * 0.92 + 0.08, clamp01(color))
    }

    private var behaviour: String {
        if level < 0.02 { return "turn NOISE up" }
        return color < 0.35 ? "every dot ignores the one before it"
                            : (color < 0.7 ? "starting to hold on to the last one" : "every dot stays near the one before it")
    }

    var body: some View {
        VStack(spacing: 9) {
            HStack {
                Text("EVERY INSTANT, A NEW VALUE").mono(9, .semibold).tracking(1.2)
                    .foregroundColor(Theme.textDim)
                Spacer()
                Text(behaviour).mono(9).foregroundColor(Theme.textMuted)
            }

            TimelineView(.animation) { ctx in
                GeometryReader { g in
                    let w = g.size.width, h = g.size.height, mid = h / 2
                    let amp = mid - 6
                    let step = w / CGFloat(max(dots - 1, 1))
                    ZStack {
                        Rectangle().fill(Theme.plot)
                        Path { p in p.move(to: CGPoint(x: 0, y: mid)); p.addLine(to: CGPoint(x: w, y: mid)) }
                            .stroke(Theme.hairline(0.10), lineWidth: 1)

                        // The thread between the dots. It is a scribble when white and a slow
                        // wander when pink, which is the difference stated without a single word.
                        Path { p in
                            for (i, v) in samples.enumerated() {
                                let pt = CGPoint(x: CGFloat(i) * step, y: mid - CGFloat(v) * amp)
                                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                            }
                        }
                        .stroke(accent.opacity(0.22), lineWidth: 1)

                        // The values themselves.
                        Path { p in
                            for (i, v) in samples.enumerated() {
                                let pt = CGPoint(x: CGFloat(i) * step, y: mid - CGFloat(v) * amp)
                                p.addEllipse(in: CGRect(x: pt.x - 1.6, y: pt.y - 1.6, width: 3.2, height: 3.2))
                            }
                        }
                        .fill(accent.opacity(0.9))
                    }
                    .onChange(of: ctx.date) { _, now in advance(to: now) }
                }
            }
            .frame(height: 92)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .opacity(0.35 + 0.65 * clamp01(level))

            HStack {
                Text("older").mono(9).foregroundColor(Theme.textDim)
                Spacer()
                Text("no shape ever repeats").mono(9).foregroundColor(Theme.textMuted)
                Spacer()
                Text("now").mono(9).foregroundColor(Theme.textDim)
            }

            HStack {
                Text("HOW MUCH OF EACH FREQUENCY").mono(9, .semibold).tracking(1.2)
                    .foregroundColor(Theme.textDim)
                Spacer()
                Text(color < 0.5 ? "all equal — white" : "high end turned down — pink")
                    .mono(9).foregroundColor(Theme.textMuted)
            }

            GeometryReader { g in
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(0..<bands, id: \.self) { i in
                        let a = amount(i)
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(accent.opacity(0.30 + 0.55 * a))
                            .frame(width: max(2, g.size.width / CGFloat(bands) - 2),
                                   height: max(3, g.size.height * a))
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(height: 52)
            .padding(8)
            .background(Theme.inset)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .opacity(0.4 + 0.6 * clamp01(level))

            HStack {
                Text("slow / low").mono(9).foregroundColor(Theme.textDim)
                Spacer()
                Text(color < 0.4 ? "hiss" : (color < 0.7 ? "softer hiss" : "rain, wind"))
                    .mono(9, .semibold).foregroundColor(Theme.textPrimary)
                Spacer()
                Text("fast / high").mono(9).foregroundColor(Theme.textDim)
            }
        }
        .onAppear {
            if samples.count < dots {
                samples = [Double](repeating: 0, count: dots)
                for i in 0..<dots { samples[i] = next() }
            }
        }
    }
}

// MARK: - FM: the two oscillators, drawn separately

/// Three stacked rows: the modulator, the carrier it would have been, and the result. The point
/// the picture has to make is that the modulator is a real wave at ordinary note speed, and the
/// only reason it is inaudible is that it is used to move something instead of being played. It is
/// drawn dimmed and labelled accordingly.
struct FMView: View {
    var amount: Double         // FM depth 0…1
    var ratioIndex: Int        // index into Voice.fmRatios
    var accent: Color

    private var ratio: Double { Voice.fmRatios[min(max(0, ratioIndex), Voice.fmRatios.count - 1)] }
    private var isWhole: Bool { ratio == ratio.rounded() }
    /// Two cycles of the carrier, no more. At ratio 7 an earlier version drew fourteen cycles of
    /// modulator into the same width, which looked like noise even when the result was a clean
    /// repeating wave — the picture contradicted its own caption.
    private let cycles = 2.0

    var body: some View {
        VStack(spacing: 8) {
            row(label: "MODULATOR", note: "never sent to the speakers", dim: true) { t in
                sin(2 * .pi * t * ratio * cycles)
            }
            row(label: "CARRIER", note: "the note you play", dim: true) { t in
                sin(2 * .pi * t * cycles)
            }
            row(label: "RESULT",
                note: amount < 0.02 ? "turn FM up" : (isWhole ? "repeats: rings" : "never repeats: clangs"),
                dim: false) { t in
                // The same phase-modulation maths the engine uses, so the drawing and the sound
                // can never disagree.
                sin(2 * .pi * t * cycles + sin(2 * .pi * t * ratio * cycles) * Voice.fmIndex(amount))
            }

            Text(amount < 0.02
                 ? "FM adds the top wave onto the middle one\'s speed. At zero it adds nothing."
                 : "The taller the top wave, the more the bottom one speeds up and slows down.")
                .mono(9).foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder private func row(label: String, note: String, dim: Bool,
                                  _ f: @escaping (Double) -> Double) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label).mono(9, .semibold).tracking(1.2)
                    .foregroundColor(dim ? Theme.textDim : accent)
                Spacer()
                Text(note).mono(9).foregroundColor(Theme.textDim)
            }
            GeometryReader { g in
                Path { p in
                    let n = 180
                    for i in 0...n {
                        let t = Double(i) / Double(n)
                        let y = g.size.height * (0.5 - f(t) * 0.42)
                        let pt = CGPoint(x: g.size.width * t, y: y)
                        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                    }
                }
                .stroke(dim ? Theme.textDim.opacity(0.55) : accent,
                        style: StrokeStyle(lineWidth: dim ? 1.2 : 2, lineCap: .round, lineJoin: .round))
            }
            .frame(height: dim ? 34 : 52)
            .background(Theme.inset)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

// MARK: - Hard sync: the master cutting the slave off

/// The slave wave with a vertical line every time the master restarts it. What the picture has
/// to show is that the cut always lands in the same places no matter how fast the slave runs,
/// which is why the pitch never changes while the tone does.
struct SyncView: View {
    var amount: Double         // 0…1, how far the slave is tuned above the master
    var accent: Color

    private var slaveMultiple: Double { 1 + amount * 7 }
    private let masterCycles = 3.0

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("MASTER").mono(9, .semibold).tracking(1.2).foregroundColor(Theme.textDim)
                Spacer()
                Text("silent, only keeps time").mono(9).foregroundColor(Theme.textDim)
            }

            // Master: drawn as tick marks, because it is never heard.
            GeometryReader { g in
                ForEach(0...Int(masterCycles), id: \.self) { i in
                    let x = g.size.width * (Double(i) / masterCycles)
                    Path { p in
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: g.size.height))
                    }
                    .stroke(Theme.textDim.opacity(0.8), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
            }
            .frame(height: 16)

            HStack {
                Text("SLAVE").mono(9, .semibold).tracking(1.2).foregroundColor(accent)
                Spacer()
                Text(amount < 0.02 ? "turn SYNC up" : "cut off and restarted at every tick")
                    .mono(9).foregroundColor(Theme.textDim)
            }

            GeometryReader { g in
                ZStack {
                    // The slave, restarted at each master tick. Drawing it as one path per
                    // master cycle is exactly what the engine does to it.
                    ForEach(0..<Int(masterCycles), id: \.self) { c in
                        let x0 = g.size.width * (Double(c) / masterCycles)
                        let w = g.size.width / masterCycles
                        Path { p in
                            let n = 90
                            for i in 0...n {
                                let local = Double(i) / Double(n)
                                let y = g.size.height * (0.5 - sin(2 * .pi * local * slaveMultiple) * 0.42)
                                let pt = CGPoint(x: x0 + w * local, y: y)
                                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                            }
                        }
                        .stroke(accent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    }
                    // The tear: a hard vertical drop back to the start at every tick.
                    ForEach(1..<Int(masterCycles), id: \.self) { c in
                        let x = g.size.width * (Double(c) / masterCycles)
                        Path { p in
                            p.move(to: CGPoint(x: x, y: g.size.height * 0.08))
                            p.addLine(to: CGPoint(x: x, y: g.size.height * 0.92))
                        }
                        .stroke(Theme.textPrimary.opacity(0.5), lineWidth: 1)
                    }
                }
            }
            // Shorter than it wants to be, so the spectrum underneath the knob is on the same
            // screen as the knob. The tearing reads fine at this height; a claim you have to
            // scroll to check is a claim most people will not check.
            .frame(height: 72)
            .background(Theme.inset)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text("The cuts never move. That is why the note stays put.")
                .mono(9).foregroundColor(Theme.textMuted)
        }
    }
}

// MARK: - Drive: the shape that does the squashing

/// Left: the transfer curve, with the flat ceiling drawn in. Right: a sine going in and the
/// squashed version coming out, drawn over each other so the flattening is the thing you see.
struct DriveView: View {
    var drive: Double
    var accent: Color

    private func shaped(_ x: Double) -> Double { tanh(x * (1 + drive * 5)) }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("WHAT DRIVE DOES TO THE SHAPE").mono(9, .semibold).tracking(1.2)
                    .foregroundColor(Theme.textDim)
                Spacer()
                Text(drive < 0.02 ? "round" : (drive < 0.5 ? "corners rounding off" : "nearly a square"))
                    .mono(9).foregroundColor(Theme.textMuted)
            }

            GeometryReader { g in
                ZStack {
                    // The ceiling the signal cannot pass.
                    ForEach([0.12, 0.88], id: \.self) { yf in
                        Path { p in
                            p.move(to: CGPoint(x: 0, y: g.size.height * yf))
                            p.addLine(to: CGPoint(x: g.size.width, y: g.size.height * yf))
                        }
                        .stroke(Theme.textDim.opacity(0.55), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }

                    // The original, for comparison.
                    wave(in: g) { sin(2 * .pi * $0 * 2) * 0.78 }
                        .stroke(Theme.textDim.opacity(0.5), lineWidth: 1.2)

                    // The driven version.
                    wave(in: g) { shaped(sin(2 * .pi * $0 * 2)) * 0.78 }
                        .stroke(accent, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                }
            }
            .frame(height: 150)
            .background(Theme.inset)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack(spacing: 14) {
                legend(color: Theme.textDim.opacity(0.6), label: "before")
                legend(color: accent, label: "after drive")
                Spacer()
                Text("dotted line = the ceiling").mono(9).foregroundColor(Theme.textDim)
            }
        }
    }

    private func wave(in g: GeometryProxy, _ f: (Double) -> Double) -> Path {
        Path { p in
            let n = 200
            for i in 0...n {
                let t = Double(i) / Double(n)
                let pt = CGPoint(x: g.size.width * t, y: g.size.height * (0.5 - f(t) * 0.5))
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
        }
    }

    private func legend(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 1).fill(color).frame(width: 14, height: 2.5)
            Text(label).mono(9).foregroundColor(Theme.textDim)
        }
    }
}
