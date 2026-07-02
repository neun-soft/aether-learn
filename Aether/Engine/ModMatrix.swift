import Foundation

// The teaching instrument exposes one editable modulation slot: pick a SOURCE, point it at a
// DESTINATION, dial the DEPTH. That's enough to teach vibrato, tremolo, filter wobble, morph
// movement, and "an envelope is also a modulator", without a full drag-matrix on a phone screen.
// The routing is deliberately generalized so more slots can be added later.

enum ModSource: String, CaseIterable, Codable, Identifiable {
    case lfo = "LFO"
    case envelope = "Envelope"
    var id: String { rawValue }
}

enum ModDest: String, CaseIterable, Codable, Identifiable {
    case none = "Off"
    case pitch = "Pitch"        // vibrato
    case cutoff = "Cutoff"      // filter wobble
    case amplitude = "Volume"   // tremolo
    case wave = "Wave"          // morph movement
    var id: String { rawValue }
}

struct Routing: Codable, Equatable {
    var source: ModSource = .lfo
    var dest: ModDest = .none

    static let off = Routing(source: .lfo, dest: .none)
}
