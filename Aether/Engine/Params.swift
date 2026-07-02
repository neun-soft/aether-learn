import Foundation

// Every knob in the teaching instrument is one addressable, normalized (0…1) parameter.
// Real-world ranges are applied at the point of use (cutoffHz, seconds, etc.) so the mod
// matrix can sum contributions in a single normalized space.

enum ParamID: String, CaseIterable, Codable {
    // Oscillator
    case oscWave        // morph: sine → triangle → saw → square
    case oscPulse       // pulse width shaping on the bright end
    case detune         // unison spread / 2nd-voice detune

    // Filter (subtractive)
    case cutoff
    case resonance
    case filterType     // quantized: LP / HP / BP / notch

    // Amplitude envelope (DAHDSR)
    case ampDelay
    case ampAttack
    case ampHold
    case ampDecay
    case ampSustain
    case ampRelease
    case ampCurve       // 0 = linear, 1 = strongly exponential

    // LFO 1 (the mappable modulator)
    case lfoRate
    case lfoDepth
    case lfoShape       // sine / tri / saw / square

    // FX
    case drive
    case reverb
    case reverbMix

    var spec: ParamSpec { ParamSpec.table[self]! }

    static let order: [ParamID: Int] =
        Dictionary(uniqueKeysWithValues: allCases.enumerated().map { ($1, $0) })
    var index: Int { ParamID.order[self]! }
}

struct ParamSpec {
    let name: String
    let short: String
    let def: Double

    static let table: [ParamID: ParamSpec] = [
        .oscWave:    .init(name: "Wave",     short: "WAVE",  def: 0.30),
        .oscPulse:   .init(name: "Width",    short: "PW",    def: 0.50),
        .detune:     .init(name: "Detune",   short: "DTUNE", def: 0.0),
        .cutoff:     .init(name: "Cutoff",   short: "CUT",   def: 0.70),
        .resonance:  .init(name: "Reso",     short: "RES",   def: 0.20),
        .filterType: .init(name: "Type",     short: "TYPE",  def: 0.00),
        .ampDelay:   .init(name: "Delay",    short: "DLY",   def: 0.00),
        .ampAttack:  .init(name: "Attack",   short: "ATK",   def: 0.06),
        .ampHold:    .init(name: "Hold",     short: "HOLD",  def: 0.00),
        .ampDecay:   .init(name: "Decay",    short: "DEC",   def: 0.35),
        .ampSustain: .init(name: "Sustain",  short: "SUS",   def: 0.75),
        .ampRelease: .init(name: "Release",  short: "REL",   def: 0.35),
        .ampCurve:   .init(name: "Curve",    short: "CRV",   def: 0.60),
        .lfoRate:    .init(name: "Rate",     short: "RATE",  def: 0.35),
        .lfoDepth:   .init(name: "Depth",    short: "DEPTH", def: 0.00),
        .lfoShape:   .init(name: "Shape",    short: "SHAPE", def: 0.00),
        .drive:      .init(name: "Drive",    short: "DRIVE", def: 0.10),
        .reverb:     .init(name: "Reverb",   short: "SIZE",  def: 0.45),
        .reverbMix:  .init(name: "Mix",      short: "MIX",   def: 0.25),
    ]
}

// A patch is just the base value of every parameter.
struct Patch {
    var values: [ParamID: Double]

    init(_ overrides: [ParamID: Double] = [:]) {
        var v: [ParamID: Double] = [:]
        for id in ParamID.allCases { v[id] = id.spec.def }
        for (k, val) in overrides { v[k] = val }
        values = v
    }

    subscript(_ id: ParamID) -> Double {
        get { values[id] ?? id.spec.def }
        set { values[id] = min(1, max(0, newValue)) }
    }
}
