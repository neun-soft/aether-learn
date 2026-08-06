import Foundation

// A block-rate snapshot of everything the audio thread needs. Copied once per control block so
// the render loop never touches Swift dictionaries or locks per sample.
struct RenderSnapshot {
    var base: [Double]          // indexed by ParamID.index
    var routingSource: Int      // 0 = LFO, 1 = envelope
    var routingDest: Int        // ModDest.allCases index
    var toneHz: Double          // pure test-tone frequency (frequency lessons)
    var toneOn: Bool            // pure test-tone gate
    var simLow: Double          // playback simulation: master high-pass cutoff (0 = off)
    var simHigh: Double         // playback simulation: master low-pass cutoff (>=20000 = off)
    var additiveCount: Int      // >0 = play a partial-sum saw with this many sines (additive lesson)
    var toneBuzz: Bool          // test tone plays as a buzzy, bee-like timbre (the bee lesson)
    var toneFlutterHz: Double   // wingbeat amplitude-modulation rate, matched to the visible flap

    static let empty = RenderSnapshot(
        base: ParamID.allCases.map { $0.spec.def }, routingSource: 0, routingDest: 0,
        toneHz: 220, toneOn: false, simLow: 0, simHigh: 22000, additiveCount: 0, toneBuzz: false,
        toneFlutterHz: 6)

    @inline(__always) func v(_ id: ParamID) -> Double { base[id.index] }
}

// MARK: - One polyphonic voice

final class Voice {
    let sr: Double
    private let osc1: Oscillator
    private let osc2: Oscillator
    private let noise = Noise()
    private let filter: SVFilter
    let env: Envelope

    /// Whole-number ratios sound harmonic (another note in the same series); the in-between
    /// and high odd ones sound metallic, because their sidebands don't line up with the
    /// harmonic series. This is the whole lesson of FM in one array.
    static let fmRatios: [Double] = [0.5, 1, 1.5, 2, 3, 5, 7]

    /// FM depth 0…1 to modulation index. This has to reach a genuinely high index: below about
    /// 2 the carrier still dominates and every ratio — harmonic or not — reads as a clear note,
    /// which made "Repetition Makes a Note" impossible to hear. At index 6 an in-between ratio
    /// scatters enough energy off the harmonic series that the ear stops finding a pitch.
    /// The FM visual calls this too, so the drawing and the sound cannot disagree.
    static func fmIndex(_ amount: Double) -> Double { amount * 6.0 }

    private(set) var midi = 60
    private var vel = 0.8
    private var noteHz = 261.63

    var active: Bool { env.isActive }
    var startedAt = 0

    init(sampleRate: Double) {
        sr = sampleRate
        osc1 = Oscillator(sampleRate: sampleRate)
        osc2 = Oscillator(sampleRate: sampleRate)
        filter = SVFilter(sampleRate: sampleRate)
        env = Envelope(sampleRate: sampleRate)
    }

    func noteOn(_ m: Int, velocity: Double, snap: RenderSnapshot, order: Int) {
        midi = m; vel = velocity; noteHz = midiToHz(Double(m)); startedAt = order
        env.delay   = snap.v(.ampDelay) * 1.0
        env.attack  = 0.002 + pow(snap.v(.ampAttack), 2) * 3.0
        env.hold    = snap.v(.ampHold) * 1.5
        env.decay   = 0.005 + pow(snap.v(.ampDecay), 2) * 3.0
        env.sustain = snap.v(.ampSustain)
        env.release = 0.005 + pow(snap.v(.ampRelease), 2) * 4.0
        env.curve   = snap.v(.ampCurve)
        env.gateOn()
    }

    func noteOff() { env.gateOff() }
    func kill() { env.reset() }

    // The current amp-envelope level, so the UI can animate the shape.
    var envLevel: Double { env.value }

    @inline(__always) func render(_ s: RenderSnapshot, lfoValue: Double) -> Double {
        let e = env.process()
        env.sustain = s.v(.ampSustain)   // live sustain feels responsive while a note is held

        // Resolve the single modulation slot.
        let modRaw = s.routingSource == 1 ? e : lfoValue      // env: 0…1, LFO: -1…1
        let depth = s.v(.lfoDepth)
        var morph = s.v(.oscWave)
        var cutoffNorm = s.v(.cutoff)
        var pitchSemi = 0.0
        var ampMul = 1.0

        switch s.routingDest {
        case 1: pitchSemi = modRaw * depth * 3.0                 // pitch → vibrato
        case 2: cutoffNorm += modRaw * depth * 0.6              // cutoff → wobble
        case 3: ampMul = max(0, 1.0 + modRaw * depth * 0.9)     // amplitude → tremolo
        case 4: morph = clamp01(morph + modRaw * depth * 0.6)   // wave → morph movement
        default: break
        }

        let hz = noteHz * pow(2.0, pitchSemi / 12.0)
        let det = s.v(.detune) * 0.02
        let pulse = s.v(.oscPulse)

        // The second oscillator can only do one job at a time, so the three ways of using it
        // take strict precedence: FM, then sync, then the plain detuned pair. Teaching them
        // one at a time is also how the lessons introduce them, so a patch never sounds like
        // two effects fighting.
        let fm = s.v(.fmAmount)
        let sync = s.v(.syncAmount)
        var raw: Double

        if s.additiveCount > 0 {
            let table = WaveTables.partialSaw(s.additiveCount)
            let a = osc1.render(hz: hz * (1 - det), table: table)
            let b = osc2.render(hz: hz * (1 + det), table: table)
            raw = (a + b) * 0.5
        } else if fm > 0.001 {
            // osc2 is the modulator. Its own output never reaches the output — you hear it
            // only as the sidebands it puts on osc1.
            let ratio = Voice.fmRatios[Int(clamp01(s.v(.fmRatio)) * Double(Voice.fmRatios.count - 1) + 0.5)]
            let mod = osc2.render(hz: hz * ratio, morph: 0, pulse: 0.5)
            raw = osc1.render(hz: hz, morph: morph, pulse: pulse, phaseMod: mod * Voice.fmIndex(fm))
        } else if sync > 0.001 {
            // osc1 is the master: inaudible, it only keeps time. osc2 is the slave, tuned up
            // to 3 octaves above and forced to restart on every master cycle. The pitch you
            // hear stays the master's; sweeping the slave changes the timbre, not the note.
            _ = osc1.render(hz: hz, morph: 0, pulse: 0.5)
            if osc1.didWrap { osc2.syncReset() }
            raw = osc2.render(hz: hz * (1 + sync * 7), morph: morph, pulse: pulse)
        } else {
            let a = osc1.render(hz: hz * (1 - det), morph: morph, pulse: pulse)
            let b = osc2.render(hz: hz * (1 + det), morph: morph, pulse: pulse)
            raw = (a + b) * 0.5
        }

        // Noise sits alongside whatever the oscillators are doing rather than replacing them —
        // a breath on top of a flute, or, with the oscillators down, the drum itself.
        // At the top of the range the oscillator is gone completely, not just quieter. A lesson
        // that says "noise has no pitch" has to be able to prove it, and it cannot while a
        // pitched wave is still audible underneath.
        let nz = s.v(.noiseLevel)
        if nz > 0.001 { raw = raw * (1 - nz) + noise.render(color: s.v(.noiseColor)) * nz * 0.8 }

        let cutoffHz = 60.0 * pow(2.0, clamp01(cutoffNorm) * 8.0)
        let res = s.v(.resonance)
        let mode = FilterMode(rawValue: Int(clamp01(s.v(.filterType)) * 3.0 + 0.5)) ?? .lowpass
        let filtered = filter.process(raw, cutoffHz: cutoffHz, res: res, mode: mode)

        return filtered * e * ampMul * vel
    }
}
