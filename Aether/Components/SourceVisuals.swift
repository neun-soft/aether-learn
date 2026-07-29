import SwiftUI

// Visuals built for one lesson each. The rule here is that the picture has to carry the idea on
// its own, before the words: someone who scrolls past the theory and lands on the exercise should
// still be able to work out what is happening by moving the one knob and watching.

// MARK: - Noise: what is in it, and where the colour names come from

/// One row of bars: how much of each frequency is present, low on the left, high on the right.
/// The knob tilts that row. Underneath, the two things that row means — what an eye would see if
/// those were frequencies of light, and what an ear hears now that they are frequencies of sound.
///
/// The swatch is *computed* from the bar heights, by adding up the colour of every band weighted
/// by how tall it is. That is the whole reason the panel exists: an earlier version simply
/// asserted that removing the blue end leaves pink, which is a claim a reader has no way to check.
/// Here they can watch it happen.
struct NoiseColorView: View {
    var color: Double          // 0 white → 1 pink
    var level: Double          // how much noise is in the sound at all
    var accent: Color

    private let bands = 18

    /// The colour our eyes assign to each frequency of light, slow (red) to fast (violet).
    private func hue(_ t: Double) -> (r: Double, g: Double, b: Double) {
        // A rough but honest rainbow: enough to make the mixing believable.
        let stops: [(Double, Double, Double)] = [
            (0.95, 0.20, 0.18), (0.98, 0.55, 0.15), (0.98, 0.85, 0.25),
            (0.40, 0.85, 0.40), (0.25, 0.62, 0.95), (0.45, 0.35, 0.90), (0.62, 0.30, 0.85)
        ]
        let x = clamp01(t) * Double(stops.count - 1)
        let i = min(Int(x), stops.count - 2)
        let f = x - Double(i)
        return (lerp(stops[i].0, stops[i+1].0, f),
                lerp(stops[i].1, stops[i+1].1, f),
                lerp(stops[i].2, stops[i+1].2, f))
    }

    /// How much of band `i` is present. Flat when white; tilted away from the high end when pink.
    private func amount(_ i: Int) -> Double {
        let t = Double(i) / Double(bands - 1)
        return lerp(1.0, pow(1.0 - t, 0.9) * 0.92 + 0.08, clamp01(color))
    }

    /// Add every band's colour together, weighted by how much of it there is. All bands equal
    /// gives white; weighted towards the slow end gives pink. Nothing is asserted here.
    private var mixedLight: Color {
        var r = 0.0, g = 0.0, b = 0.0, total = 0.0
        for i in 0..<bands {
            let a = amount(i)
            let c = hue(Double(i) / Double(bands - 1))
            r += c.r * a; g += c.g * a; b += c.b * a; total += a
        }
        guard total > 0 else { return .white }
        // Normalise so the result is a hue rather than a brightness, then lift it towards the
        // top of the range: a mix of every colour reads as white, not as mid grey.
        let peak = max(r, max(g, b)) / total
        return Color(red: min(1, (r / total) / peak), green: min(1, (g / total) / peak),
                     blue: min(1, (b / total) / peak))
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("HOW MUCH OF EACH FREQUENCY").mono(9, .semibold).tracking(1.2)
                    .foregroundColor(Theme.textDim)
                Spacer()
                Text(level < 0.02 ? "turn NOISE up" : (color < 0.5 ? "all equal" : "less at the high end"))
                    .mono(9).foregroundColor(Theme.textMuted)
            }

            // The bars are tinted with the colour that frequency would be, as light. That is the
            // bridge: the same row of frequencies, read two different ways.
            GeometryReader { g in
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(0..<bands, id: \.self) { i in
                        let a = amount(i)
                        let c = hue(Double(i) / Double(bands - 1))
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color(red: c.r, green: c.g, blue: c.b).opacity(0.55 + 0.4 * a))
                            .frame(width: max(2, g.size.width / CGFloat(bands) - 2),
                                   height: max(3, g.size.height * a))
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(height: 96)
            .padding(8)
            .background(Theme.inset)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .opacity(0.4 + 0.6 * clamp01(level))

            HStack {
                Text("slow / low").mono(9).foregroundColor(Theme.textDim)
                Spacer()
                Text("fast / high").mono(9).foregroundColor(Theme.textDim)
            }

            // The same row of bars, read as light and read as sound.
            HStack(spacing: 10) {
                result(title: "AS LIGHT, AN EYE SEES") {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous).fill(mixedLight)
                        Text(color < 0.4 ? "white" : (color < 0.7 ? "warm white" : "pink"))
                            .mono(11, .semibold).foregroundColor(.black.opacity(0.7))
                    }
                }
                result(title: "AS SOUND, AN EAR HEARS") {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(accent.opacity(0.16))
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(accent.opacity(0.5), lineWidth: 1)
                        Text(color < 0.4 ? "hiss" : (color < 0.7 ? "softer hiss" : "rain, wind"))
                            .mono(11, .semibold).foregroundColor(Theme.textPrimary)
                    }
                }
            }
            .frame(height: 52)

            Text("Same bars, two senses. Every frequency equally is what we call white.")
                .mono(9).foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder private func result<C: View>(title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(spacing: 5) {
            Text(title).mono(8, .semibold).tracking(1).foregroundColor(Theme.textDim)
            content().frame(maxWidth: .infinity, maxHeight: .infinity)
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
                note: amount < 0.02 ? "turn FM up" : (isWhole ? "repeats: still a note" : "never repeats: metal"),
                dim: false) { t in
                // The same phase-modulation maths the engine uses, so the drawing and the sound
                // can never disagree.
                sin(2 * .pi * t * cycles + sin(2 * .pi * t * ratio * cycles) * amount * 3)
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
            .frame(height: 96)
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
