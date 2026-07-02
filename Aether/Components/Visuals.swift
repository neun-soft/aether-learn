import SwiftUI

// Amplitude of harmonic k for a given wave-shape morph (sine → tri → saw → square).
func harmonicAmplitude(_ morph: Double, _ k: Int) -> Double {
    func table(_ idx: Int) -> Double {
        switch idx {
        case 0: return k == 1 ? 1 : 0                       // sine
        case 1: return k % 2 == 1 ? 1.0 / Double(k * k) : 0 // triangle
        case 2: return 1.0 / Double(k)                      // saw
        default: return k % 2 == 1 ? 1.0 / Double(k) : 0    // square
        }
    }
    let m = min(1, max(0, morph)) * 3
    let i0 = Int(m), i1 = min(i0 + 1, 3), f = m - Double(i0)
    return table(i0) * (1 - f) + table(i1) * f
}

// MARK: - Live waveform scope (draws the actual audio output)

struct WaveScope: View {
    var samples: [Float]
    var accent: Color
    @EnvironmentObject var lang: LangStore
    var height: CGFloat = 150

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Rectangle().fill(Color.black.opacity(0.25))
                Path { p in p.move(to: CGPoint(x: 0, y: h / 2)); p.addLine(to: CGPoint(x: w, y: h / 2)) }
                    .stroke(Theme.hairline(0.10), lineWidth: 1)
                Path { p in
                    let n = samples.count
                    guard n > 16 else { return }
                    // Trigger on a rising zero crossing so the wave looks stable frame to frame.
                    var start = 0
                    for i in 1..<(n / 2) where samples[i - 1] <= 0 && samples[i] > 0 { start = i; break }
                    let count = n - start
                    guard count > 1 else { return }
                    for i in 0..<count {
                        let s = CGFloat(max(-1, min(1, samples[start + i])))
                        let x = w * CGFloat(i) / CGFloat(count - 1)
                        let y = h / 2 - s * (h / 2 - 6)
                        if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(accent, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline(), lineWidth: 1))
        .overlay(alignment: .topLeading) {
            Text(lang.t("cone: push ↕ pull")).mono(8).foregroundColor(Theme.textFaint).padding(7)
        }
        .overlay(alignment: .bottomTrailing) {
            Text(lang.t("time →")).mono(8).foregroundColor(Theme.textFaint).padding(7)
        }
    }
}

// MARK: - Beat scope (output loudness over time, so slow beating is visible)

struct BeatScope: View {
    var history: [Float]
    var accent: Color
    @EnvironmentObject var lang: LangStore
    var height: CGFloat = 96

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Rectangle().fill(Color.black.opacity(0.25))
                Path { p in
                    let n = history.count
                    guard n > 1 else { return }
                    p.move(to: CGPoint(x: 0, y: h))
                    for i in 0..<n {
                        let x = w * CGFloat(i) / CGFloat(n - 1)
                        let y = h - CGFloat(max(0, min(1, history[i]))) * (h - 8)
                        p.addLine(to: CGPoint(x: x, y: y))
                    }
                    p.addLine(to: CGPoint(x: w, y: h)); p.closeSubpath()
                }
                .fill(accent.opacity(0.18))
                Path { p in
                    let n = history.count
                    guard n > 1 else { return }
                    for i in 0..<n {
                        let x = w * CGFloat(i) / CGFloat(n - 1)
                        let y = h - CGFloat(max(0, min(1, history[i]))) * (h - 8)
                        if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(accent, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline(), lineWidth: 1))
        .overlay(alignment: .topLeading) {
            Text(lang.t("loudness ↕")).mono(8).foregroundColor(Theme.textFaint).padding(7)
        }
        .overlay(alignment: .bottomTrailing) {
            Text(lang.t("time →")).mono(8).foregroundColor(Theme.textFaint).padding(7)
        }
    }
}

// MARK: - Harmonic spectrum (bars derived from the waveform shape)

struct HarmonicBars: View {
    var morph: Double
    var accent: Color
    @EnvironmentObject var lang: LangStore
    var height: CGFloat = 150
    private let count = 16

    private func amp(_ k: Int) -> Double { harmonicAmplitude(morph, k) }

    var body: some View {
        GeometryReader { geo in
            let slot: CGFloat = geo.size.width / CGFloat(count)
            ZStack {
                Rectangle().fill(Color.black.opacity(0.25))
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(0..<count, id: \.self) { i in
                        bar(index: i, slot: slot, fullHeight: geo.size.height)
                    }
                }
                .padding(.bottom, 6)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline(), lineWidth: 1))
        .overlay(alignment: .topLeading) {
            Text(lang.t("strength ↕")).mono(8).foregroundColor(Theme.textFaint).padding(7)
        }
        .overlay(alignment: .bottom) {
            HStack {
                Text(lang.t("fundamental")).mono(8).foregroundColor(Theme.textFaint)
                Spacer()
                Text(lang.t("higher harmonics →")).mono(8).foregroundColor(Theme.textFaint)
            }
            .padding(.horizontal, 8).padding(.bottom, 5)
        }
    }

    private func bar(index i: Int, slot: CGFloat, fullHeight: CGFloat) -> some View {
        let a = amp(i + 1)
        let barHeight = max(1.0, CGFloat(a) * (fullHeight - 12))
        return RoundedRectangle(cornerRadius: 2)
            .fill(accent.opacity(0.35 + 0.6 * a))
            .frame(width: slot * 0.55, height: barHeight)
            .frame(width: slot, alignment: .bottom)
    }
}

// MARK: - Live spectrum bars (real FFT of the actual output)

struct SpectrumBars: View {
    var spectrum: [Float]
    var accent: Color
    @EnvironmentObject var lang: LangStore
    var height: CGFloat = 150

    var body: some View {
        GeometryReader { geo in
            let n = max(1, spectrum.count)
            let slot = geo.size.width / CGFloat(n)
            ZStack {
                Rectangle().fill(Color.black.opacity(0.25))
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(0..<spectrum.count, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(accent.opacity(0.35 + 0.6 * Double(spectrum[i])))
                            .frame(width: slot * 0.72,
                                   height: max(1, CGFloat(spectrum[i]) * (geo.size.height - 14)))
                            .frame(width: slot, alignment: .bottom)
                    }
                }
                .padding(.bottom, 7).frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline(), lineWidth: 1))
        .overlay(alignment: .topLeading) {
            Text(lang.t("strength ↕")).mono(8).foregroundColor(Theme.textFaint).padding(7)
        }
        .overlay(alignment: .bottom) {
            HStack {
                Text(lang.t("low")).mono(8).foregroundColor(Theme.textFaint)
                Spacer()
                Text(lang.t("frequency →")).mono(8).foregroundColor(Theme.textFaint)
            }
            .padding(.horizontal, 8).padding(.bottom, 5)
        }
    }
}

// MARK: - Wave-shape presets (draw the actual shape)

struct WavePresets: View {
    @Binding var morph: Double
    var accent: Color
    @EnvironmentObject var lang: LangStore
    private let stops: [(String, Double)] = [("Sine", 0), ("Tri", 0.34), ("Saw", 0.66), ("Square", 1)]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(stops, id: \.0) { name, val in
                let on = abs(morph - val) < 0.08
                Button { morph = val } label: {
                    VStack(spacing: 6) {
                        MiniWave(kind: name)
                            .stroke(on ? Color.black : Theme.textMuted, lineWidth: 1.6)
                            .frame(height: 20)
                        Text(lang.t(name)).ui(11, on ? .semibold : .regular)
                            .foregroundColor(on ? .black : Theme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(on ? accent : Theme.inset)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct MiniWave: Shape {
    var kind: String
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height, mid = h / 2
        switch kind {
        case "Tri":
            p.move(to: CGPoint(x: 0, y: mid))
            p.addLine(to: CGPoint(x: w * 0.25, y: 2)); p.addLine(to: CGPoint(x: w * 0.75, y: h - 2))
            p.addLine(to: CGPoint(x: w, y: mid))
        case "Saw":
            p.move(to: CGPoint(x: 0, y: h - 2)); p.addLine(to: CGPoint(x: w * 0.5, y: 2))
            p.addLine(to: CGPoint(x: w * 0.5, y: h - 2)); p.addLine(to: CGPoint(x: w, y: 2))
        case "Square":
            p.move(to: CGPoint(x: 0, y: h - 2)); p.addLine(to: CGPoint(x: 0, y: 2))
            p.addLine(to: CGPoint(x: w * 0.5, y: 2)); p.addLine(to: CGPoint(x: w * 0.5, y: h - 2))
            p.addLine(to: CGPoint(x: w, y: h - 2)); p.addLine(to: CGPoint(x: w, y: 2))
        default: // Sine
            p.move(to: CGPoint(x: 0, y: mid))
            for x in stride(from: 0.0, through: 1.0, by: 0.05) {
                p.addLine(to: CGPoint(x: w * x, y: mid - sin(x * 2 * .pi) * (mid - 2)))
            }
        }
        return p
    }
}

// MARK: - Frequency explorer (sweep a raw frequency, see and hear it become a note)

struct FrequencyExplorer: View {
    @Binding var norm: Double
    let minHz: Double
    let maxHz: Double
    let snap: Bool
    let toneOn: Bool
    let scope: [Float]
    let accent: Color
    let onHz: (Double) -> Void
    let onToggle: () -> Void
    @EnvironmentObject var lang: LangStore

    @State private var scaleSnap = false   // false = nearest of all 12 notes, true = C major scale

    private var rawHz: Double { minHz * pow(maxHz / minHz, norm) }
    private var snappedMidi: Int? {
        guard snap else { return nil }
        let raw = 69.0 + 12.0 * log2(rawHz / 440.0)
        if !scaleSnap { return Int(raw.rounded()) }
        let scale = [0, 2, 4, 5, 7, 9, 11]   // C major
        let m = Int(raw.rounded())
        var best = m, bestDist = 999.0
        for cand in (m - 7)...(m + 7) where scale.contains(((cand % 12) + 12) % 12) {
            let d = abs(Double(cand) - raw)
            if d < bestDist { bestDist = d; best = cand }
        }
        return best
    }
    private var hz: Double {
        guard let m = snappedMidi else { return rawHz }
        return 440.0 * pow(2.0, (Double(m) - 69.0) / 12.0)
    }
    private var noteName: String {
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let midi = Int((69.0 + 12.0 * log2(hz / 440.0)).rounded())
        return names[((midi % 12) + 12) % 12] + "\(midi / 12 - 1)"
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text("\(Int(hz.rounded()))").mono(34, .semibold).foregroundColor(Theme.textPrimary)
                Text("Hz").mono(14).foregroundColor(Theme.textDim)
                Spacer()
                if snap {
                    Text(noteName).ui(26, .semibold).foregroundColor(accent)
                }
            }

            if snap {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        modeButton("C major scale", true)
                        modeButton("All notes", false)
                    }
                    Text(lang.t(scaleSnap
                         ? "Only the seven notes of the C major scale. These are the white keys, a do-re-mi run."
                         : "The nearest of all twelve notes, including the sharps and flats in between."))
                        .ui(11).foregroundColor(Theme.textFaint)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            WaveScope(samples: scope, accent: accent, height: 120)

            slider

            Button(action: onToggle) {
                HStack(spacing: 8) {
                    Image(systemName: toneOn ? "stop.fill" : "play.fill")
                    Text(lang.t(toneOn ? "Stop tone" : "Play tone"))
                }
                .font(AppFont.ui(15, .semibold)).foregroundColor(.black)
                .frame(maxWidth: .infinity).padding(.vertical, 13)
                .background(accent).clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    private func modeButton(_ title: String, _ isScale: Bool) -> some View {
        let on = scaleSnap == isScale
        return Button {
            scaleSnap = isScale
            onHz(hz)
        } label: {
            Text(lang.t(title))
                .ui(12, on ? .semibold : .regular)
                .foregroundColor(on ? .black : Theme.textMuted)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(on ? accent : Theme.inset)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var slider: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.hairline(0.10)).frame(height: 6)
                Capsule().fill(accent).frame(width: max(0, w * norm), height: 6)
                Circle().fill(.white).frame(width: 22, height: 22)
                    .offset(x: max(0, min(w - 22, w * norm - 11)))
            }
            .frame(height: 22)
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        norm = min(1, max(0, g.location.x / w))
                        onHz(hz)
                    }
            )
        }
        .frame(height: 22)
    }
}
