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

    static let empty = RenderSnapshot(
        base: ParamID.allCases.map { $0.spec.def }, routingSource: 0, routingDest: 0,
        toneHz: 220, toneOn: false, simLow: 0, simHigh: 22000)

    @inline(__always) func v(_ id: ParamID) -> Double { base[id.index] }
}

// MARK: - One polyphonic voice

final class Voice {
    let sr: Double
    private let osc1: Oscillator
    private let osc2: Oscillator
    private let filter: SVFilter
    let env: Envelope

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
        let a = osc1.render(hz: hz * (1 - det), morph: morph, pulse: pulse)
        let b = osc2.render(hz: hz * (1 + det), morph: morph, pulse: pulse)
        let raw = (a + b) * 0.5

        let cutoffHz = 60.0 * pow(2.0, clamp01(cutoffNorm) * 8.0)
        let res = s.v(.resonance)
        let mode = FilterMode(rawValue: Int(clamp01(s.v(.filterType)) * 3.0 + 0.5)) ?? .lowpass
        let filtered = filter.process(raw, cutoffHz: cutoffHz, res: res, mode: mode)

        return filtered * e * ampMul * vel
    }
}
