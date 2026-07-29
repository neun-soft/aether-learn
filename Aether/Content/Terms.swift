import Foundation

// MARK: - The glossary, defined once
//
// Every tappable word in the course comes from here. Defining them in one place is not tidiness:
// a reader who taps "harmonic" in module one and again in module six must get the same sentence
// both times, or the word stops being a fixed thing they can build on. Lessons pick from this
// list; they do not write their own definitions.
//
// House rules for a definition:
//   - one sentence, and no other jargon inside it
//   - say what it IS, not what it is for
//   - `more` is optional and earns its place only by answering the obvious next question

enum G {

    // MARK: Sound itself

    static let frequency = Term(
        word: "frequency",
        plain: "How many times something repeats each second.",
        more: "A wave repeating 440 times a second is the note A. Repeat it faster and the note gets higher.")

    static let pitch = Term(
        word: "pitch",
        plain: "How high or low a note sounds to you.")

    static let amplitude = Term(
        word: "amplitude",
        plain: "How tall a wave is, meaning how big a push it makes through the air.",
        more: "Bigger pushes carry more energy, which is most of what you hear as louder.")

    static let loudness = Term(
        word: "loudness",
        plain: "How loud a sound actually seems to you, which is not quite the same as how big it is.")

    static let waveform = Term(
        word: "waveform",
        plain: "The shape one repeat of a wave traces out.",
        more: "The shape is what makes a flute and a violin sound different while playing the same note.")

    static let harmonic = Term(
        word: "harmonic",
        plain: "An extra frequency sitting neatly above the main note, at two times, three times, four times its speed.",
        more: "Harmonics are why two instruments playing the same note still sound different.")

    static let harmonics = Term(
        word: "harmonics",
        plain: "Extra frequencies sitting neatly above the main note, at two times, three times, four times its speed.",
        more: "More harmonics sounds brighter and buzzier. A square-ish wave has far more of them than a round one.")

    static let fundamental = Term(
        word: "fundamental",
        plain: "The lowest frequency in a sound, and the one you hear as the note.")

    static let sineWave = Term(
        word: "sine wave",
        plain: "The simplest possible wave, a smooth curve with nothing else mixed into it.",
        more: "Every other wave can be built by stacking sine waves together.")

    static let tone = Term(
        word: "tone",
        plain: "A sound with a steady pitch you could hum along with.",
        more: "People also use the word loosely to mean the character of a sound, as in a bright tone or a warm tone. Both meanings are common.")

    static let synthesis = Term(
        word: "synthesis",
        plain: "Making a sound from scratch rather than recording one.",
        more: "Synthesise just means to build something up from parts. A synthesiser is a machine for doing it.")

    static let timbre = Term(
        word: "timbre",
        plain: "What makes two instruments playing the same note still sound different.",
        more: "A piano and a guitar can play the exact same pitch and you can still tell them apart. That difference is timbre. It is pronounced TAM-ber.")

    static let spectrum = Term(
        word: "spectrum",
        plain: "A picture of which frequencies are in a sound, low on the left and high on the right.",
        more: "A tall bar means there is a lot of that frequency in the sound.")

    static let cycle = Term(
        word: "cycle",
        plain: "One full repeat of a wave, before it starts over.")

    static let beating = Term(
        word: "beating",
        plain: "The slow throbbing you hear when two notes are almost, but not quite, the same pitch.")

    // MARK: The instrument

    static let oscillator = Term(
        word: "oscillator",
        plain: "The part of a synth that makes the raw repeating wave.",
        more: "Oscillate just means to move back and forth. Everything else in the synth shapes what the oscillator produces.")

    static let noise = Term(
        word: "noise",
        plain: "Sound with no repeating pattern, so it has no note in it.")

    static let filter = Term(
        word: "filter",
        plain: "Anything that removes some frequencies from a sound and leaves the others.")

    static let cutoff = Term(
        word: "cutoff",
        plain: "The frequency where a filter starts doing its job.",
        more: "On a low-pass filter everything above the cutoff is removed. On a high-pass filter, everything below it.")

    static let resonance = Term(
        word: "resonance",
        plain: "A boost right at the filter's cutoff, which makes that one frequency stand out.",
        more: "Push it far enough and the filter starts ringing at that frequency on its own.")

    static let lowPass = Term(
        word: "low-pass filter",
        plain: "A filter that lets low frequencies through and blocks high ones.")

    static let highPass = Term(
        word: "high-pass filter",
        plain: "A filter that lets high frequencies through and blocks low ones.")

    static let subtractive = Term(
        word: "subtractive",
        plain: "Making a sound by starting with something rich and taking parts away.",
        more: "It is the opposite of building a sound up from nothing, and it is how most synths work.")

    // MARK: Shape over time

    static let envelope = Term(
        word: "envelope",
        plain: "The shape of a sound's loudness from the moment it starts to the moment it ends.",
        more: "It does not have to control loudness. Point it at pitch and the pitch traces the same shape.")

    static let attack = Term(
        word: "attack",
        plain: "How long a sound takes to reach full volume after it starts.")

    static let decay = Term(
        word: "decay",
        plain: "How long a sound takes to fall from full volume down to its holding level.")

    static let sustain = Term(
        word: "sustain",
        plain: "The level a sound holds at while you keep the key held down.")

    static let release = Term(
        word: "release",
        plain: "How long a sound takes to fade away after you let go of the key.")

    static let percussive = Term(
        word: "percussive",
        plain: "Sounding like something that was struck rather than blown or bowed.")

    // MARK: Movement

    static let modulation = Term(
        word: "modulation",
        plain: "One control automatically moving another one for you.",
        more: "Anything you could do by turning a knob with your finger, a modulation can do faster and more precisely.")

    static let lfo = Term(
        word: "LFO",
        plain: "A very slow wave used to move a knob for you instead of your finger.",
        more: "It stands for low frequency oscillator. Low frequency means slow enough to watch.")

    static let vibrato = Term(
        word: "vibrato",
        plain: "A small, regular wobble in pitch, the kind a singer adds to a held note.")

    static let tremolo = Term(
        word: "tremolo",
        plain: "A regular wobble in volume, so the sound pulses instead of staying steady.")

    static let detune = Term(
        word: "detune",
        plain: "Slightly mistuning one copy of a sound against another so they drift against each other.",
        more: "The drifting is what your ear reads as width. Too much and it just sounds out of tune.")

    // MARK: Other ways to make a wave

    static let carrier = Term(
        word: "carrier",
        plain: "In FM, the wave you actually hear.")

    static let modulator = Term(
        word: "modulator",
        plain: "In FM, the hidden wave that bends the carrier. You never hear it by itself.")

    static let ratio = Term(
        word: "ratio",
        plain: "How fast one thing runs compared to another.",
        more: "A ratio of 2 means the hidden wave goes round twice for every one time the wave you hear goes round.")

    // MARK: Effects

    static let drive = Term(
        word: "drive",
        plain: "How hard a sound is pushed into something that cannot take it all.",
        more: "It is called drive because you are driving the signal past the limit on purpose, to change how it sounds.")

    static let ceiling = Term(
        word: "ceiling",
        plain: "The loudest signal a piece of equipment can pass on before it runs out of room.")

    static let overloading = Term(
        word: "overloading",
        plain: "Sending in more than something can handle, so the loudest parts get flattened.")

    static let distortion = Term(
        word: "distortion",
        plain: "When a wave comes out of something a different shape from how it went in.",
        more: "Distort just means change the shape. Since the shape is what you hear, a changed shape is a changed sound.")

    static let peaks = Term(
        word: "peaks",
        plain: "The tallest points of a wave, where it is furthest from the middle.")

    static let delay = Term(
        word: "delay",
        plain: "An effect that stores a sound and plays it back a moment later.")

    static let echo = Term(
        word: "echo",
        plain: "The same sound reaching you a second time, after taking longer to arrive.")

    static let feedback = Term(
        word: "feedback",
        plain: "Sending something back into where it came from, so it happens again.",
        more: "In a delay, feeding the copy back in is what turns one repeat into many.")

    static let cancel = Term(
        word: "cancel",
        plain: "When one wave pushes while another pulls, so they undo each other and you hear nothing.",
        more: "This is exactly how noise-cancelling headphones work.")

    static let combFilter = Term(
        word: "comb filter",
        plain: "A filter that removes a row of evenly spaced frequencies, leaving gaps like the teeth of a comb.")

    static let flanger = Term(
        word: "flanger",
        plain: "An effect that slowly moves the gaps of a comb filter up and down, giving a sweeping, jet-plane sound.")

    static let chorus = Term(
        word: "chorus",
        plain: "An effect that uses a slightly longer, gently wandering copy to make one sound seem like several.")

    static let reverb = Term(
        word: "reverb",
        plain: "The wash of sound made by thousands of bounces around a room.",
        more: "Short for reverberation. It is what tells you, with your eyes shut, whether you are in a cupboard or a church.")

    static let bounce = Term(
        word: "bounce",
        plain: "Sound hitting a surface and coming back off it, the way light does off a mirror.")

    // MARK: Putting it together

    static let patch = Term(
        word: "patch",
        plain: "One complete sound, meaning every setting on the synth at once.",
        more: "The word comes from old synths, where you connected the parts together with patch cables.")

    static let signalPath = Term(
        word: "signal path",
        plain: "The route a sound takes through the synth, from where it is made to where it comes out.")

    static let lead = Term(
        word: "lead",
        plain: "The sound playing the main melody, the part a listener follows.")

    static let pad = Term(
        word: "pad",
        plain: "A slow, soft sound that fills the background behind everything else.")

    static let layer = Term(
        word: "layer",
        plain: "Two or more sounds played at the same moment so they are heard as one.")

    // MARK: Gear

    static let driver = Term(
        word: "driver",
        plain: "The moving part inside a speaker or headphone that actually pushes the air.")

    static let woofer = Term(
        word: "woofer",
        plain: "A large speaker driver built to move enough air for low notes.")

    static let medium = Term(
        word: "medium",
        plain: "Whatever the sound is travelling through, usually air, but water and solids work too.")
}
