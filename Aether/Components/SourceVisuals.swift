import SwiftUI

// Visuals built for one lesson each. The rule here is that the picture has to carry the idea on
// its own, before the words: someone who scrolls past the theory and lands on the exercise should
// still be able to work out what is happening by moving the one knob and watching.

// MARK: - Noise: why "white" and why "pink"

/// Two panels. On the left, the light analogy the names come from: white light contains every
/// colour at once, and taking the top off leaves it pink. On the right, the same idea as sound:
/// a bar per frequency band, flat for white and sloping down for pink. The blend follows the
/// Colour knob so the picture moves as it is turned.
struct NoiseColorView: View {
    var color: Double          // 0 white → 1 pink
    var level: Double          // how much noise is in the sound at all
    var accent: Color

    // Rough visible-spectrum hues, low frequency (red) to high (violet), so the light strip and
    // the bar chart read left to right in the same direction.
    private let hues: [Color] = [
        Color(red: 0.93, green: 0.27, blue: 0.24), Color(red: 0.96, green: 0.60, blue: 0.20),
        Color(red: 0.96, green: 0.87, blue: 0.28), Color(red: 0.42, green: 0.82, blue: 0.44),
        Color(red: 0.30, green: 0.66, blue: 0.94), Color(red: 0.47, green: 0.40, blue: 0.88),
        Color(red: 0.65, green: 0.36, blue: 0.85)
    ]

    /// White noise holds every band at the same height. Pink drops the high bands away, which is
    /// what leaves the low, warm end standing — the same thing that makes light look pink.
    private func height(_ i: Int, of n: Int) -> Double {
        let t = Double(i) / Double(max(1, n - 1))
        let white = 1.0
        let pink = pow(1.0 - t, 0.85) * 0.92 + 0.08
        return lerp(white, pink, clamp01(color))
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                panel(title: color < 0.5 ? "WHITE LIGHT" : "PINK LIGHT") {
                    ZStack {
                        // Every colour at once is white. Pull the top of the spectrum down and
                        // what is left over reads as pink.
                        LinearGradient(colors: hues, startPoint: .leading, endPoint: .trailing)
                            .opacity(0.9)
                            .mask(
                                GeometryReader { g in
                                    Path { p in
                                        let n = 60
                                        p.move(to: CGPoint(x: 0, y: g.size.height))
                                        for i in 0...n {
                                            let t = Double(i) / Double(n)
                                            let h = lerp(1.0, pow(1 - t, 0.85) * 0.92 + 0.08, clamp01(color))
                                            p.addLine(to: CGPoint(x: g.size.width * t,
                                                                  y: g.size.height * (1 - h)))
                                        }
                                        p.addLine(to: CGPoint(x: g.size.width, y: g.size.height))
                                        p.closeSubpath()
                                    }
                                }
                            )
                        Text(color < 0.5 ? "all colours,\nequal amounts" : "top taken off,\nwhat is left looks pink")
                            .mono(9).foregroundColor(Theme.textPrimary.opacity(0.85))
                            .multilineTextAlignment(.center)
                    }
                }

                panel(title: color < 0.5 ? "WHITE NOISE" : "PINK NOISE") {
                    GeometryReader { g in
                        let n = 16
                        let w = g.size.width / CGFloat(n)
                        HStack(alignment: .bottom, spacing: 1.5) {
                            ForEach(0..<n, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(accent.opacity(0.35 + 0.5 * height(i, of: n)))
                                    .frame(width: w - 1.5,
                                           height: max(2, g.size.height * height(i, of: n)))
                            }
                        }
                        .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                }
            }
            .frame(height: 132)
            .opacity(0.35 + 0.65 * clamp01(level))

            HStack {
                Text("low").mono(9).foregroundColor(Theme.textDim)
                Spacer()
                Text(level < 0.02 ? "turn NOISE up to hear it" : (color < 0.5 ? "flat: every band equal" : "sloped: less at the top"))
                    .mono(9).foregroundColor(Theme.textMuted)
                Spacer()
                Text("high").mono(9).foregroundColor(Theme.textDim)
            }
        }
    }

    @ViewBuilder private func panel<C: View>(title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(spacing: 6) {
            Text(title).mono(9, .semibold).tracking(1.2).foregroundColor(Theme.textDim)
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.inset)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

// MARK: - FM: the two oscillators, drawn separately

/// Three stacked rows: the modulator, the carrier it would have been, and the result. The point
/// the picture has to make is that the modulator is never heard on its own — it only bends the
/// one below it — so it is drawn dimmed and labelled "you never hear this".
struct FMView: View {
    var amount: Double         // FM depth 0…1
    var ratioIndex: Int        // index into Voice.fmRatios
    var accent: Color

    private var ratio: Double { Voice.fmRatios[min(max(0, ratioIndex), Voice.fmRatios.count - 1)] }
    private var isWhole: Bool { ratio == ratio.rounded() }

    var body: some View {
        VStack(spacing: 8) {
            row(label: "MODULATOR", note: "you never hear this one", dim: true) { t in
                sin(2 * .pi * t * ratio * 2)
            }
            row(label: "CARRIER", note: "the note you play", dim: true) { t in
                sin(2 * .pi * t * 2)
            }
            row(label: "RESULT", note: amount < 0.02 ? "turn FM up" : (isWhole ? "lines up: still a note" : "does not line up: metallic"),
                dim: false) { t in
                // Phase modulation, the same maths the engine uses, so the drawing and the
                // sound cannot drift apart.
                sin(2 * .pi * t * 2 + sin(2 * .pi * t * ratio * 2) * amount * 3)
            }
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
