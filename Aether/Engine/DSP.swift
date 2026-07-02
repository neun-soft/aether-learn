import Foundation

// MARK: - Utility

@inline(__always) func midiToHz(_ midi: Double) -> Double { 440.0 * pow(2.0, (midi - 69.0) / 12.0) }
@inline(__always) func clamp01(_ v: Double) -> Double { min(1, max(0, v)) }
@inline(__always) func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }
@inline(__always) func flush(_ x: Double) -> Double { abs(x) < 1e-15 ? 0 : x }

// MARK: - Bandlimited wavetables (sine → triangle → saw → square)

enum WaveTables {
    static let size = 2048
    static let mask = size - 1
    private static let harmonics = 24

    private static func build(_ amp: (Int) -> Double) -> [Double] {
        var t = [Double](repeating: 0, count: size)
        for k in 1...harmonics {
            let a = amp(k)
            if a == 0 { continue }
            let w = 2.0 * .pi * Double(k) / Double(size)
            for i in 0..<size { t[i] += a * sin(w * Double(i)) }
        }
        let peak = t.map { abs($0) }.max() ?? 1
        return peak > 0 ? t.map { $0 / peak } : t
    }

    static let sine     = build { $0 == 1 ? 1 : 0 }
    static let triangle = build { k in k % 2 == 1 ? (k % 4 == 1 ? 1.0 : -1.0) / Double(k * k) : 0 }
    static let saw      = build { 1.0 / Double($0) }
    static let square   = build { k in k % 2 == 1 ? 1.0 / Double(k) : 0 }

    // Ordered by brightness; morph blends adjacent tables.
    static let ramp: [[Double]] = [sine, triangle, saw, square]

    // Partial-sum saws for the additive lesson: n = 1 is a pure sine, n = 8 is close to a saw.
    static let maxPartials = 8
    static let partialSaws: [[Double]] = (1...maxPartials).map { n in
        build { k in k <= n ? 1.0 / Double(k) : 0 }
    }
    @inline(__always) static func partialSaw(_ n: Int) -> [Double] {
        partialSaws[max(1, min(maxPartials, n)) - 1]
    }

    @inline(__always) static func sample(morph: Double, phase: Double) -> Double {
        let m = clamp01(morph) * Double(ramp.count - 1)
        let i0 = Int(m)
        let i1 = min(i0 + 1, ramp.count - 1)
        let frac = m - Double(i0)
        let p = phase * Double(size)
        let idx = Int(p) & mask
        let nxt = (idx + 1) & mask
        let f = p - Double(Int(p))
        let a = lerp(ramp[i0][idx], ramp[i0][nxt], f)
        let b = lerp(ramp[i1][idx], ramp[i1][nxt], f)
        return lerp(a, b, frac)
    }
}

// MARK: - Wavetable oscillator

final class Oscillator {
    private var phase = 0.0
    let sampleRate: Double
    init(sampleRate: Double) { self.sampleRate = sampleRate }

    func reset() { phase = 0 }

    @inline(__always) func render(hz: Double, morph: Double, pulse: Double) -> Double {
        phase += hz / sampleRate
        if phase >= 1 { phase -= 1 }
        var s = WaveTables.sample(morph: morph, phase: phase)
        // Pulse-width shaping only bites near the square end, where it is musically meaningful.
        if morph > 0.66 {
            let pw = 0.5 + (pulse - 0.5) * 0.9
            let second = WaveTables.sample(morph: morph, phase: fmod(phase + pw, 1.0))
            s = (s - second) * 0.7
        }
        return s
    }

    // Play one fixed table directly (the additive lesson's partial-sum saws).
    @inline(__always) func render(hz: Double, table: [Double]) -> Double {
        phase += hz / sampleRate
        if phase >= 1 { phase -= 1 }
        let p = phase * Double(WaveTables.size)
        let idx = Int(p) & WaveTables.mask
        let nxt = (idx + 1) & WaveTables.mask
        return lerp(table[idx], table[nxt], p - Double(Int(p)))
    }
}

// MARK: - State-variable multimode filter

enum FilterMode: Int { case lowpass, highpass, bandpass, notch }

final class SVFilter {
    private var low = 0.0, band = 0.0
    let sampleRate: Double
    init(sampleRate: Double) { self.sampleRate = sampleRate }

    func reset() { low = 0; band = 0 }

    @inline(__always) func process(_ x: Double, cutoffHz: Double, res: Double, mode: FilterMode) -> Double {
        // The Chamberlin SVF is only stable while the coefficient stays below ~1, which caps the
        // usable cutoff near fs/6. Clamp f (and guard the state) so bright cutoffs can't blow up.
        let f = min(0.98, 2.0 * sin(.pi * min(cutoffHz, sampleRate * 0.24) / sampleRate))
        let q = max(0.035, 1.0 - res * 0.985)      // lower q value = more resonance
        let high = x - low - q * band
        band += f * high
        low += f * band
        if !low.isFinite || !band.isFinite { low = 0; band = 0 }
        band = flush(max(-3, min(3, band))); low = flush(max(-3, min(3, low)))
        switch mode {
        case .lowpass:  return low
        case .highpass: return high
        case .bandpass: return band
        case .notch:    return low + high
        }
    }
}

// MARK: - DAHDSR envelope (with per-segment curve, usable as a modulation source)

final class Envelope {
    enum Stage { case idle, delay, attack, hold, decay, sustain, release }
    private(set) var stage: Stage = .idle
    private(set) var value = 0.0
    private var t = 0.0                 // seconds elapsed in the current timed stage

    let sampleRate: Double
    private let dt: Double
    var delay = 0.0, attack = 0.005, hold = 0.0, decay = 0.3
    var sustain = 0.7, release = 0.3, curve = 0.6
    private var releaseFrom = 0.0

    init(sampleRate: Double) { self.sampleRate = sampleRate; dt = 1.0 / sampleRate }

    var isActive: Bool { stage != .idle }

    func gateOn()  { stage = delay > 0 ? .delay : .attack; t = 0 }
    func gateOff() { if stage != .idle { stage = .release; t = 0; releaseFrom = value } }
    func reset()   { stage = .idle; value = 0; t = 0 }

    // curve shaping: 0 → linear, 1 → strongly exponential
    @inline(__always) private func shape(_ x: Double) -> Double {
        let k = 0.02 + curve * 6.0
        return (exp(k * x) - 1) / (exp(k) - 1)
    }

    @inline(__always) func process() -> Double {
        switch stage {
        case .idle:
            return 0
        case .delay:
            t += dt
            value = 0
            if t >= delay { stage = .attack; t = 0 }
        case .attack:
            t += dt
            let p = attack <= 0 ? 1 : min(1, t / attack)
            value = shape(p)
            if p >= 1 { value = 1; stage = hold > 0 ? .hold : .decay; t = 0 }
        case .hold:
            t += dt
            value = 1
            if t >= hold { stage = .decay; t = 0 }
        case .decay:
            t += dt
            let p = decay <= 0 ? 1 : min(1, t / decay)
            value = lerp(1.0, sustain, shape(p))
            if p >= 1 { value = sustain; stage = .sustain }
        case .sustain:
            value = sustain
        case .release:
            t += dt
            let p = release <= 0 ? 1 : min(1, t / release)
            value = releaseFrom * (1 - shape(p))
            if p >= 1 { value = 0; stage = .idle }
        }
        return value
    }
}

// MARK: - Kick drum (pitch drop + fast decay) for the gear-limits lesson

final class KickSynth {
    let sr: Double
    private var t = 0.0
    private var phase = 0.0
    private var active = false
    init(sampleRate: Double) { sr = sampleRate }

    func trigger() { t = 0; phase = 0; active = true }

    @inline(__always) func render() -> Double {
        guard active else { return 0 }
        let dur = 0.5
        if t >= dur { active = false; return 0 }
        let p = t / dur
        let freq = 45.0 + 95.0 * exp(-20.0 * p)   // ~140 Hz snapping down to 45 Hz
        let amp = exp(-5.0 * p)
        phase += freq / sr
        if phase >= 1 { phase -= 1 }
        t += 1.0 / sr
        return sin(2.0 * .pi * phase) * amp * 0.95
    }
}

// MARK: - LFO (a mappable modulation source)

final class LFO {
    private var phase = 0.0
    let sampleRate: Double
    init(sampleRate: Double) { self.sampleRate = sampleRate }

    func reset() { phase = 0 }

    // shape: 0 sine · 1 triangle · 2 saw · 3 square (quantized). Returns bipolar -1…1.
    @inline(__always) func render(hz: Double, shape: Double) -> Double {
        phase += hz / sampleRate
        if phase >= 1 { phase -= 1 }
        let s = Int(clamp01(shape / 3.0) * 3.0 + 0.5)
        switch s {
        case 1:  return 4.0 * abs(phase - 0.5) - 1.0            // triangle
        case 2:  return 2.0 * phase - 1.0                        // saw
        case 3:  return phase < 0.5 ? 1.0 : -1.0                 // square
        default: return sin(2.0 * .pi * phase)                  // sine
        }
    }
}
