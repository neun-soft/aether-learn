import SwiftUI

// MARK: - Additive build-up (add sine partials one at a time and watch the sum become a saw)

struct AdditiveGraph: View {
    @Binding var count: Int          // 1…WaveTables.maxPartials sine partials
    var accent: Color
    @EnvironmentObject var lang: LangStore
    var height: CGFloat = 190

    private let cycles = 2.0

    // The sum's peak, so the bright line always fills the display height.
    private var sumPeak: Double {
        var peak = 0.0
        for i in 0..<256 {
            let x = Double(i) / 256.0
            peak = max(peak, abs(sum(x)))
        }
        return max(peak, 0.001)
    }
    private func sum(_ x: Double) -> Double {
        (1...count).reduce(0) { $0 + sin(2 * .pi * Double($1) * x) / Double($1) }
    }

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height, mid = h / 2
                let amp = mid - 12
                let norm = sumPeak
                ZStack {
                    Rectangle().fill(Color.black.opacity(0.28))
                    Path { p in p.move(to: CGPoint(x: 0, y: mid)); p.addLine(to: CGPoint(x: w, y: mid)) }
                        .stroke(Theme.hairline(0.10), lineWidth: 1)

                    // Each faint line is one sine partial, at its true relative strength.
                    ForEach(1...count, id: \.self) { k in
                        Path { p in
                            var x: CGFloat = 0
                            var first = true
                            while x <= w {
                                let ph = Double(x / w) * cycles
                                let y = mid - CGFloat(sin(2 * .pi * Double(k) * ph) / Double(k) / norm) * amp
                                if first { p.move(to: CGPoint(x: x, y: y)); first = false }
                                else { p.addLine(to: CGPoint(x: x, y: y)) }
                                x += 3
                            }
                        }
                        .stroke(accent.opacity(0.22), lineWidth: 1.2)
                    }

                    // The bright line is their sum, what the speaker actually plays.
                    Path { p in
                        var x: CGFloat = 0
                        var first = true
                        while x <= w {
                            let ph = Double(x / w) * cycles
                            let y = mid - CGFloat(sum(ph) / norm) * amp
                            if first { p.move(to: CGPoint(x: x, y: y)); first = false }
                            else { p.addLine(to: CGPoint(x: x, y: y)) }
                            x += 2
                        }
                    }
                    .stroke(accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                }
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline(), lineWidth: 1))
            .animation(.easeInOut(duration: 0.25), value: count)

            HStack(spacing: 12) {
                stepButton("minus") { count = max(1, count - 1) }
                VStack(spacing: 1) {
                    Text("\(count)").mono(16, .semibold).foregroundColor(accent)
                    Text(lang.t(count == 1 ? "SINE WAVE" : "SINE WAVES"))
                        .mono(9, .semibold).tracking(1.2).foregroundColor(Theme.textDim)
                }
                .frame(width: 100)
                stepButton("plus") { count = min(WaveTables.maxPartials, count + 1) }
            }
        }
    }

    private func stepButton(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .frame(width: 52, height: 38)
                .background(Theme.inset)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter / EQ graph (harmonic bars with the filter curve cutting them, Ableton-style)

struct FilterGraph: View {
    @Binding var cutoff: Double
    @Binding var resonance: Double
    var filterType: Double
    var spectrum: [Float]            // live FFT of the actual output
    var accent: Color
    @EnvironmentObject var lang: LangStore
    var height: CGFloat = 180
    var interactive: Bool = true

    private let fMin = 40.0, fMax = 18000.0

    private var fc: Double { 60.0 * pow(2.0, cutoff * 8.0) }
    private var mode: Int { Int(min(1, max(0, filterType)) * 3 + 0.5) }

    private func xFor(_ f: Double, _ w: CGFloat) -> CGFloat {
        CGFloat((log(f) - log(fMin)) / (log(fMax) - log(fMin))) * w
    }
    private func yFor(_ g: Double, _ h: CGFloat) -> CGFloat {
        h - CGFloat(min(1.25, g) / 1.25) * (h - 12) - 6
    }

    private func peak(_ f: Double) -> Double {
        let d = log(f / fc)
        return resonance * 1.9 * exp(-(d * d) / (2 * 0.11 * 0.11))
    }
    private func gain(_ f: Double) -> Double {
        let x = f / fc
        switch mode {
        case 1: return min(1.25, pow(x, 2) / sqrt(1 + pow(x, 4)) + peak(f))     // highpass
        case 2:                                                                  // bandpass
            let d = log(x); return min(1.25, exp(-(d * d) / (2 * 0.2 * 0.2)) * (0.7 + resonance))
        case 3:                                                                  // notch
            let d = log(x); return min(1.25, 1 - exp(-(d * d) / (2 * 0.12 * 0.12)) * 0.95)
        default: return min(1.25, 1 / sqrt(1 + pow(x, 4)) + peak(f))            // lowpass
        }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Rectangle().fill(Color.black.opacity(0.28))

                // Live spectrum of the actual output, positioned by frequency.
                ForEach(0..<spectrum.count, id: \.self) { b in
                    let f = Double(SpectrumAnalyzer.barHz[b])
                    Path { p in
                        let x = xFor(f, w)
                        p.move(to: CGPoint(x: x, y: h - 4))
                        p.addLine(to: CGPoint(x: x, y: h - 4 - CGFloat(spectrum[b]) * (h - 20)))
                    }
                    .stroke(accent.opacity(0.55), lineWidth: 3)
                }

                // The filter response curve.
                Path { p in
                    var first = true
                    var x: CGFloat = 0
                    while x <= w {
                        let f = fMin * pow(fMax / fMin, Double(x / w))
                        let y = yFor(gain(f), h)
                        if first { p.move(to: CGPoint(x: x, y: y)); first = false }
                        else { p.addLine(to: CGPoint(x: x, y: y)) }
                        x += 3
                    }
                }
                .stroke(accent, style: StrokeStyle(lineWidth: 2, lineCap: .round))

                // Cutoff handle. The dot sits at a fixed height on the cutoff line so it never
                // rides the resonance peak (which made the curve look kinked).
                let cx = xFor(fc, w)
                Path { p in p.move(to: CGPoint(x: cx, y: 0)); p.addLine(to: CGPoint(x: cx, y: h)) }
                    .stroke(Theme.hairline(0.25), lineWidth: 1)
                Circle().fill(.white).frame(width: 14, height: 14)
                    .position(x: min(w - 7, max(7, cx)), y: yFor(0.72, h))
            }
            .contentShape(Rectangle())
            .highPriorityGesture(interactive ? drag(w, h) : nil)
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline(), lineWidth: 1))
    }

    private func drag(_ w: CGFloat, _ h: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0).onChanged { g in
            let f = fMin * pow(fMax / fMin, Double(max(0, min(1, g.location.x / w))))
            cutoff = min(1, max(0, log2(f / 60.0) / 8.0))
            resonance = min(1, max(0, 1 - Double(g.location.y / h)))
        }
    }
}

// MARK: - Filter-type selector (drawn curve icons, like a synth)

struct FilterTypePicker: View {
    @Binding var value: Double        // 0 LP · 0.34 HP · 0.67 BP · 1 notch
    var accent: Color
    @EnvironmentObject var lang: LangStore
    private let stops: [(String, Double)] = [("Low", 0), ("High", 0.34), ("Band", 0.67), ("Notch", 1)]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(stops, id: \.0) { name, val in
                let on = abs(value - val) < 0.1
                Button { value = val } label: {
                    VStack(spacing: 6) {
                        FilterIcon(kind: name)
                            .stroke(on ? Color.black : Theme.textMuted, lineWidth: 1.6)
                            .frame(height: 18)
                        Text(lang.t(name)).ui(11, on ? .semibold : .regular)
                            .foregroundColor(on ? .black : Theme.textMuted)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 9)
                    .background(on ? accent : Theme.inset)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct FilterIcon: Shape {
    var kind: String
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height, mid = h / 2
        switch kind {
        case "High":
            p.move(to: CGPoint(x: 0, y: h)); p.addLine(to: CGPoint(x: w * 0.55, y: h))
            p.addQuadCurve(to: CGPoint(x: w * 0.75, y: 2), control: CGPoint(x: w * 0.68, y: 2))
            p.addLine(to: CGPoint(x: w, y: 2))
        case "Band":
            p.move(to: CGPoint(x: 0, y: h)); p.addLine(to: CGPoint(x: w * 0.3, y: h))
            p.addQuadCurve(to: CGPoint(x: w * 0.5, y: 2), control: CGPoint(x: w * 0.42, y: 2))
            p.addQuadCurve(to: CGPoint(x: w * 0.7, y: h), control: CGPoint(x: w * 0.58, y: h))
            p.addLine(to: CGPoint(x: w, y: h))
        case "Notch":
            p.move(to: CGPoint(x: 0, y: 2)); p.addLine(to: CGPoint(x: w * 0.4, y: 2))
            p.addLine(to: CGPoint(x: w * 0.5, y: h)); p.addLine(to: CGPoint(x: w * 0.6, y: 2))
            p.addLine(to: CGPoint(x: w, y: 2))
        default: // Low
            p.move(to: CGPoint(x: 0, y: 2)); p.addLine(to: CGPoint(x: w * 0.45, y: 2))
            p.addQuadCurve(to: CGPoint(x: w * 0.65, y: h), control: CGPoint(x: w * 0.58, y: h))
            p.addLine(to: CGPoint(x: w, y: h))
        }
        _ = mid
        return p
    }
}

// MARK: - Envelope editor (DAHDSR shape with a live playhead, Vital-style)

struct EnvelopeGraph: View {
    var delay: Double, attack: Double, hold: Double, decay: Double
    var sustain: Double, release: Double, curve: Double
    var playhead: Double        // seconds since note-on, negative if idle
    var accent: Color
    @EnvironmentObject var lang: LangStore
    var height: CGFloat = 180

    private var dly: Double { delay * 1.0 }
    private var atk: Double { 0.002 + attack * attack * 3 }
    private var hld: Double { hold * 1.5 }
    private var dcy: Double { 0.005 + decay * decay * 3 }
    private var rel: Double { 0.005 + release * release * 4 }
    private let susW = 0.5
    private var total: Double { dly + atk + hld + dcy + susW + rel }

    private func shape(_ x: Double) -> Double {
        let k = 0.02 + curve * 6
        return (exp(k * x) - 1) / (exp(k) - 1)
    }
    // Envelope level at time t (seconds).
    private func level(_ t: Double) -> Double {
        if t < dly { return 0 }
        if t < dly + atk { return shape((t - dly) / atk) }
        if t < dly + atk + hld { return 1 }
        if t < dly + atk + hld + dcy { return 1 - (1 - sustain) * shape((t - dly - atk - hld) / dcy) }
        if t < dly + atk + hld + dcy + susW { return sustain }
        return sustain * (1 - shape((t - dly - atk - hld - dcy - susW) / rel))
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let xF = { (t: Double) in CGFloat(t / total) * w }
            let yF = { (v: Double) in h - CGFloat(v) * (h - 16) - 8 }
            ZStack {
                Rectangle().fill(Color.black.opacity(0.28))

                Path { p in
                    var x: CGFloat = 0
                    var first = true
                    while x <= w {
                        let t = Double(x / w) * total
                        let pt = CGPoint(x: x, y: yF(level(t)))
                        if first { p.move(to: pt); first = false } else { p.addLine(to: pt) }
                        x += 2
                    }
                }
                .stroke(accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                // Fill under the curve.
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h))
                    var x: CGFloat = 0
                    while x <= w { p.addLine(to: CGPoint(x: x, y: yF(level(Double(x / w) * total)))); x += 2 }
                    p.addLine(to: CGPoint(x: w, y: h)); p.closeSubpath()
                }
                .fill(accent.opacity(0.12))

                if playhead >= 0 {
                    let t = min(playhead, dly + atk + hld + dcy + susW)
                    Circle().fill(.white).frame(width: 12, height: 12)
                        .position(x: xF(t), y: yF(level(t)))
                }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline(), lineWidth: 1))
    }
}

// MARK: - LFO display (the looping shape with a moving playhead)

struct LFOGraph: View {
    var rate: Double, shape: Double, depth: Double
    var dest: ModDest
    var accent: Color
    @EnvironmentObject var lang: LangStore
    var height: CGFloat = 150
    private let cycles = 1.0   // one clean iteration, like Vital / Serum

    private func shapeVal(_ phase: Double) -> Double {
        let s = Int(min(1, max(0, shape / 1.0)) * 3 + 0.5) // shape is 0..1 here
        let ph = phase - floor(phase)
        switch s {
        case 1: return 1 - 4 * abs(ph - 0.5)      // triangle
        case 2: return 1 - 2 * ph                 // saw (down)
        case 3: return ph < 0.5 ? 1 : -1          // square
        default: return sin(2 * .pi * ph)         // sine
        }
    }

    var body: some View {
        TimelineView(.animation) { ctx in
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height, mid = h / 2
                let amp = (mid - 10) * CGFloat(depth)
                let rateHz = 0.05 * pow(2.0, rate * 8.6)
                let head = (ctx.date.timeIntervalSince1970 * rateHz / cycles).truncatingRemainder(dividingBy: 1)
                ZStack {
                    Rectangle().fill(Color.black.opacity(0.28))
                    Path { p in p.move(to: CGPoint(x: 0, y: mid)); p.addLine(to: CGPoint(x: w, y: mid)) }
                        .stroke(Theme.hairline(0.10), lineWidth: 1)
                    Path { p in
                        var x: CGFloat = 0
                        var first = true
                        while x <= w {
                            let phase = Double(x / w) * cycles
                            let pt = CGPoint(x: x, y: mid - CGFloat(shapeVal(phase)) * amp)
                            if first { p.move(to: pt); first = false } else { p.addLine(to: pt) }
                            x += 2
                        }
                    }
                    .stroke(accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                    let hx = CGFloat(head) * w
                    Circle().fill(.white).frame(width: 12, height: 12)
                        .position(x: hx, y: mid - CGFloat(shapeVal(head * cycles)) * amp)
                }
                .overlay(alignment: .topLeading) {
                    Text("LFO → \(lang.t(dest.rawValue))").mono(11, .semibold)
                        .foregroundColor(accent).padding(8)
                }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline(), lineWidth: 1))
    }
}
