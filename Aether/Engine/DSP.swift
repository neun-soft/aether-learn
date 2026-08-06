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

    // Partial-sum saws for the additive lesson: n = 1 is a pure sine, n = 24 is the full saw
    // (the same 24 harmonics the saw table itself is built from).
    static let maxPartials = 24
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
    private(set) var phase = 0.0
    /// True on the sample where phase wrapped past 1. Hard sync watches this on the master
    /// oscillator to know when to restart the slave.
    private(set) var didWrap = false
    let sampleRate: Double
    init(sampleRate: Double) { self.sampleRate = sampleRate }

    func reset() { phase = 0; didWrap = false }

    /// Restart the cycle mid-flight. The discontinuity this creates *is* the sound of hard sync.
    @inline(__always) func syncReset() { phase = 0 }

    /// `phaseMod` offsets the read position rather than the frequency — phase modulation, which
    /// is what every "FM" synth since the DX7 actually does. It stays stable at high depths,
    /// where true frequency modulation drifts off pitch.
    @inline(__always) func render(hz: Double, morph: Double, pulse: Double, phaseMod: Double = 0) -> Double {
        phase += hz / sampleRate
        didWrap = false
        if phase >= 1 { phase -= 1; didWrap = true }
        let p = phaseMod == 0 ? phase : (phase + phaseMod).truncatingRemainder(dividingBy: 1.0) + 1.0
        let read = p >= 1 ? p - 1 : p
        var s = WaveTables.sample(morph: morph, phase: read)
        // Pulse-width shaping only bites near the square end, where it is musically meaningful.
        if morph > 0.66 {
            let pw = 0.5 + (pulse - 0.5) * 0.9
            let second = WaveTables.sample(morph: morph, phase: fmod(read + pw, 1.0))
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

/// Topology-preserving (zero-delay-feedback) state variable filter.
///
/// This used to be a Chamberlin SVF, which is only stable while its coefficient stays under ~1.
/// That clamp bit at about 7 kHz — so the top sixth of the CUTOFF knob moved nothing at all, in
/// any lesson, and the hi-hat exercise (a high-pass swept as far up as it will go) is exactly
/// where that shows. The TPT form stays accurate to its cutoff right up to Nyquist, so the knob
/// now does something everywhere along its travel.
final class SVFilter {
    private var ic1 = 0.0, ic2 = 0.0    // integrator states
    let sampleRate: Double
    init(sampleRate: Double) { self.sampleRate = sampleRate }

    func reset() { ic1 = 0; ic2 = 0 }

    @inline(__always) func process(_ x: Double, cutoffHz: Double, res: Double, mode: FilterMode) -> Double {
        // tan() runs away at Nyquist, so hold the cutoff just short of it.
        let g = tan(.pi * min(max(cutoffHz, 10.0), sampleRate * 0.45) / sampleRate)
        let k = max(0.035, 1.0 - res * 0.985)      // damping: lower value = more resonance
        let a1 = 1.0 / (1.0 + g * (g + k))
        let a2 = g * a1
        let a3 = g * a2
        let v3 = x - ic2
        let v1 = a1 * ic1 + a2 * v3
        let v2 = ic2 + a2 * ic1 + a3 * v3
        ic1 = 2 * v1 - ic1
        ic2 = 2 * v2 - ic2
        if !ic1.isFinite || !ic2.isFinite { ic1 = 0; ic2 = 0 }
        ic1 = flush(max(-6, min(6, ic1))); ic2 = flush(max(-6, min(6, ic2)))
        let low = v2
        let high = x - k * v1 - low
        switch mode {
        case .lowpass:  return low
        case .highpass: return high
        case .bandpass: return v1
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

// MARK: - Noise (the other way to make a sound)
//
// Every oscillator so far repeats: a cycle, then the same cycle again, which is why it has a
// pitch. Noise never repeats, so there is no pitch to hear — only colour. It is the raw material
// for wind, breath, and every drum that isn't a kick.

final class Noise {
    // xorshift32: cheap, no allocation, and identical on every device.
    private var state: UInt32 = 0x9E37_79B9
    // One-pole states for the pink tilt.
    private var p0 = 0.0, p1 = 0.0, p2 = 0.0

    func reset() { p0 = 0; p1 = 0; p2 = 0 }

    @inline(__always) private func white() -> Double {
        state ^= state << 13
        state ^= state >> 17
        state ^= state << 5
        return Double(Int32(bitPattern: state)) / Double(Int32.max)
    }

    /// `color`: 0 = white (flat, hissy), 1 = pink (−3 dB/octave, darker and more natural).
    /// Pink is the one that sounds like rain or breath; white is the one that sounds like a TV.
    @inline(__always) func render(color: Double) -> Double {
        let w = white()
        guard color > 0.001 else { return w }
        // Three stacked one-poles approximate the −3 dB/octave tilt closely enough to hear.
        p0 = 0.99765 * p0 + w * 0.0990460
        p1 = 0.96300 * p1 + w * 0.2965164
        p2 = 0.57000 * p2 + w * 1.0526913
        let pink = (p0 + p1 + p2 + w * 0.1848) * 0.22
        return lerp(w, pink, clamp01(color))
    }
}

// MARK: - Delay line (echo, and the short end of it: doubling and comb tones)

final class DelayLine {
    private var buf: [Double]
    private var write = 0
    private let sr: Double
    private var readTime = 0.05      // smoothed, so moving the time knob glides instead of clicking

    init(sampleRate: Double, maxSeconds: Double = 1.2) {
        sr = sampleRate
        buf = [Double](repeating: 0, count: max(1, Int(sampleRate * maxSeconds)))
    }

    func reset() {
        for i in buf.indices { buf[i] = 0 }
        write = 0
    }

    /// Returns the wet signal only; the caller decides the dry/wet balance.
    @inline(__always) func process(_ x: Double, timeSec: Double, feedback: Double) -> Double {
        // Glide the read distance. Jumping it would pitch-shift the tail audibly on every
        // knob movement, which reads as a bug rather than as an echo.
        readTime += (max(0.002, min(timeSec, Double(buf.count) / sr - 0.01)) - readTime) * 0.0006

        let d = readTime * sr
        var r = Double(write) - d
        if r < 0 { r += Double(buf.count) }
        let i0 = Int(r) % buf.count
        let i1 = (i0 + 1) % buf.count
        let wet = lerp(buf[i0], buf[i1], r - Double(Int(r)))

        // Cap feedback below 1 so a held knob can't build to infinity.
        var v = x + wet * min(0.92, max(0, feedback))
        if !v.isFinite { v = 0 }
        buf[write] = flush(max(-4, min(4, v)))
        write = (write + 1) % buf.count
        return wet
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
    /// Readable so the display can put its playhead on the phase that is actually sounding,
    /// instead of running its own wall-clock animation that drifts away from the audio.
    private(set) var phase = 0.0
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
