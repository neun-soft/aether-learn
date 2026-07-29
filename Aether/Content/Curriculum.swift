import SwiftUI

// The whole course as hardcoded data. Each lesson is theory, an optional scripted demo, and a
// hands-on exercise built around a visual. Every explanation is grounded in the same pure basic:
// sound is a vibration traveling through a medium, and a synth builds that vibration up step by step.

private func lane(_ p: ParamID, _ pts: [(Double, Double)]) -> AutomationLane {
    AutomationLane(param: p, frames: pts.map { Keyframe(t: $0.0, value: $0.1) })
}
private func held(_ midi: Int, _ dur: Double) -> [NoteEvent] { [NoteEvent(t: 0, midi: midi, dur: dur)] }
private func pulses(_ midi: Int, count: Int, every: Double, dur: Double) -> [NoteEvent] {
    (0..<count).map { NoteEvent(t: Double($0) * every, midi: midi, dur: dur) }
}

enum Curriculum {
    // Flattened, ordered list of every lesson with its owning module, for linear navigation.
    static let flat: [(lesson: Lesson, module: Module)] =
        course.modules.flatMap { m in m.lessons.map { (lesson: $0, module: m) } }
    static func indexOf(_ lessonID: String) -> Int { flat.firstIndex { $0.lesson.id == lessonID } ?? 0 }

    // MARK: - Free tier
    //
    // The first module is free end to end: every lesson, the demos, the exercises, the
    // completion screen. Everything after it is behind the one-time unlock. Pinned by id
    // rather than position so reordering the course can't silently give away a paid module.

    static let freeModuleID = "m1"

    static var freeModule: Module { course.modules.first { $0.id == freeModuleID } ?? course.modules[0] }

    static func isFree(moduleID: String) -> Bool { moduleID == freeModuleID }

    /// Whether a lesson is playable without paying. Unknown ids read as free — a content
    /// bug should never lock someone out of something they already bought.
    static func isFree(lessonID: String) -> Bool {
        guard let ref = flat.first(where: { $0.lesson.id == lessonID }) else { return true }
        return isFree(moduleID: ref.module.id)
    }

    /// What the unlock actually buys, computed so the paywall copy can't drift from the course.
    static var paidModuleCount: Int { course.modules.filter { !isFree(moduleID: $0.id) }.count }
    static var paidLessonCount: Int { course.allLessons.count - freeModule.lessons.count }

    static let course = Course(
        id: "foundations",
        title: "Sound Design Foundations",
        subtitle: "Learn synthesis from the ground up, by turning real knobs.",
        // Order matters commercially, not just pedagogically. `frequency` is the free module,
        // so whatever sits next is the first thing a buyer touches after paying — it needs to
        // be the payoff, and a resonant filter sweep is the payoff. `playback` (speakers and
        // gear) is the module people are least willing to pay for and the dullest thing to
        // land on straight after a purchase, so it moves to the end as an appendix.
        modules: [frequency, subtractive, shape, motion, sources, effects, drums, building, playback]
    )


    // MARK: Module - Other Ways to Make a Wave
    //
    // Placed after Motion, not before it: these lessons lean on the LFO and on modulation, and
    // an earlier draft referenced both before either had been taught.

    static let sources = Module(
        id: "msr", title: "Other Ways to Make a Wave", subtitle: "Noise, FM, and sync", accent: Theme.tone,
        lessons: [
            Lesson(
                id: "msr1", title: "Noise Has No Pitch",
                concept: "Noise is every frequency at once, in amounts that never stop changing. That is why there is no note in it.",
                theory: [
                    "Here is the only reason anything has a pitch: the wave repeats. The same shape, again and again. How many times it repeats each second is the note you hear.",
                    "Noise does not repeat. Ever. It is a brand new random value every instant, so there is no shape to come back around, and nothing for your ear to count.",
                    "So what is actually in it? Every frequency, all of them, all at the same time, and in amounts that change constantly. That is the honest description: a bit of everything, forever rearranging. There is no one frequency standing out, and a note is exactly one frequency standing out, which is why there is no note to hear.",
                    "Turn the Noise knob all the way up in the exercise and the pitch disappears completely. You can still play the keyboard and it will make no difference at all.",
                    "Not all noise has the same amounts, though. Some has just as much high as low. Some has more low than high. Those two need names, and the names sound odd until you know where they came from.",
                    "Light is made of frequencies too. Slow light looks red to us, fast light looks violet, and everything else sits in between. Your eye does not hear them one at a time the way it would notes. It adds up whatever arrives and reports back a single colour.",
                    "Add up every frequency of light in equal amounts and the colour your eye reports is white. That is all white means: everything, evenly. So sound with every frequency in equal amounts got called white noise. It is the same word for the same idea, borrowed.",
                    "Now take away some of the fast end, the blues and violets, and leave the slow red end standing. The colour your eye reports is pink. Sound with more low than high got the same name for the same reason: pink noise. In the exercise the swatch is worked out from the bars above it, so you can watch the colour change as you take the top off."
                ],
                takeaways: [
                    "Noise is every frequency at once, in constantly changing amounts",
                    "A note is one frequency standing out, and in noise none does",
                    "Light is frequencies too, and your eye adds them into one colour",
                    "Everything evenly looks white, so even sound is called white noise",
                    "More low than high looks pink, so that sound is called pink noise"
                ],
                demo: nil,
                terms: [G.frequency, G.pitch, G.noise, G.spectrum],
                exercise: Exercise(
                    prompt: "Turn NOISE up until the note is gone and the keyboard stops mattering. Then move COLOUR and watch the bars tilt, the swatch turn pink, and the hiss soften into rain.",
                    visibleParams: [.noiseLevel, .noiseColor],
                    basePatch: Patch([.noiseLevel: 0.0, .noiseColor: 0.0, .oscWave: 0.0, .cutoff: 1.0,
                                      .ampAttack: 0.02, .ampDecay: 0.3, .ampSustain: 0.9, .ampRelease: 0.25]),
                    visual: .noiseColor,
                    tip: "With NOISE at the top, play the highest key and then the lowest. They sound identical. That is what having no pitch means.",
                    controlsHint: "NOISE is how much, COLOUR tilts how much of it is low against high"
                )
            ),
            Lesson(
                id: "msr2", title: "FM Synthesis",
                concept: "FM is the LFO you already know, pointed at pitch and sped up until you can no longer follow it.",
                theory: [
                    "The shortest honest description of FM is this: it is a fast LFO.",
                    "You already have the whole idea. An LFO is a wave that moves a control for you instead of your finger. Point it at the pitch and you get vibrato, the note wobbling up and down a few times a second, and you can count the wobbles.",
                    "Now speed that same wave up. Not five times a second, but five hundred. Two things change.",
                    "First, you stop being able to follow it. This is the same threshold from the very start of the course, where a vibration became a note: below roughly twenty times a second your ear reports separate events, and above it your ear gives up counting and reports one steady thing instead. A wobble crossing that line stops being heard as a wobble.",
                    "Second, the sound changes character. The note stays exactly where it is. What changes is what it sounds like: harder and brighter, more like a bell or a struck metal bar than a plain tone.",
                    "Here is the picture that makes it stick. Put a record on a turntable. The record is the carrier: it is the thing actually making the sound. Now rest a finger on the platter and wobble the speed.",
                    "Your finger is the modulator. Your finger makes no sound at all. Nobody in the room hears your finger. But everybody hears what your finger did to the record.",
                    "Wobble slowly and the pitch sags and rises, the sound of a tape deck that will not hold its speed, which engineers call wow and flutter. Wobble two hundred times a second and you can no longer pick out individual wobbles at all. What you hear instead is a completely different sound. Same finger, same wobbling, only faster than your ear can resolve.",
                    "That also settles a question worth asking: is the fast wave too high-pitched to hear? No. It is running at ordinary note speed and would sound like a perfectly normal tone if you sent it to the speakers. But you do not send it to the speakers, any more than you point a microphone at your finger. It only moves something.",
                    "Which control? With the LFO you chose: pitch, volume, the filter. With FM the choice is already made, and it is in the name. F is frequency, so the fast wave is pointed at the frequency of the wave you hear. M is modulation, which is the word for one control moving another. Frequency modulation.",
                    "The only reason it stops being called an LFO is the L. Low frequency oscillator: low frequency is the whole meaning of the name, so once it is fast the name no longer fits. Same part, same wiring, different speed, different word.",
                    "The two waves have names worth knowing, because every FM synth uses them. The one you hear is the carrier. The fast hidden one bending it is the modulator.",
                    "So what does the FM knob change? Not volume, and not a blend between two sounds. The modulator\'s output is added onto the carrier\'s frequency: when the modulator is high the carrier speeds up, when it is low it slows down. The knob is how much gets added. At zero, nothing is added and the speed stays flat."
                ],
                takeaways: [
                    "FM is an LFO pointed at pitch and sped up past what you can follow",
                    "Above roughly twenty times a second a wobble stops sounding like a wobble",
                    "The fast wave is ordinary and audible, it is just never sent to the speakers",
                    "F is frequency, which is the control it moves; M is modulation",
                    "It stops being called an LFO because the L means low"
                ],
                demo: nil,
                terms: [G.lfo, G.modulation, G.oscillator, G.carrier, G.modulator, G.frequency,
                        G.vibrato, G.tone, G.synthesis, G.wowAndFlutter],
                exercise: Exercise(
                    prompt: "Hold a note and turn FM up slowly. The top wave is bending the middle one, and the bottom row is the result. The note does not move; what it sounds like does.",
                    visibleParams: [.fmAmount],
                    basePatch: Patch([.fmAmount: 0.0, .fmRatio: 0.5, .oscWave: 0.0, .cutoff: 1.0,
                                      .ampAttack: 0.01, .ampDecay: 0.4, .ampSustain: 0.85, .ampRelease: 0.3]),
                    visual: .fm,
                    tip: "Go back to the vibrato lesson and compare. Identical wiring, a thousand times the speed, and nothing about the two sounds seems related.",
                    controlsHint: "FM is how much of the hidden wave gets added onto the speed of the one you hear"
                )
            ),
            Lesson(
                id: "msr3", title: "Repetition Makes a Note",
                concept: "Whether FM sounds musical or like struck metal depends on how the two waves line up.",
                theory: [
                    "FM depth decides how much bending happens. This lesson is about the other knob: how fast the hidden wave runs compared to the one you hear.",
                    "When the hidden wave runs at a simple multiple, twice as fast or three times as fast, the two line up neatly. Every bend happens at the same point in every cycle, so the result still repeats. It repeats, so it still has a pitch, and it still sounds like a note.",
                    "When it runs at something in between, like one and a half times, they never quite line up. The bends land in a different place every cycle, so the wave does not settle into a repeating shape. Less repetition means less pitch, and your ear hears metal instead of a note. Bells, gongs, and the inside of a piano all work this way.",
                    "This is not a synth trick. It is exactly why a real bell sounds like a bell.",
                    "Pluck a string, or blow down a tube, and the extra frequencies that come out sit at neat whole-number multiples of the lowest one: two times, three times, four times. Your ear knows that pattern and fuses the whole stack into a single note.",
                    "Hit a bell and the extra frequencies land at ratios like 2.76 times, or 5.4 times. Nothing lines up with anything. Your ear cannot fit them into one series, finds no single pitch to settle on, and reports metal rather than a note. It is also why tuning a bell is a specialist craft: the founder is shaping the metal to drag those stubborn ratios back towards something musical.",
                    "Your RATIO knob is doing the same thing from the other end. Whole numbers put the extra frequencies on the neat multiples, so you get an instrument. In-between numbers put them between the multiples, so you get metal.",
                    "That is why RATIO is the interesting knob and not the depth one. Depth makes it brighter. Ratio decides whether you are building an instrument or a bell."
                ],
                takeaways: [
                    "Whole-number ratios line up, keep repeating, and still sound like a note",
                    "In-between ratios never line up, so the sound turns metallic",
                    "A real bell is metallic for the same reason: its frequencies do not line up either",
                    "Depth changes how bright it is; ratio changes what kind of thing it is"
                ],
                demo: nil,
                terms: [G.ratio, G.carrier, G.harmonic, G.harmonics, G.fundamental, G.pitch],
                exercise: Exercise(
                    prompt: "Step RATIO through its positions. Watch the bottom wave: at whole numbers it settles into a repeating shape, and in between it never does. Listen for the moment it stops sounding like a note.",
                    visibleParams: [.fmRatio, .fmAmount],
                    basePatch: Patch([.fmAmount: 0.5, .fmRatio: 0.5, .oscWave: 0.0, .cutoff: 1.0,
                                      .ampAttack: 0.0, .ampDecay: 0.5, .ampSustain: 0.7, .ampRelease: 0.4]),
                    visual: .fm,
                    tip: "Ratio 1, 2, and 3 sound like instruments. 1.5 and 7 sound like something you would hit with a stick.",
                    controlsHint: "RATIO steps through fixed speeds: 0.5, 1, 1.5, 2, 3, 5, 7"
                )
            ),
            Lesson(
                id: "msr4", title: "Restarting Adds Harmonics",
                concept: "Two oscillators, where one keeps interrupting the other and dragging it back to the beginning.",
                theory: [
                    "The name is short for synchronise, which means forcing two things to keep in step. Here one oscillator is forced to keep in step with another, whether it wants to or not.",
                    "There are two of them. The first is silent, and its only job is to keep time. Every time it finishes a cycle it reaches over and yanks the second one back to the very start, wherever that one had got to. The second oscillator is the one you actually hear.",
                    "Being cut off halfway through leaves a sharp corner in the wave, because it drops instantly back to zero instead of curving down gently. Sharp corners sound bright and harsh, which is why sync has that tearing, screaming quality.",
                    "Here is the useful part. The interruptions always happen at the same moments, because the silent one is still keeping the same time. Something repeats at the same rate as before, so the note you hear does not move.",
                    "You will still hear something climbing as you turn the knob, and it is worth being clear about what it is. It is not the note. It is a bright peak in the tone, sliding upwards as the interrupted wave is squeezed tighter. Play a low note and turn SYNC slowly: underneath the sliding brightness, the note itself stays exactly where you put it."
                ],
                takeaways: [
                    "Sync is short for synchronise: keeping two things in step",
                    "A silent oscillator keeps time and restarts the one you hear, every cycle",
                    "Being cut off mid-wave leaves a sharp corner, which sounds bright and harsh",
                    "The interruptions never move, so the note stays put",
                    "What slides upward as you turn it is the brightness, not the pitch"
                ],
                demo: nil,
                terms: [
                    G.oscillator,
                    G.cycle,
                    G.pitch
                ],
                exercise: Exercise(
                    prompt: "Hold a note and turn SYNC up slowly. Watch the dotted lines stay exactly where they are while the wave between them gets squeezed in. That is why the note does not change.",
                    visibleParams: [.syncAmount],
                    basePatch: Patch([.syncAmount: 0.0, .oscWave: 0.55, .cutoff: 1.0, .resonance: 0.0,
                                      .ampAttack: 0.01, .ampDecay: 0.4, .ampSustain: 0.9, .ampRelease: 0.3]),
                    visual: .sync,
                    tip: "Play the lowest note you can and turn SYNC very slowly. The bottom of the sound never moves.",
                    controlsHint: "SYNC tunes the wave you hear. The note does not follow it"
                )
            )
        ]
    )

    // MARK: Module - Effects as Timbre

    static let effects = Module(
        id: "mfx", title: "Effects as Timbre", subtitle: "Drive, delay, and space", accent: Theme.signal,
        lessons: [
            Lesson(
                id: "mfx1", title: "Distortion Adds Harmonics",
                concept: "Push a sound past what the equipment can hold and its shape gets flattened. A new shape means a new sound.",
                theory: [
                    "Everything that carries sound has a limit to how loud a signal it can pass on. A speaker cone can only move so far. A wire can only carry so much. Think of pouring water into a glass: past the top, the extra does not go anywhere. The glass is full. That limit is called the ceiling.",
                    "Now push a wave into something with a ceiling, harder than it can take. The quiet middle of the wave passes through untouched. But the loud peaks, the tallest parts, hit the ceiling and cannot go any higher, so they come out flattened off at the top. That is what overloading means: sending in more than the thing can pass on.",
                    "Here is why that matters, and it goes back to the very first module. The shape of a wave is what decides how it sounds. You have already heard this: a smooth round wave sounds soft, a square-edged wave sounds harsh and buzzy. Flattening the peaks changes a round shape into a squarer one, so the sound changes with it.",
                    "That change has a name. Distortion just means the shape came out different from how it went in. And because a flatter, squarer shape is made of more harmonics than a round one, distortion always means more harmonics: more buzz, more edge, more of the sound you get from a guitar amp turned up.",
                    "The DRIVE knob is how hard you push. A little and only the very tips get rounded off, which people hear as warmth. A lot and the wave is squashed almost square, which people hear as grit and aggression. Watch the picture as you turn it: the faint line is the wave going in, the bright one is what comes out."
                ],
                takeaways: [
                    "Everything that carries sound has a ceiling it cannot go past",
                    "Overloading means pushing in more than it can pass on, so the peaks come out flat",
                    "The shape of a wave decides how it sounds, so a flattened shape sounds different",
                    "Distortion means the shape changed, and a flatter shape has more harmonics",
                    "A little drive sounds warm, a lot sounds gritty"
                ],
                demo: nil,
                terms: [
                    G.drive,
                    G.ceiling,
                    G.overloading,
                    G.distortion,
                    G.peaks,
                    G.harmonics,
                    G.harmonic
                ],
                exercise: Exercise(
                    prompt: "Hold a note and turn DRIVE up slowly. Watch the bright wave meet the dotted ceiling and flatten off against it.",
                    visibleParams: [.drive],
                    basePatch: Patch([.drive: 0.0, .oscWave: 0.0, .cutoff: 1.0, .resonance: 0.0,
                                      .ampAttack: 0.01, .ampDecay: 0.4, .ampSustain: 0.9, .ampRelease: 0.3]),
                    visual: .drive,
                    tip: "Start from a pure round wave. By the time DRIVE is at the top it is very nearly a square, and it sounds like one.",
                    controlsHint: "DRIVE is how hard the sound is pushed past the ceiling"
                )
            ),
            Lesson(
                id: "mfx2", title: "A Sound Can Arrive Twice",
                concept: "A delay keeps a copy of what you played and hands it back a moment later.",
                theory: [
                    "Shout at a cliff face and a moment later your voice comes back. Nothing new was made. The same sound simply took a longer route and arrived late. That is an echo, and a delay is a machine for producing one on purpose.",
                    "It works by keeping a very short recording. Everything you play goes into it, and a set amount of time later it comes back out. The TIME knob is how long that wait is.",
                    "You can also feed the copy back in to be recorded again. That gives you a second repeat, then a third, each one quieter than the last because a little is lost each time round. That is what FEEDBACK controls: not how loud the echo is, but how many times it goes round before it dies away.",
                    "ECHO decides how much of all this you actually hear next to the original sound. At zero the delay is still running, you simply are not listening to it.",
                    "In the picture, the white bar is the note you played and every coloured bar after it is the same note coming back. Move TIME and the bars spread apart or bunch up. Move FEEDBACK and more of them survive."
                ],
                takeaways: [
                    "A delay stores what you play and returns it after a set time",
                    "Time is the length of the wait",
                    "Feedback is how many repeats you get, because the copy is recorded again",
                    "Each repeat is quieter, so it fades out on its own"
                ],
                demo: nil,
                terms: [
                    G.delay,
                    G.echo,
                    G.feedback
                ],
                exercise: Exercise(
                    prompt: "Play one short note and watch it come back. Move TIME to spread the repeats apart, then FEEDBACK to get more of them.",
                    visibleParams: [.delayMix, .delayTime, .delayFeedback],
                    basePatch: Patch([.delayMix: 0.45, .delayTime: 0.45, .delayFeedback: 0.45,
                                      .oscWave: 0.3, .cutoff: 0.75,
                                      .ampAttack: 0.0, .ampDecay: 0.18, .ampSustain: 0.0, .ampRelease: 0.12]),
                    visual: .delay,
                    holdDefault: false,
                    tip: "Short taps show this best. A note you hold covers up its own repeats.",
                    controlsHint: "ECHO is how much you hear, TIME is the wait, FEEDBACK is how many"
                )
            ),
            Lesson(
                id: "mfx3", title: "Two Copies Cancel Each Other",
                concept: "Bring the copy close enough and you stop hearing two sounds. They start fighting instead.",
                theory: [
                    "Keep shortening the wait. At around a thirtieth of a second your ear gives up trying to hear two separate arrivals and hears one sound instead. But the copy has not gone anywhere.",
                    "Now the two are close enough to interfere with each other. A wave pushes and pulls. When both copies push at the same moment, they add together and that frequency gets louder. When one pushes while the other pulls, they work against each other and that frequency cancels out, sometimes completely.",
                    "Whether they help or fight depends on the frequency, so some frequencies survive and others vanish. Drawn as a spectrum, that leaves a row of evenly spaced gaps, which is what gives the effect its name: a comb filter, because it looks like the teeth of a comb.",
                    "You are hearing a filter now, not an echo, made out of nothing but a copy arriving slightly late. That is worth knowing because it is how three effects you will meet everywhere are built. Move those gaps slowly up and down and you have a flanger. Use a slightly longer wait and a gentler movement and you have a chorus."
                ],
                takeaways: [
                    "Below about a thirtieth of a second, two copies fuse into one sound",
                    "Where they push together, a frequency gets louder; where they oppose, it cancels",
                    "The result is a row of evenly spaced gaps: a comb filter",
                    "Flanger and chorus are both built from this"
                ],
                demo: nil,
                terms: [
                    G.cancel,
                    G.combFilter,
                    G.filter,
                    G.flanger,
                    G.chorus
                ],
                exercise: Exercise(
                    prompt: "Hold a note and bring TIME all the way down. The echo disappears, the gaps appear, and the sound goes hollow.",
                    visibleParams: [.delayTime, .delayFeedback],
                    basePatch: Patch([.delayMix: 0.6, .delayTime: 0.35, .delayFeedback: 0.55,
                                      .oscWave: 0.5, .cutoff: 0.9,
                                      .ampAttack: 0.01, .ampDecay: 0.3, .ampSustain: 0.9, .ampRelease: 0.25]),
                    visual: .comb,
                    tip: "Turn FEEDBACK up once the gaps appear. The deeper the gaps, the more hollow it sounds.",
                    controlsHint: "TIME down low is where an echo turns into a filter"
                )
            ),
            Lesson(
                id: "mfx4", title: "Many Arrivals Become a Room",
                concept: "Reverb is the same sound reaching you thousands of times, too close together to count.",
                theory: [
                    "In any real space you hear a sound twice over. First it comes straight to you. Then it comes again, having bounced off a wall, then off the floor, the ceiling, and everything in the room.",
                    "One bounce on its own would be an echo. But a room has surfaces everywhere, and every bounce bounces again. Within a fraction of a second there are thousands of arrivals, far too many and too close together to hear as separate events. They blur into a single wash of sound. That wash is reverb, which is short for reverberation.",
                    "SIZE is how far apart the walls are. A bigger space means the bounces travel further, so they arrive further apart and take longer to die away. That is why a cathedral rings for seconds and a bathroom does not.",
                    "MIX is how much of the bounced sound you hear against the straight one. This is what your ears use to judge distance. Mostly straight sound means the source is right in front of you. Mostly bounces means it is far away, at the other end of the room.",
                    "Look at the second picture. The tall white line is the sound arriving straight, and everything after it is the same sound coming back off a surface."
                ],
                takeaways: [
                    "Reverb is thousands of bounces arriving too close together to count",
                    "One bounce is an echo; a room full of them is reverb",
                    "Size is how far apart the walls are, which sets how long it rings",
                    "Mix is how far away the sound seems"
                ],
                demo: nil,
                terms: [
                    G.reverb,
                    G.bounce,
                    G.echo
                ],
                exercise: Exercise(
                    prompt: "Play a short note with MIX at zero, then bring it up. The sound stops being right in your ears and starts being somewhere. Then open SIZE.",
                    visibleParams: [.reverbMix, .reverb],
                    basePatch: Patch([.reverbMix: 0.0, .reverb: 0.5, .oscWave: 0.3, .cutoff: 0.75,
                                      .ampAttack: 0.01, .ampDecay: 0.25, .ampSustain: 0.0, .ampRelease: 0.25]),
                    visual: .room,
                    holdDefault: false,
                    tip: "Put MIX high and play one short note, then stop. What you can still hear is the room, not the note.",
                    controlsHint: "SIZE is how big the room is, MIX is how far away you are"
                )
            )
        ]
    )

    // MARK: Module - Designing Drums

    static let drums = Module(
        id: "mdr", title: "Designing Drums", subtitle: "Building a kit from nothing", accent: Theme.basics,
        lessons: [
            Lesson(
                id: "mdr1", title: "A Hit Is a Shape, Not a Sound",
                concept: "What makes something percussive is not what it is made of. It is how quickly it arrives and leaves.",
                theory: [
                    "Think about the difference between a violin and a drum. It is not really what they are made of. It is timing. The violin swells in and holds for as long as the bow keeps moving. The drum is at full volume the instant it is struck and then it is gone.",
                    "You already have the control for this. The envelope is the shape of a sound\'s loudness over time, and three of its settings are what make something a hit.",
                    "Attack is how long it takes to reach full volume. For a hit this must be zero: struck things are loud immediately, because the energy arrives all at once.",
                    "Sustain is the level it holds at while you keep the key down. For a hit this must also be zero. Nothing is feeding a drum after the stick has left it, so there is nothing to hold.",
                    "Decay is how long it takes to fall from full volume to that nothing. Short is a hit. Long is a note.",
                    "Set those three and any source at all becomes percussive. That is why this lesson comes before the kick, the hat and the snare: the shape is shared, and only the source changes between them."
                ],
                takeaways: [
                    "Percussive means instant attack, no sustain, and a short decay",
                    "Attack zero, because struck things are loud immediately",
                    "Sustain zero, because nothing keeps feeding a drum after the hit",
                    "The shape decides that it is a hit; the source decides which hit"
                ],
                demo: nil,
                terms: [
                    G.envelope,
                    G.attack,
                    G.sustain,
                    G.decay,
                    G.percussive
                ],
                exercise: Exercise(
                    prompt: "Pull DECAY down and SUSTAIN to zero. Watch the shape go straight up and straight back down, and hear the note turn into a hit.",
                    visibleParams: [.ampDecay, .ampSustain, .ampAttack],
                    basePatch: Patch([.ampAttack: 0.25, .ampDecay: 0.6, .ampSustain: 0.7, .ampRelease: 0.2,
                                      .oscWave: 0.35, .cutoff: 0.8]),
                    visual: .hitShape,
                    holdDefault: false,
                    tip: "Try it the other way too. Put ATTACK up and the same sound stops being a drum and becomes a pad.",
                    controlsHint: "Three settings turn any sound into a hit"
                )
            ),
            Lesson(
                id: "mdr2", title: "A Cymbal Is Noise With No Bottom",
                concept: "Take noise, throw away the low end, and cut it short. That is a hi-hat.",
                theory: [
                    "Two thin metal discs hitting each other. There is nothing in that sound you could hum, so there is no note in it, which tells you the source immediately: it has to be noise.",
                    "But raw noise has energy everywhere, including deep at the bottom, and a pair of small metal discs cannot produce deep sound. So the low end has to go.",
                    "The tool for that is a high-pass filter. High-pass means it lets the high frequencies pass through and blocks the low ones. It is the same filter you met before, working in the opposite direction: instead of keeping the bottom, it keeps the top.",
                    "Sweep the cutoff up and watch the picture. Everything below the dotted line is thrown away, and what is left is thin, bright, and metallic. Nothing has been added to make it sound like a cymbal. Things have only been taken away.",
                    "Then decay does the last job, and it is the only difference between the two hats every drum kit has. Very short is a closed hat. Let it ring on and it is an open one."
                ],
                takeaways: [
                    "A cymbal has no note in it, so noise is the right source",
                    "A high-pass filter keeps the highs and blocks the lows",
                    "A hat is made by taking away, not by adding",
                    "Decay length is the whole difference between a closed and an open hat"
                ],
                demo: nil,
                terms: [
                    G.highPass,
                    G.cutoff,
                    G.noise,
                    G.decay
                ],
                exercise: Exercise(
                    prompt: "Sweep CUTOFF up until only the thin bright part is left, then open DECAY to turn the closed hat into an open one.",
                    visibleParams: [.cutoff, .ampDecay],
                    basePatch: Patch([.noiseLevel: 1.0, .noiseColor: 0.0, .filterType: 0.33,
                                      .cutoff: 0.45, .resonance: 0.1,
                                      .ampAttack: 0.0, .ampDecay: 0.08, .ampSustain: 0.0, .ampRelease: 0.05]),
                    visual: .hatFilter,
                    keyboardRoot: 60,
                    holdDefault: false,
                    tip: "Any key gives the same hat, because there is no note in noise to change.",
                    controlsHint: "CUTOFF is where the bottom gets cut off, DECAY is how long it rings"
                )
            ),
            Lesson(
                id: "mdr3", title: "Two Sounds Can Share One Hit",
                concept: "A snare is a drum and a rattle happening at the same instant, and the balance between them is the sound.",
                theory: [
                    "A snare drum is really two instruments stacked on top of each other. There is the drum itself, a skin stretched over a shell, which has a real note in it, somewhere around two hundred vibrations a second. And stretched underneath that skin is a set of loose metal wires. When the skin is struck the wires jump and rattle, and a rattle has no note in it at all.",
                    "You have both sources already. The oscillator is the skin. The noise is the wires. This lesson is only about how much of each.",
                    "Mostly skin gives you a soft, round thud, closer to a tom than a snare. Mostly wires gives you a thin crack with no weight behind it, like a hand clap. The sound everyone recognises as a snare drum sits between the two, and finding that point by ear is the exercise.",
                    "This is worth more than one drum. Almost every sound you will ever build is two or three simple things arriving together, and the balance between them is what you are really designing."
                ],
                takeaways: [
                    "A snare is a skin with a note in it plus wires with no note in them",
                    "The oscillator is the skin, the noise is the wires",
                    "Too much noise loses the weight, too little loses the crack",
                    "Most sounds are a few simple things layered, balanced by ear"
                ],
                demo: nil,
                terms: [
                    G.oscillator,
                    G.noise,
                    G.layer
                ],
                exercise: Exercise(
                    prompt: "Play a low key and move NOISE across its range. Stop where the thud and the crack stop sounding like two things and start sounding like one drum.",
                    visibleParams: [.noiseLevel],
                    basePatch: Patch([.noiseLevel: 0.15, .noiseColor: 0.2, .oscWave: 0.2,
                                      .cutoff: 0.7, .resonance: 0.25,
                                      .ampAttack: 0.0, .ampDecay: 0.16, .ampSustain: 0.0, .ampRelease: 0.12]),
                    visual: .snareMix,
                    keyboardRoot: 36,
                    holdDefault: false,
                    tip: "Around two thirds noise is where most snares live. Trust your ear over the number.",
                    controlsHint: "One knob: how much of the hit is rattle instead of drum"
                )
            ),
            Lesson(
                id: "mdr4", title: "A Falling Pitch Sounds Struck",
                concept: "A kick drum is a low note whose pitch drops the instant it starts. That drop is the sound of being hit.",
                theory: [
                    "Hit a real bass drum and the skin is stretched tight for a fraction of a second before it relaxes. A tighter skin makes a higher note, so the pitch starts high and falls immediately to where it settles.",
                    "That fall lasts a few hundredths of a second and it is the entire reason a kick sounds struck instead of switched on. Take it away and you have a low hum. Put it back and your ear hears a beater hitting a skin.",
                    "To make the pitch fall on its own you need something that starts high and drops to nothing. You already have exactly that: the envelope. Point it at pitch instead of loudness, and the pitch traces out the same falling shape.",
                    "This is worth stopping on. In the Motion module the same connection, pointed at pitch, gave you vibrato. Nothing about the wiring has changed here. Only the speed has. Slow modulation is something you hear as movement; fast modulation is something you hear as a hit. Speed is what a modulation means.",
                    "DEPTH is how far the pitch falls, and DECAY is how long the fall takes. Underneath it all is a plain sine wave, because a kick is almost pure low end, which is what makes it something you feel rather than hear."
                ],
                takeaways: [
                    "The pitch drop at the start is what makes a kick sound struck",
                    "Pointing the envelope at pitch produces that drop automatically",
                    "The same routing that made vibrato makes a beater when it is fast enough",
                    "Depth is how far it falls, decay is how long it takes"
                ],
                demo: nil,
                terms: [
                    G.envelope,
                    G.vibrato,
                    G.modulation,
                    G.sineWave
                ],
                exercise: Exercise(
                    prompt: "Play the lowest keys. Move DEPTH to change how far the pitch falls, and DECAY to change how fast. Find the point where it stops sliding and starts sounding hit.",
                    visibleParams: [.lfoDepth, .ampDecay],
                    basePatch: Patch([.oscWave: 0.0, .cutoff: 0.45, .ampAttack: 0.0, .ampDecay: 0.3,
                                      .ampSustain: 0.0, .ampRelease: 0.2, .lfoDepth: 0.55, .drive: 0.2]),
                    visual: .pitchDrop,
                    showRouting: false,
                    initialRouting: Routing(source: .envelope, dest: .pitch),
                    keyboardRoot: 24,
                    showOctave: false,
                    holdDefault: false,
                    tip: "Too much depth and it whistles. Too little and it hums. The kick is in between.",
                    controlsHint: "DEPTH is how far the pitch falls, DECAY is how long the fall lasts"
                )
            )
        ]
    )

    // MARK: Module - Building a Patch

    static let building = Module(
        id: "mbp", title: "Building a Patch", subtitle: "Putting all of it together", accent: Theme.filter,
        lessons: [
            Lesson(
                id: "mbp1", title: "Low Sounds Need Room Made For Them",
                concept: "A bass has to be felt without covering everything else, and that is a question of what you take away.",
                theory: [
                    "A patch just means one complete sound: a source, a filter, a shape, and wherever you put it. This module builds four of them, and each one is really an argument about what a sound has to do in a piece of music.",
                    "A bass has the hardest job. It sits at the very bottom, where there is the least room and the most energy, so almost every decision is about staying out of the way of everything above it.",
                    "So the filter comes down. A bass rarely needs anything bright in it, and closing the filter keeps it from crowding the instruments sitting above. A little resonance right at the cutoff gives it definition without making it bright.",
                    "The shape stays short. Sustain low so it does not drone on, decay quick so each note has let go before the next one lands. Long low notes overlapping is the fastest way to turn music into mud.",
                    "One last trick, and it comes straight back to the gear module. Adding a little drive puts extra harmonics higher up, well above the note itself. A phone speaker cannot reproduce the low note at all, but it can reproduce those harmonics, and your ear fills in the missing note underneath. That is why a good bass still reads on a laptop."
                ],
                takeaways: [
                    "A bass fights for room at the bottom, so most choices are about taking away",
                    "Close the filter: a bass does not need the top",
                    "Keep it short, or overlapping notes turn to mud",
                    "Drive adds high harmonics that imply the low note on small speakers"
                ],
                demo: nil,
                terms: [
                    G.patch,
                    G.resonance,
                    G.cutoff,
                    G.harmonics,
                    G.drive
                ],
                exercise: Exercise(
                    prompt: "Play low. Close CUTOFF until it stops being bright, shorten DECAY so notes let go, then add DRIVE and listen on your phone speaker.",
                    visibleParams: [.cutoff, .ampDecay, .drive],
                    basePatch: Patch([.oscWave: 0.55, .cutoff: 0.75, .resonance: 0.25,
                                      .ampAttack: 0.0, .ampDecay: 0.5, .ampSustain: 0.25,
                                      .ampRelease: 0.15, .drive: 0.0]),
                    visual: .pathBass,
                    keyboardRoot: 24,
                    tip: "Check it on the worst speaker you own. If the note still reads there, the harmonics are doing their job.",
                    controlsHint: "Everything here is about staying low and out of the way"
                )
            ),
            Lesson(
                id: "mbp2", title: "Bright Sounds Carry Furthest",
                concept: "A lead has to be heard over everything else, which comes down to harmonics and movement.",
                theory: [
                    "A lead is the opposite problem to a bass. It is the part people follow, so it has to stay audible through everything else that is playing.",
                    "Brightness is the first tool. Start from a rich source, open the filter, and there are plenty of harmonics up where human hearing is most sensitive. That is why a saw-shaped wave is the traditional starting point for a lead: it has the most harmonics to work with.",
                    "Movement is the second, and it is the one people forget. A sound that never changes disappears into music no matter how loud it is, because your ear stops paying attention to anything that stays still. That is not a mixing problem, it is how attention works.",
                    "Two cheap kinds of movement. Detune slightly mistunes a second copy against the first so they drift in and out of step, which reads as width and life. And a slow, shallow vibrato keeps the pitch breathing rather than sitting frozen.",
                    "Sustain stays high, because a lead holds notes. This is the one patch where a long singing tail is the point rather than a problem."
                ],
                takeaways: [
                    "Brightness carries: a rich source and an open filter",
                    "A sound that never changes disappears, however loud it is",
                    "Detune gives width, slow vibrato gives life",
                    "Keep sustain high, because a lead holds its notes"
                ],
                demo: nil,
                terms: [
                    G.lead,
                    G.detune,
                    G.vibrato,
                    G.harmonics
                ],
                exercise: Exercise(
                    prompt: "Open CUTOFF until it cuts through, then add DETUNE for width. Stop as soon as it sounds wide rather than out of tune.",
                    visibleParams: [.cutoff, .detune],
                    basePatch: Patch([.oscWave: 0.65, .cutoff: 0.55, .resonance: 0.15, .detune: 0.0,
                                      .ampAttack: 0.03, .ampDecay: 0.3, .ampSustain: 0.85, .ampRelease: 0.3,
                                      .delayMix: 0.12, .delayTime: 0.35, .delayFeedback: 0.3]),
                    visual: .pathLead,
                    keyboardRoot: 60,
                    tip: "Play two notes together once DETUNE is up. Width is much easier to hear on a chord than on one note.",
                    controlsHint: "Bright and moving are the two things that make a lead carry"
                )
            ),
            Lesson(
                id: "mbp3", title: "Slow Shapes Fill Space",
                concept: "A pad is defined almost entirely by timing. Everything arrives late and leaves slowly.",
                theory: [
                    "A pad is background. Its job is to fill the space behind everything else without ever asking to be noticed, and it does that mostly through timing rather than through tone.",
                    "Attack is long, so notes fade in instead of announcing themselves. Nothing about a pad should have a moment where it starts.",
                    "Release is long, so notes carry on after you let go and overlap with whatever you play next. That overlap is the whole point: separate notes should sound like one continuous thing, and the release is what glues them.",
                    "Width comes from detune, and a pad takes far more of it than a lead would. Several slightly mistuned copies drifting against each other is what makes a pad sound large rather than loud.",
                    "Then reverb, generously. This is the one patch where a wash is the correct answer, because a pad is supposed to feel like a place rather than an instrument."
                ],
                takeaways: [
                    "Long attack and long release make notes overlap into one texture",
                    "The overlap is the sound, not a side effect",
                    "Heavy detune reads as width rather than as being out of tune",
                    "Reverb belongs here more than anywhere else"
                ],
                demo: nil,
                terms: [
                    G.pad,
                    G.attack,
                    G.release,
                    G.reverb
                ],
                exercise: Exercise(
                    prompt: "Lengthen ATTACK and RELEASE until notes blur into each other, then open MIX. Play a chord, let go, and start another before the first has finished.",
                    visibleParams: [.ampAttack, .ampRelease, .reverbMix],
                    basePatch: Patch([.oscWave: 0.4, .cutoff: 0.6, .resonance: 0.1, .detune: 0.4,
                                      .ampAttack: 0.08, .ampDecay: 0.5, .ampSustain: 0.8, .ampRelease: 0.2,
                                      .reverb: 0.7, .reverbMix: 0.1]),
                    visual: .pathPad,
                    keyboardRoot: 48,
                    tip: "Hold three keys at once. A pad is nearly always chords, because the overlap is what you are building.",
                    controlsHint: "Slow in, slow out, and plenty of room"
                )
            ),
            Lesson(
                id: "mbp4", title: "Build One Yourself",
                concept: "Every control at once, in the order that sound travels through them.",
                theory: [
                    "This is the last exercise and there is nothing new in it. Every knob you have met is in front of you at the same time, which is what a real synthesiser looks like when you open it up.",
                    "The order is what saves you. Decide what kind of thing it is with the shape: is this a hit, or a note you hold. Choose the source: a wave, noise, FM, or sync. Take away what you do not want with the filter. Add movement so it does not sit still. Then put it somewhere with delay and reverb.",
                    "That order is worth keeping, because most patches that go wrong went wrong by reaching for an effect to fix a problem in the source. No amount of reverb rescues a sound that was not interesting to start with.",
                    "Nothing here can break, and nothing is graded. Turn things to their extremes deliberately. The sounds you find by accident at the ends of the range are usually better than the ones you set out to make."
                ],
                takeaways: [
                    "Shape first, then source, then filter, then movement, then space",
                    "Effects place a sound, they do not rescue it",
                    "The extremes are where the useful accidents happen"
                ],
                demo: nil,
                terms: [
                    G.patch,
                    G.signalPath
                ],
                exercise: Exercise(
                    prompt: "No target. Work left to right along the chain and build something you like, taking it to the extremes on the way.",
                    visibleParams: [.oscWave, .noiseLevel, .fmAmount, .syncAmount,
                                    .cutoff, .resonance, .ampAttack, .ampDecay, .ampSustain, .ampRelease,
                                    .drive, .delayMix, .reverbMix, .detune],
                    basePatch: Patch([.oscWave: 0.35, .cutoff: 0.7, .resonance: 0.15,
                                      .ampAttack: 0.05, .ampDecay: 0.35, .ampSustain: 0.6, .ampRelease: 0.35]),
                    visual: .pathFree,
                    keyboardRoot: 48,
                    tip: "If you make something worth keeping, write the knob positions down. There is no save button yet.",
                    controlsHint: "Everything, all at once. This is the whole instrument"
                )
            )
        ]
    )

    // MARK: Module - Where Sound Plays

    static let playback = Module(
        id: "mp", title: "Where Sound Plays", subtitle: "Speakers, gear, and frequency range", accent: Theme.playback,
        lessons: [
            Lesson(
                id: "mpl1", title: "Not Every Speaker Plays Bass",
                concept: "The gear you listen on can only reproduce part of the sound. Small speakers lose the bass.",
                theory: [
                    "How low a device can go depends on physical size. Low notes are slow vibrations, and making them audible in open air means moving a lot of it. Only a big driver, a woofer or a subwoofer, can push that much air.",
                    "A tiny phone speaker cannot move enough air for deep bass, so it rolls the low end away. There is one exception to the size rule: sealed earbuds like AirPods sit inside your ear canal, where there is almost no air to move, so even a tiny driver can deliver deep bass. A tight seal on a tiny space beats a big driver in a big room.",
                    "One more thing before you try it: a note that falls outside a device's range does not go silent. The chart shows the note's fundamental, its lowest sine. The harmonics above it still play, so you hear a thinner version of the note, the outline without the body.",
                    "In the exercise, pick a device and the chart highlights the range it can reproduce. Play a note and a line shows where its fundamental sits. You will hear the real difference for yourself in the next lesson."
                ],
                takeaways: [
                    "Deep bass in open air needs a big driver moving a lot of air",
                    "Sealed earbuds are the exception: a tiny sealed space needs almost no air",
                    "Out-of-range notes lose their body but their harmonics keep them audible"
                ],
                demo: nil,
                terms: [G.driver, G.woofer, G.fundamental, G.harmonics, G.frequency],
                exercise: Exercise(
                    prompt: "Pick a device and play a low note. When the marker falls below the device's range, the note loses its body — the harmonics are what you still hear.",
                    visibleParams: [],
                    basePatch: Patch([.oscWave: 0.4, .cutoff: 0.85, .ampSustain: 0.95, .ampRelease: 0.3]),
                    visual: .equipment,
                    keyboardRoot: 36,
                    showOctave: true
                )
            ),
            Lesson(
                id: "mpl2", title: "Try Your Own Gear",
                concept: "Right now you are listening on one specific device. Connect another and hear it change.",
                theory: [
                    "Everything so far came out of whatever your phone is connected to right now. The app can see which output that is and roughly what it can reproduce.",
                    "To really feel the difference, play the two deepest sounds there are: a sub bass and a kick drum. These live at the very bottom of hearing, right where small speakers give up.",
                    "On your phone speaker they will be thin or almost silent. Switch to headphones, AirPods, or a real speaker and they come alive, deep and physical. Same sound, completely different experience."
                ],
                takeaways: ["Your current output has its own limited range", "Deep bass is where cheap and good gear differ most"],
                demo: nil,
                terms: [G.driver, G.fundamental],
                exercise: Exercise(
                    prompt: "Play the sub bass and the kick, then switch outputs. On small speakers they nearly vanish, on headphones or a big system you feel them.",
                    visibleParams: [],
                    basePatch: Patch(),
                    visual: .output,
                    showKeyboard: false,
                    showBassTest: true
                )
            ),
            Lesson(
                id: "mpl3", title: "The Right Setup",
                concept: "Different jobs need different gear. Matching them is part of the craft.",
                theory: [
                    "Because every device shows a different slice of sound, the setup you choose should fit the job in front of you.",
                    "When you design or mix sound yourself, this matters most of all. Work on studio monitors or accurate, professional headphones. They are built to tell you the truth, so what you make holds up everywhere else. Cheap or bass-boosted gear flatters the sound and lies to you, and your work will fall apart on other systems.",
                    "You still check on a phone speaker, because that is where many people will actually listen. A club needs subs to move air for a crowd, and a commute needs sealed earbuds. Different job, different tool."
                ],
                takeaways: [
                    "Design and mix on honest monitors or pro headphones",
                    "The right setup depends on the purpose"
                ],
                demo: nil,
                terms: [G.driver, G.spectrum],
                exercise: Exercise(
                    prompt: "Match each situation to the setup that fits it best.",
                    visibleParams: [],
                    basePatch: Patch(),
                    visual: .match,
                    showKeyboard: false
                )
            )
        ]
    )

    // MARK: Module 1 - Sound & Frequency

    static let frequency = Module(
        id: "m1", title: "Sound & Frequency", subtitle: "Start here: what sound really is", accent: Theme.basics,
        lessons: [
            Lesson(
                id: "m1l1", title: "What Sound Is",
                concept: "Sound is a vibration traveling through a medium like air or water. No medium, no sound.",
                theory: [
                    "Sound is a vibration moving through a medium. Something vibrates, that moves the molecules of the medium, and the disturbance travels outward until it reaches your ears.",
                    "Underwater you can still hear, because water carries the vibration; however, sound travels differently than it does in air. In the vacuum of space there is nothing to carry it, so there is complete silence.",
                    "In the exercise you will see that vibration on a display. A flat line means the medium is still and there is silence. A wiggle means it is vibrating, and you hear a tone."
                ],
                takeaways: ["Sound is a vibration traveling through a medium", "No medium, like a vacuum, means no sound"],
                demo: DemoScript(
                    duration: 5,
                    startPatch: Patch([.oscWave: 0, .cutoff: 0.95, .ampSustain: 0.9, .ampRelease: 0.4]),
                    notes: held(57, 4.5)
                ),
                terms: [G.medium, G.frequency, G.amplitude],
                exercise: Exercise(
                    prompt: "Tap a key to hold a note. The wiggling line is the medium vibrating.",
                    visibleParams: [],
                    basePatch: Patch([.oscWave: 0, .cutoff: 0.95, .ampSustain: 0.9, .ampRelease: 0.4]),
                    visual: .scope
                )
            ),
            Lesson(
                id: "m1l2", title: "Frequency",
                concept: "How many times per second the medium vibrates. Slow means low frequency, fast means a high frequency.",
                theory: [
                    "Frequency is how many times per second the medium vibrates. We measure it in hertz, written Hz. Ten vibrations per second is 10 Hz.",
                    "Slow vibrations sound 'low'. Fast vibrations sound 'high'. As you speed them up, the wiggling line packs together more tightly.",
                    "In the exercise, sweep the slider from slow to fast and listen to the sound climb."
                ],
                takeaways: ["Frequency is vibrations per second, measured in Hz", "Slower is lower, faster is higher"],
                demo: nil,
                terms: [G.frequency, G.pitch, G.cycle],
                exercise: Exercise(
                    prompt: "Sweep from slow, low vibrations up to fast, high ones. Watch the wave tighten as it rises.",
                    visibleParams: [],
                    basePatch: Patch(),
                    tone: ToneConfig(minHz: 20, maxHz: 2000, startNorm: 0.3, snap: false),
                    showKeyboard: false
                )
            ),
            Lesson(
                id: "m1l2b", title: "The Bee",
                concept: "A vibration is just something moving back and forth, fast. Speed it up and the pitch rises.",
                theory: [
                    "A speaker makes sound the same way a bee does: by moving something back and forth, fast. The bee beats its wings; a speaker pushes its cone out and pulls it back in. Each beat, each push, shoves the air and sends a vibration on its way.",
                    "How fast it moves is the frequency. A bee beats its wings around two hundred times a second, which is why you hear one steady buzz at a pitch, not separate flaps. Beat slower and the pitch drops; beat faster and it climbs.",
                    "In the exercise, drag the flap speed. Watch the wings beat faster and hear the buzz rise with them. It is the same idea behind every note a synth plays: something vibrating, and how fast it vibrates is the pitch."
                ],
                takeaways: [
                    "A vibration is something moving back and forth, fast",
                    "How fast it moves is the frequency, and that is the pitch"
                ],
                demo: nil,
                terms: [G.frequency, G.pitch],
                exercise: Exercise(
                    prompt: "Drag the flap speed. Faster wings, faster vibration, higher buzz.",
                    visibleParams: [],
                    basePatch: Patch(),
                    visual: .bee,
                    showKeyboard: false
                )
            ),
            Lesson(
                id: "m1l3", title: "Frequency Becomes Pitch",
                concept: "A steady, fast enough vibration is what we hear as a musical note.",
                theory: [
                    "When a vibration is steady and fast enough, your ear stops hearing separate vibrations and hears one clear musical note instead.",
                    "Every note has an exact frequency. For example, the note A above middle C vibrates 440 times per second, or 440 Hz. Double the frequency and you get the same note one octave higher.",
                    "This is the big idea: musical notes are just specific frequencies. In the exercise, sweep the slider and watch the note name land on each one."
                ],
                takeaways: ["A musical note is a specific frequency", "Doubling the frequency raises it one octave"],
                demo: nil,
                terms: [G.frequency, G.pitch, G.fundamental],
                exercise: Exercise(
                    prompt: "Sweep and watch the note name. Try both snapping modes below: the C major scale, or all twelve notes.",
                    visibleParams: [],
                    basePatch: Patch(),
                    tone: ToneConfig(minHz: 55, maxHz: 1046, startNorm: 0.4, snap: true),
                    showKeyboard: false
                )
            ),
            Lesson(
                id: "m1l4", title: "Amplitude",
                concept: "Amplitude is how tall the wave is, the size of the pressure swing it makes.",
                theory: [
                    "Amplitude is the height of the wave, which is how far the speaker cone is driven on each swing. A tall wave pushes the cone far out and pulls it far back, moving more air, which your ear hears as louder. A short wave barely nudges it. The flat centerline is the cone at rest, silence.",
                    "In the exercise, a knob sets the amplitude inside the app. Turn it up and the wave grows taller, turn it down and it shrinks. This is the app's own volume.",
                    "There is a second volume as well: your phone's. It sits at the very end of the chain and turns the whole output up or down. Raise your phone's volume now with the side buttons, then shape the wave with the app knob.",
                    "Two controls, one chain. The app sets how tall the wave is, your phone sets how much of it reaches the speaker."
                ],
                takeaways: [
                    "Amplitude is the height of the wave, the size of the pressure swing",
                    "A taller wave is louder, the flat centerline is silence",
                    "The app knob and your phone volume are two separate stages"
                ],
                demo: DemoScript(
                    duration: 6,
                    startPatch: Patch([.oscWave: 0, .cutoff: 0.95, .ampSustain: 0.3, .ampRelease: 0.3]),
                    lanes: [lane(.ampSustain, [(0, 0.3), (2.5, 0.95), (5.5, 0.4)])],
                    notes: held(52, 6)
                ),
                terms: [G.amplitude, G.loudness, G.waveform],
                exercise: Exercise(
                    prompt: "Raise your phone volume, then use Amplitude to make the wave taller and shorter.",
                    visibleParams: [.ampSustain],
                    basePatch: Patch([.oscWave: 0, .cutoff: 0.95, .ampSustain: 0.7, .ampRelease: 0.3]),
                    visual: .scope,
                    showSystemVolume: true,
                    tip: "On screen this height is really just a number, roughly between minus one and plus one. It travels out through a converter, an amplifier, and a speaker, and each stage scales it, which is why the same wave is quiet on a phone and huge on a club system.",
                    labels: [.ampSustain: "Amplitude"]
                )
            ),
            Lesson(
                id: "m1l4b", title: "Loudness",
                concept: "Loudness is how loud a sound actually seems to you, which is not the same as its amplitude.",
                theory: [
                    "Amplitude is the physical height of the wave. Loudness is what your ears make of it, how loud it truly seems.",
                    "Put another way: amplitude is a fact about the wave, loudness is the opinion your ears form about it. The very same wave can seem loud or quiet depending on its pitch.",
                    "Your ears are not equally sensitive to every pitch. Sounds in the middle range, roughly where the human voice sits, are easy to hear, while very low bass notes are much harder to pick up. That's why a bass note needs far more energy to sound just as loud as a voice-range note.",
                    "See it for yourself in the exercise. Sweep the tone: the amplitude stays exactly the same the whole way, yet the low notes sound much quieter than the mids. Same wave height, different loudness.",
                    "Interesting fact: in music mastering, loudness is not left vague. It is measured with a standard called LUFS, which is a model of how ears actually hear and gives loudness an exact number so tracks can be matched to a target. It is this same perceived loudness, turned into a precise measurement."
                ],
                takeaways: [
                    "Loudness is the strength of a sound as you perceive it",
                    "Your ears hear mids more easily than deep bass",
                    "In mastering, perceived loudness is measured precisely, in LUFS"
                ],
                demo: nil,
                terms: [G.loudness, G.amplitude],
                exercise: Exercise(
                    prompt: "Sweep from low to high. The amplitude never changes, but notice how much quieter the low notes seem.",
                    visibleParams: [],
                    basePatch: Patch(),
                    tone: ToneConfig(minHz: 30, maxHz: 4000, startNorm: 0.5, snap: false),
                    showKeyboard: false
                )
            ),
            Lesson(
                id: "m1l4c", title: "Amplitude vs Loudness",
                concept: "Putting it together: amplitude and volume are physical, loudness is what you perceive.",
                theory: [
                    "Amplitude is the size of the wave, how far it swings from its resting point. Volume is a control that scales that amplitude up or down on a given device. Amplitude is a physical property you can measure; volume is just a setting that changes it.",
                    "Loudness is how loud that ends up seeming to a listener, and it shifts with frequency, and even with how long a sound lasts.",
                    "This is why, to make bass feel as loud as the mids, you need far more amplitude down low. It is the reason sub-heavy club systems exist, and why engineers watch loudness, not just the height of the wave.",
                    "Play a low key, then a high key, at the same Amplitude. The high one sounds louder even though the wave is the same height. That gap is loudness."
                ],
                takeaways: [
                    "Amplitude and volume are the physical size of the wave",
                    "Loudness is the perceived strength, and it depends on frequency",
                    "Bass needs more amplitude to feel as loud as the mids"
                ],
                demo: nil,
                terms: [G.amplitude, G.loudness],
                exercise: Exercise(
                    prompt: "Play a low key, then a high key, at the same Amplitude. The high one sounds louder. Meaning loudness is not more volume, your ears just perceive it that way because they are more sensitive to some frequencies than others.",
                    visibleParams: [.ampSustain],
                    basePatch: Patch([.oscWave: 0, .cutoff: 0.95, .ampSustain: 0.8, .ampRelease: 0.3]),
                    visual: .scope,
                    keyboardRoot: 36,
                    labels: [.ampSustain: "Amplitude"]
                )
            ),
            Lesson(
                id: "m1l5", title: "Waveforms",
                concept: "The shape of the wave, its waveform, decides the character of the sound.",
                theory: [
                    "Two sounds can share the same frequency and loudness and still sound completely different. The difference is the shape of the wave, called its waveform.",
                    "First, how to read the wave display you will use in the exercise. Left to right is time, so you are watching the sound unfold. The flat centerline is the speaker at rest, silence.",
                    "Up and down is the speaker cone. The height tells the cone how far to push out or pull back at each instant: above the line it pushes out, below it pulls in, on the line it sits still. The cone pushing out squeezes the air in front of it, and pulling back leaves it thinner. That squeeze and thin is the sound.",
                    "And as you saw with amplitude, a taller wiggle means the cone travels further, a bigger push, louder. The waveform is something different: not how tall the wave is, but the shape of one full push and pull, repeated over and over.",
                    "Each basic shape has a character. A sine is smooth and pure, good for sub bass and soft, flute-like tones. A triangle is a little brighter but still mellow. A saw is rich and buzzy, the backbone of strings, brass, and big supersaw leads. A square is hollow and woody, used for clarinet-like tones and classic chiptune sounds.",
                    "In the exercise, tap a key, try each shape, and watch the wave change. Sharper shapes sound brighter."
                ],
                takeaways: [
                    "Left to right is time, up and down is the speaker cone pushing out and pulling in",
                    "The centerline is the cone at rest, a taller wiggle is louder",
                    "The waveform is the shape of one repeat, and it sets the tone"
                ],
                demo: DemoScript(
                    duration: 7,
                    startPatch: Patch([.oscWave: 0, .cutoff: 0.98, .ampSustain: 0.95, .ampRelease: 0.3]),
                    lanes: [lane(.oscWave, [(0.5, 0), (6, 1)])],
                    notes: held(50, 6.5)
                ),
                terms: [G.waveform, G.harmonics, G.timbre, G.sineWave],
                exercise: Exercise(
                    prompt: "Hold a key, then try each shape. Watch the wave change and hear the tone change.",
                    visibleParams: [.oscWave],
                    basePatch: Patch([.oscWave: 0, .cutoff: 0.98, .ampSustain: 0.95, .ampRelease: 0.3]),
                    visual: .scope,
                    wavePresets: true
                )
            ),
            Lesson(
                id: "m1l5b", title: "Built from Sines",
                concept: "Any repeating wave can be built by adding simple sine waves together.",
                theory: [
                    "Here is the surprise. Every shape you just heard, the triangle, the saw, the square, can be built out of nothing but sine waves added together.",
                    "Start with one sine at the note's pitch. Add a second sine that vibrates twice as fast at half the strength, and the shape bends. Keep adding faster, quieter sines and the wiggles pile up, creeping closer and closer to a sharp saw edge.",
                    "In the exercise, each faint line is one sine. The bright line is their sum, and that sum is what the speaker actually plays. Add sines one at a time, hold a key, and hear the tone grow brighter with every sine."
                ],
                takeaways: [
                    "Complex waves are sums of simple sine waves",
                    "Each added sine is faster and quieter than the last",
                    "More sines make a sharper shape and a brighter sound"
                ],
                demo: nil,
                terms: [G.sineWave, G.harmonics, G.waveform, G.spectrum],
                exercise: Exercise(
                    prompt: "Add sines one at a time and hold a key. Watch the sum sharpen and hear it brighten.",
                    visibleParams: [],
                    basePatch: Patch([.cutoff: 0.98, .ampSustain: 0.95, .ampRelease: 0.3]),
                    visual: .additive
                )
            ),
            Lesson(
                id: "m1l6", title: "Harmonics",
                concept: "A bright shape is really many sine waves, at different frequencies, stacked up.",
                theory: [
                    "You just built a wave out of sine waves by hand. Every sound the synth makes works the same way: each shape is secretly a stack of sine waves, and those hidden sine waves are called harmonics.",
                    "In the exercise, each bar is one of those sine waves. The tall bar on the left is the fundamental, the main pitch you hear. Each bar to its right is a harmonic at a higher frequency, a whole-number multiple of the fundamental. How tall a bar is shows how strong that harmonic is.",
                    "A pure sine has a single bar, only the fundamental, so it sounds plain. A saw or square stacks up many bars, which is why they sound bright and rich.",
                    "In the exercise, change the shape and watch the bars appear. More bars, and taller ones, means a brighter sound."
                ],
                takeaways: [
                    "Each bar is one sine wave hidden inside the sound",
                    "The left bar is the fundamental, the rest are higher harmonics",
                    "More and taller bars means a brighter tone"
                ],
                demo: DemoScript(
                    duration: 7,
                    startPatch: Patch([.oscWave: 0, .cutoff: 0.98, .ampSustain: 0.95, .ampRelease: 0.3]),
                    lanes: [lane(.oscWave, [(0.5, 0), (6, 1)])],
                    notes: held(45, 6.5)
                ),
                terms: [G.harmonics, G.harmonic, G.fundamental, G.timbre, G.spectrum],
                exercise: Exercise(
                    prompt: "Change the shape and watch the harmonics stack up. More bars means a brighter sound.",
                    visibleParams: [.oscWave],
                    basePatch: Patch([.oscWave: 0, .cutoff: 0.98, .ampSustain: 0.95, .ampRelease: 0.3]),
                    visual: .spectrum,
                    wavePresets: true
                )
            ),
            Lesson(
                id: "m1l7", title: "Two Notes and Beating",
                concept: "Two notes very close in pitch drift in and out of step, making the loudness pulse.",
                theory: [
                    "Play two vibrations that are almost, but not quite, the same pitch. Because they run at slightly different speeds, they slowly drift in and out of step with each other.",
                    "When their pushes line up they add together and the sound swells louder. When they oppose they cancel and it drops quieter. That steady rise and fall of loudness is called beating.",
                    "Detune is the tool that creates it. It splits one note into two copies and pushes them slightly apart in pitch. The further apart, the faster they drift, so the faster the beating. With no detune the two copies sit exactly together and the sound stays flat.",
                    "In the exercise, hold a key and raise Detune. The lower display shows the volume over time: it rises and falls. That pulse is the beating, and the top display shows the two waves combining."
                ],
                takeaways: [
                    "Two close pitches drift in and out of step",
                    "In step they add and swell, out of step they cancel and dip",
                    "Detune sets how far apart they are, which sets the beat speed"
                ],
                demo: DemoScript(
                    duration: 8,
                    startPatch: Patch([.oscWave: 0.3, .cutoff: 0.9, .detune: 0, .ampSustain: 0.95, .ampRelease: 0.3]),
                    lanes: [lane(.detune, [(0.5, 0), (7, 0.4)])],
                    notes: held(48, 7.5)
                ),
                terms: [G.beating, G.frequency, G.pitch],
                exercise: Exercise(
                    prompt: "Hold a key and raise Detune. Watch the volume pulse below. More detune, faster beating.",
                    visibleParams: [.detune],
                    basePatch: Patch([.oscWave: 0.3, .cutoff: 0.9, .detune: 0.1, .ampSustain: 0.95, .ampRelease: 0.3]),
                    visual: .beating,
                    controlsHint: "DETUNE splits your note into two close pitches. It creates the drift you are watching."
                )
            ),
            Lesson(
                id: "m1l8", title: "Detune",
                concept: "Detune splits your note into two copies and spreads them apart in pitch.",
                theory: [
                    "Detune takes the one note you play and produces two copies of it: one pushed slightly up in pitch, one slightly down. The knob sets how far apart the copies sit.",
                    "You already know what two close pitches do: they drift in and out of step, and the volume pulses. A small spread makes that drift slow, so the sound keeps gently moving. A large spread separates the copies enough that you begin to hear them as two different pitches.",
                    "In the exercise, the display shows the two copies and the wave they add up to. Move Detune from zero upward and listen to how the character changes at each amount. On a bright saw, a wide spread is the basis of the supersaw lead you hear across dance music."
                ],
                takeaways: ["Detune plays two copies of the note, spread apart in pitch", "The spread sets how fast they drift and how separate they sound"],
                demo: DemoScript(
                    duration: 7,
                    startPatch: Patch([.oscWave: 0.62, .cutoff: 0.9, .detune: 0, .ampSustain: 0.9, .ampRelease: 0.3]),
                    lanes: [lane(.detune, [(0.5, 0), (6, 0.7)])],
                    notes: held(48, 6.5)
                ),
                terms: [G.detune, G.beating, G.oscillator],
                exercise: Exercise(
                    prompt: "Hold a key and move Detune. The faint lines are the two copies; the bright line is what you hear.",
                    visibleParams: [.detune],
                    basePatch: Patch([.oscWave: 0.62, .cutoff: 0.9, .detune: 0.15, .ampSustain: 0.9, .ampRelease: 0.3]),
                    visual: .detune,
                    tip: "Producers automate Detune while a note plays, on pads, supersaws, and effects, for a rising, unstable sweep.",
                    controlsHint: "DETUNE sets how far apart the two copies sit."
                )
            )
        ]
    )

    // MARK: Module 2 - Subtractive

    static let subtractive = Module(
        id: "m2", title: "Subtractive", subtitle: "Shaping tone with filters", accent: Theme.filter,
        lessons: [
            Lesson(
                id: "m2l0", title: "Filters in the Real World",
                concept: "A low-pass filter is like closing a door on a room: it shuts out the highs first.",
                theory: [
                    "You have heard a filter a hundred times without knowing it. Stand outside a room with music playing and slowly close the door. The bright, crisp highs fade first, while the bass thumps straight through the wall.",
                    "That is exactly what a low-pass filter does. 'Low-pass' means it lets the low frequencies pass and holds the higher ones back. The more you close it, the lower it reaches, and the darker and more muffled the sound becomes.",
                    "In the exercise, music is playing on a speaker in the room. Drag the door: swing it open and the bright highs pour out; ease it shut and they fade, leaving just the low, muffled body of the sound."
                ],
                takeaways: [
                    "A low-pass filter passes the lows and holds back the highs",
                    "Closing it is like shutting a door: the highs go first"
                ],
                demo: nil,
                terms: [G.filter, G.subtractive, G.harmonics],
                exercise: Exercise(
                    prompt: "A beat is playing inside. Drag the door open and closed — open lets the highs through, shut muffles them.",
                    visibleParams: [],
                    basePatch: Patch([.oscWave: 0.6, .cutoff: 0.85, .resonance: 0.08, .ampAttack: 0.004, .ampDecay: 0.14, .ampSustain: 0.15, .ampRelease: 0.1]),
                    visual: .door,
                    showKeyboard: false
                )
            ),
            Lesson(
                id: "m2l1", title: "Cutoff",
                concept: "A low-pass filter removes the higher harmonics above a point you set.",
                theory: [
                    "You know now that a bright shape is a stack of harmonics. Subtractive synthesis starts with all of them and carves some away.",
                    "The low-pass filter keeps the low harmonics and removes the higher ones above its cutoff point. In the exercise, sweep the cutoff down and the tone gets darker as those harmonics disappear.",
                    "A saw shape is used here because it has plenty of harmonics for the filter to remove."
                ],
                takeaways: ["Low-pass keeps the low harmonics and removes the high ones", "Sweeping cutoff is the classic filter sound"],
                demo: DemoScript(
                    duration: 7,
                    startPatch: Patch([.oscWave: 0.66, .resonance: 0.12, .cutoff: 1, .ampSustain: 0.95]),
                    lanes: [lane(.cutoff, [(0.5, 1), (3.5, 0.08), (6.5, 0.9)])],
                    notes: held(45, 6.5)
                ),
                terms: [G.cutoff, G.filter, G.lowPass, G.harmonics],
                exercise: Exercise(
                    prompt: "Hold a key and sweep CUT down until the tone goes dark, then back up.",
                    visibleParams: [.cutoff, .resonance],
                    basePatch: Patch([.oscWave: 0.66, .resonance: 0.12, .cutoff: 0.8, .ampSustain: 0.95]),
                    visual: .filter
                )
            ),
            Lesson(
                id: "m2l2", title: "Resonance",
                concept: "Resonance boosts the harmonics sitting right at the cutoff.",
                theory: [
                    "You know the cutoff: harmonics above it are removed. Resonance adds one thing to that. It boosts the harmonics sitting right at the cutoff, making them louder than everything else in the sound.",
                    "On the graph, that boost is a bump right where the filter curve bends. More resonance makes the bump taller and narrower.",
                    "Push it far enough and the boosted harmonics stand out as a tone of their own, a whistle at the cutoff frequency. Sweep the cutoff and the whistle slides with it, through harmonic after harmonic. That sweep is a sound you will recognize from countless leads and basses."
                ],
                takeaways: [
                    "Resonance boosts a narrow band of harmonics at the cutoff",
                    "High resonance makes that band ring out as its own tone",
                    "Sweeping the cutoff slides the boosted band through the sound"
                ],
                demo: DemoScript(
                    duration: 7,
                    startPatch: Patch([.oscWave: 0.66, .cutoff: 0.5, .resonance: 0, .ampSustain: 0.95]),
                    lanes: [lane(.resonance, [(0.5, 0), (2.5, 1.0)]), lane(.cutoff, [(2.5, 0.6), (6.5, 0.12)])],
                    notes: held(40, 6.5)
                ),
                terms: [G.resonance, G.cutoff, G.filter],
                exercise: Exercise(
                    prompt: "Hold a key, raise RES to grow the peak, then sweep CUT. Hear the filter start to sing.",
                    visibleParams: [.resonance, .cutoff],
                    basePatch: Patch([.oscWave: 0.66, .cutoff: 0.5, .resonance: 0.6, .ampSustain: 0.95]),
                    visual: .filter
                )
            ),
            Lesson(
                id: "m2l3", title: "Filter Types",
                concept: "Low-pass, high-pass, band-pass, and notch each keep a different part of the sound.",
                theory: [
                    "The same filter can keep different parts of the sound. Low-pass keeps the low harmonics. High-pass keeps the high ones and thins the tone out. Band-pass keeps only a slice from the middle. Notch scoops the middle out.",
                    "Each has a job: high-pass to remove low mud, band-pass for telephone or wah tones, notch for a hollow, phaser-like sound.",
                    "In the exercise, step through TYPE and hear how the same note changes character."
                ],
                takeaways: ["The four types each keep a different band", "Filter choice shapes the whole feel"],
                demo: DemoScript(
                    duration: 8,
                    startPatch: Patch([.oscWave: 0.66, .cutoff: 0.55, .resonance: 0.35, .filterType: 0, .ampSustain: 0.95]),
                    lanes: [lane(.filterType, [(0, 0), (2, 0), (2.01, 0.34), (4, 0.34), (4.01, 0.67), (6, 0.67), (6.01, 1), (8, 1)])],
                    notes: held(48, 7.5)
                ),
                terms: [G.filter, G.lowPass, G.highPass, G.cutoff],
                exercise: Exercise(
                    prompt: "Hold a key and pick each filter type. Notice what each one removes.",
                    visibleParams: [.cutoff, .resonance],
                    basePatch: Patch([.oscWave: 0.66, .cutoff: 0.6, .resonance: 0.3, .ampSustain: 0.95]),
                    visual: .filter,
                    filterTypePicker: true
                )
            )
        ]
    )

    // MARK: Module 3 - The Shape

    static let shape = Module(
        id: "m3", title: "The Shape", subtitle: "Envelopes over time", accent: Theme.shape,
        lessons: [
            Lesson(
                id: "m3l0", title: "The Envelope",
                concept: "An envelope is a shape that plays out over a note's life. Point it at volume and it becomes the amplitude envelope.",
                theory: [
                    "An envelope is a shape that unfolds over the life of a single note. It begins the instant you press a key, travels a set path, and finishes when you let go. By itself it makes no sound; it is a contour, a set of instructions for how something should change over time.",
                    "What it does depends on where you point it. Point an envelope at pitch and the note bends up or down as it plays. Point it at the filter and the tone brightens or darkens over time. Point it at volume and the loudness rises and falls. That last one is what this whole module is about: the amplitude envelope, the shape of a note's loudness from silence, up, and back to silence.",
                    "Every note you have played so far snapped on at full volume and stayed there. Real sounds are not like that: a pluck jumps loud and fades, a pad swells in slowly. The amplitude envelope draws that. In the exercise, press and hold a key to start the note, then let go to release it, and watch the line, which is the note's volume over time. The lessons ahead shape each part of it."
                ],
                takeaways: [
                    "An envelope is a shape over time; what it does depends on where you point it",
                    "Pointed at volume it is the amplitude envelope, this module's subject"
                ],
                demo: nil,
                terms: [G.envelope, G.attack, G.decay, G.sustain, G.release],
                exercise: Exercise(
                    prompt: "Press and hold a key, then let go. The line is the note's volume over time.",
                    visibleParams: [],
                    basePatch: Patch([.oscWave: 0.4, .cutoff: 0.85, .ampAttack: 0.25, .ampDecay: 0.3, .ampSustain: 0.6, .ampRelease: 0.5]),
                    visual: .envelope,
                    holdDefault: false
                )
            ),
            Lesson(
                id: "m3l1", title: "Attack",
                concept: "Attack is how long a sound takes to fade in when a note starts.",
                theory: [
                    "So far a note has just switched on at full volume. Real sounds fade in and out instead. An envelope controls that change over the life of a note, and the first stage is attack.",
                    "Attack sets how long the sound takes to rise from silence to full volume. A fast attack is instant and percussive, like a pluck. A slow attack swells in gently, like a pad rising out of nowhere.",
                    "In the exercise, tap a key and raise ATTACK. Watch the first slope of the envelope get longer as the sound takes more time to arrive."
                ],
                takeaways: ["Attack is the fade-in time at the start of a note", "Fast attack is punchy, slow attack swells in"],
                demo: DemoScript(
                    duration: 8,
                    startPatch: Patch([.oscWave: 0.4, .cutoff: 0.85, .ampAttack: 0.02, .ampDecay: 0.1, .ampSustain: 0.85, .ampRelease: 0.25]),
                    lanes: [lane(.ampAttack, [(0, 0.02), (7.5, 0.75)])],
                    notes: pulses(52, count: 8, every: 1, dur: 0.7)
                ),
                terms: [G.attack, G.envelope, G.percussive],
                exercise: Exercise(
                    prompt: "Tap a key and raise ATTACK. Hear it change from an instant hit to a slow swell.",
                    visibleParams: [.ampAttack],
                    basePatch: Patch([.oscWave: 0.4, .cutoff: 0.85, .ampAttack: 0.06, .ampDecay: 0.1, .ampSustain: 0.85, .ampRelease: 0.25]),
                    visual: .envelope, holdDefault: false
                )
            ),
            Lesson(
                id: "m3l2", title: "Decay",
                concept: "Decay is how long the sound takes to fall from its peak down to the sustain level.",
                theory: [
                    "Right after the attack reaches the top, decay pulls the volume down to a lower holding level called sustain.",
                    "A short decay drops quickly, giving a sharp, plucky start. A long decay eases down slowly. For decay to be audible the sustain sits below the peak, so there is somewhere to fall to.",
                    "In the exercise, tap a key and change DECAY. Watch the second slope of the envelope, the fall right after the peak."
                ],
                takeaways: ["Decay is the fall from the peak down to the sustain level", "Short decay is plucky, long decay eases down"],
                demo: DemoScript(
                    duration: 8,
                    startPatch: Patch([.oscWave: 0.5, .cutoff: 0.85, .ampAttack: 0.02, .ampDecay: 0.1, .ampSustain: 0.35, .ampRelease: 0.2]),
                    lanes: [lane(.ampDecay, [(0, 0.1), (7.5, 0.7)])],
                    notes: pulses(50, count: 8, every: 1, dur: 0.8)
                ),
                terms: [G.decay, G.envelope, G.sustain],
                exercise: Exercise(
                    prompt: "Tap a key and change DECAY. Watch how fast it drops to the holding level.",
                    visibleParams: [.ampDecay],
                    basePatch: Patch([.oscWave: 0.5, .cutoff: 0.85, .ampAttack: 0.02, .ampDecay: 0.4, .ampSustain: 0.35, .ampRelease: 0.2]),
                    visual: .envelope, holdDefault: false
                )
            ),
            Lesson(
                id: "m3l3", title: "Sustain",
                concept: "Sustain is the volume the note holds at while you keep the key down.",
                theory: [
                    "After the attack and decay, the sound settles at the sustain level and stays there for as long as the note is held.",
                    "Sustain is a level, not a time. High sustain holds strong, like an organ. Low sustain fades most of the way down, leaving a short plucky front and a quiet tail.",
                    "In the exercise, hold a key and change SUSTAIN. Watch the flat holding section of the envelope move up and down."
                ],
                takeaways: ["Sustain is the held level, not a length of time", "High sustain holds like an organ, low sustain gives a pluck"],
                demo: DemoScript(
                    duration: 8,
                    startPatch: Patch([.oscWave: 0.5, .cutoff: 0.85, .ampAttack: 0.02, .ampDecay: 0.3, .ampSustain: 0.6, .ampRelease: 0.2]),
                    lanes: [lane(.ampSustain, [(0, 0.9), (7.5, 0.1)])],
                    notes: pulses(50, count: 5, every: 1.6, dur: 1.3)
                ),
                terms: [G.sustain, G.envelope, G.decay],
                exercise: Exercise(
                    prompt: "Hold a key, then change SUSTAIN. It sets how loud the note holds.",
                    visibleParams: [.ampSustain],
                    basePatch: Patch([.oscWave: 0.5, .cutoff: 0.85, .ampAttack: 0.02, .ampDecay: 0.3, .ampSustain: 0.6, .ampRelease: 0.2]),
                    visual: .envelope, holdDefault: false
                )
            ),
            Lesson(
                id: "m3l4", title: "Release",
                concept: "Release is how long the sound takes to fade out after you let go of a note.",
                theory: [
                    "When you lift your finger, the sound does not have to stop instantly. Release sets how long it takes to fade from the sustain level back to silence.",
                    "A short release cuts off cleanly. A long release lets the note ring out and blur into the next, which is how pads and ambient sounds breathe.",
                    "In the exercise, tap a key and let go, then change RELEASE. Watch the final slope of the envelope fall to nothing."
                ],
                takeaways: ["Release is the fade-out after you let go", "Long release lets notes ring out and overlap"],
                demo: DemoScript(
                    duration: 8,
                    startPatch: Patch([.oscWave: 0.4, .cutoff: 0.85, .ampAttack: 0.02, .ampDecay: 0.2, .ampSustain: 0.8, .ampRelease: 0.15]),
                    lanes: [lane(.ampRelease, [(0, 0.1), (7.5, 0.7)])],
                    notes: pulses(52, count: 8, every: 1, dur: 0.4)
                ),
                terms: [G.release, G.envelope, G.sustain],
                exercise: Exercise(
                    prompt: "Tap a key and let go, then change RELEASE. Hear the tail get longer or shorter.",
                    visibleParams: [.ampRelease],
                    basePatch: Patch([.oscWave: 0.4, .cutoff: 0.85, .ampAttack: 0.02, .ampDecay: 0.2, .ampSustain: 0.8, .ampRelease: 0.4]),
                    visual: .envelope, holdDefault: false
                )
            ),
            Lesson(
                id: "m3l5", title: "Hold",
                concept: "Hold keeps the sound pinned at full volume for a moment before decay begins.",
                theory: [
                    "Hold is an extra stage that sits between attack and decay. Once the attack reaches full volume, hold keeps it pinned there for a set time before the decay starts pulling it down.",
                    "One thing to know before trying it: the envelope only runs while the key is down. If you let go during the hold plateau, the sound skips ahead to the release. So to hear hold do its job, keep the key pressed until the fall.",
                    "In the exercise, press a key and keep it held. With HOLD at zero the volume falls right after the attack. Raise HOLD and a flat section appears at the top of the envelope: full volume, held, then the fall. Watch the dot ride the plateau."
                ],
                takeaways: [
                    "Hold pins the sound at full volume between attack and decay",
                    "Keep the key down through the plateau to hear it, or the release takes over"
                ],
                demo: DemoScript(
                    duration: 8,
                    startPatch: Patch([.oscWave: 0.5, .cutoff: 0.85, .ampAttack: 0.03, .ampHold: 0, .ampDecay: 0.3, .ampSustain: 0.15, .ampRelease: 0.2]),
                    lanes: [lane(.ampHold, [(0, 0), (7.5, 0.7)])],
                    notes: pulses(53, count: 8, every: 1, dur: 0.7)
                ),
                terms: [G.envelope, G.decay, G.sustain],
                exercise: Exercise(
                    prompt: "Press a key and keep it held. The sound sits at full volume for the HOLD time, then falls.",
                    visibleParams: [.ampHold],
                    basePatch: Patch([.oscWave: 0.5, .cutoff: 0.85, .ampAttack: 0.03, .ampHold: 0.4, .ampDecay: 0.25, .ampSustain: 0.15, .ampRelease: 0.2]),
                    visual: .envelope, holdDefault: false,
                    controlsHint: "HOLD is the length of the plateau at the top."
                )
            ),
            Lesson(
                id: "m3l6", title: "Delay",
                concept: "Delay makes the sound wait a moment before it even begins.",
                theory: [
                    "Delay here is a pause at the very start of the note, not the echo effect that shares the name. When you press a note, the sound waits for a set time before the attack begins.",
                    "On its own it is a small tool. It becomes more useful later, when you make electronic music and combine it with other ideas: layered sounds that enter one after another, or paired with an LFO so a sound's movement starts late. File it away for now.",
                    "In the exercise, tap a key and raise DELAY. A flat gap appears at the start of the envelope, before the rise."
                ],
                takeaways: ["Delay is a wait before the note begins", "Good for staggered, rhythmic entrances"],
                demo: DemoScript(
                    duration: 8,
                    startPatch: Patch([.oscWave: 0.4, .cutoff: 0.85, .ampDelay: 0, .ampAttack: 0.05, .ampDecay: 0.2, .ampSustain: 0.8, .ampRelease: 0.2]),
                    lanes: [lane(.ampDelay, [(0, 0), (7.5, 0.6)])],
                    notes: pulses(50, count: 8, every: 1, dur: 0.5)
                ),
                terms: [G.envelope, G.attack],
                exercise: Exercise(
                    prompt: "Tap a key and raise DELAY. The sound waits before it starts.",
                    visibleParams: [.ampDelay],
                    basePatch: Patch([.oscWave: 0.4, .cutoff: 0.85, .ampDelay: 0.35, .ampAttack: 0.05, .ampDecay: 0.2, .ampSustain: 0.8, .ampRelease: 0.2]),
                    visual: .envelope, holdDefault: false
                )
            ),
            Lesson(
                id: "m3l7", title: "The Full Envelope",
                concept: "Delay, attack, hold, decay, sustain, release, all together, shape the whole life of a note.",
                theory: [
                    "Now put them together. In order, a note can wait (delay), rise (attack), sit at the top (hold), fall (decay), hold steady (sustain), and fade out (release).",
                    "That full shape is called an envelope, and it turns one raw tone into a pluck, a pad, a stab, or a swell. The CURVE knob bends every slope from a straight line into a more natural curve.",
                    "In the exercise, play with all of them at once and design a shape you like. Watch the whole envelope change as you go."
                ],
                takeaways: [
                    "The full envelope is delay, attack, hold, decay, sustain, release",
                    "Curve bends the slopes from straight to natural",
                    "Together they turn one tone into a pluck, pad, stab, or swell"
                ],
                demo: nil,
                terms: [G.envelope, G.attack, G.decay, G.sustain, G.release, G.percussive],
                exercise: Exercise(
                    prompt: "Shape the whole envelope. Try a slow pad, a punchy pluck, or a delayed stab.",
                    visibleParams: [.ampDelay, .ampAttack, .ampHold, .ampDecay, .ampSustain, .ampRelease, .ampCurve],
                    basePatch: Patch([.oscWave: 0.5, .cutoff: 0.85, .ampAttack: 0.06, .ampDecay: 0.3, .ampSustain: 0.6, .ampRelease: 0.35]),
                    visual: .envelope, holdDefault: false,
                    controlsHint: "One knob per stage, in note order: delay, attack, hold, decay, sustain, release. Curve bends the slopes."
                )
            )
        ]
    )

    // MARK: Module 4 - Motion

    static let motion = Module(
        id: "m4", title: "Motion", subtitle: "Modulation and the mod matrix", accent: Theme.motion,
        lessons: [
            Lesson(
                id: "m4l1", title: "The LFO",
                concept: "A slow, looping shape you point at a knob to make it move on its own.",
                theory: [
                    "A wave that repeats fast enough makes a tone. Slow that same looping shape right down and it is too slow to hear as a pitch. Instead of making sound, it can move another control up and down, over and over.",
                    "That slow looping shape is called an LFO. In the exercise it is pointed at the volume, so the sound gets louder and quieter by itself, over and over, with no help from you. RATE sets how fast it loops, DEPTH sets how far it moves, and SHAPE sets the wave it traces.",
                    "Change the DEST to send the same LFO somewhere else, like the pitch or the filter. Pointing a source at a destination like this is called routing, and the same idea repeats across the whole synth."
                ],
                takeaways: ["An LFO is a shape too slow to hear, used to move other controls", "Rate, depth, shape, and destination describe any modulation"],
                demo: DemoScript(
                    duration: 7,
                    startPatch: Patch([.oscWave: 0.3, .cutoff: 0.85, .lfoDepth: 0.8, .lfoRate: 0.4, .ampSustain: 0.95]),
                    routing: Routing(source: .lfo, dest: .amplitude),
                    lanes: [lane(.lfoRate, [(0.5, 0.35), (6.5, 0.7)])],
                    notes: held(48, 6.5)
                ),
                terms: [G.lfo, G.modulation, G.oscillator, G.frequency],
                exercise: Exercise(
                    prompt: "Hold a key and hear the volume pulse on its own. Change RATE and DEPTH, then repoint DEST.",
                    visibleParams: [.lfoRate, .lfoDepth, .lfoShape],
                    basePatch: Patch([.oscWave: 0.3, .cutoff: 0.85, .lfoDepth: 0.8, .lfoRate: 0.5, .ampSustain: 0.95]),
                    visual: .lfo,
                    showRouting: true,
                    initialRouting: Routing(source: .lfo, dest: .amplitude),
                    allowedSources: [.lfo]
                )
            ),
            Lesson(
                id: "m4l2", title: "Vibrato",
                concept: "An LFO pointed at pitch, the same waver singers and guitarists add by hand.",
                theory: [
                    "Point a gentle LFO at pitch and the note wavers slightly higher and lower, over and over. That is vibrato.",
                    "Any rate of pitch movement counts as vibrato; the technique has no strict boundary. What changes is how it reads. Singers and players naturally sit around five to seven wavers per second with a small depth. Much slower and the pitch reads as drifting; much faster and it turns into a buzzing warble; deeper and it reads as a pitch wobble rather than a waver.",
                    "In the exercise you have a clean, sustained tone, so the pitch movement is easy to hear. Dial RATE into that five-to-seven range and it will read as vibrato immediately."
                ],
                takeaways: ["An LFO on pitch is vibrato, at any rate", "Around 5–7 Hz with small depth it reads like a singer's vibrato"],
                demo: DemoScript(
                    duration: 6,
                    startPatch: Patch([.oscWave: 0.12, .cutoff: 0.9, .detune: 0, .lfoDepth: 0, .lfoRate: 0.7, .ampSustain: 0.95]),
                    routing: Routing(source: .lfo, dest: .pitch),
                    lanes: [lane(.lfoDepth, [(0.5, 0), (5.5, 0.3)])],
                    notes: held(60, 5.5)
                ),
                terms: [G.vibrato, G.lfo, G.modulation, G.pitch],
                exercise: Exercise(
                    prompt: "Hold a key and dial in a vibrato: small DEPTH, RATE around 5–7 Hz.",
                    visibleParams: [.lfoRate, .lfoDepth],
                    basePatch: Patch([.oscWave: 0.12, .cutoff: 0.9, .detune: 0, .lfoDepth: 0.25, .lfoRate: 0.7, .ampSustain: 0.95]),
                    visual: .lfo,
                    initialRouting: Routing(source: .lfo, dest: .pitch)
                )
            ),
            Lesson(
                id: "m4l3", title: "Tremolo",
                concept: "An LFO pointed at amplitude, a steady pulsing of the volume.",
                theory: [
                    "Send the same LFO to amplitude instead and the volume rises and falls over and over. That is tremolo. Note the word: the LFO moves the amplitude, the physical wave height. The pulsing loudness is what your ears make of it, the same distinction you met back in the loudness lesson.",
                    "A slow tremolo breathes. A fast one chops the sound into a rhythm. A square LFO shape turns it into a hard on and off gate.",
                    "It is the same LFO, pointed at a new place. The pattern of modulation repeats across the whole synth."
                ],
                takeaways: ["An LFO on amplitude is tremolo", "Shape and rate turn it from breathing to chopping"],
                demo: DemoScript(
                    duration: 6,
                    startPatch: Patch([.oscWave: 0.3, .cutoff: 0.85, .lfoDepth: 0, .lfoRate: 0.45, .ampSustain: 0.95]),
                    routing: Routing(source: .lfo, dest: .amplitude),
                    lanes: [lane(.lfoDepth, [(0.5, 0), (5.5, 0.8)])],
                    notes: held(53, 5.5)
                ),
                terms: [G.tremolo, G.lfo, G.modulation, G.amplitude],
                exercise: Exercise(
                    prompt: "Hold a key. Make it breathe, then speed RATE up until it chops.",
                    visibleParams: [.lfoRate, .lfoDepth, .lfoShape],
                    basePatch: Patch([.oscWave: 0.3, .cutoff: 0.85, .lfoDepth: 0.5, .lfoRate: 0.45, .ampSustain: 0.95]),
                    visual: .lfo,
                    initialRouting: Routing(source: .lfo, dest: .amplitude)
                )
            ),
            Lesson(
                id: "m4l4", title: "Filter Wobble",
                concept: "The bass music move: an LFO sweeping the filter in rhythm.",
                theory: [
                    "Point the LFO at cutoff with real depth and some resonance and you get the rhythmic filter wobble at the heart of bass music.",
                    "Slow it for a lazy sweep, speed it for a growl. Change SHAPE to swap a smooth sweep for a jagged one.",
                    "You have now sent one LFO to pitch, to loudness, and to cutoff. That proves modulation is a routing you choose, not a fixed feature."
                ],
                takeaways: ["An LFO on cutoff is the classic wobble", "Depth, resonance, and rate shape the growl"],
                demo: DemoScript(
                    duration: 8,
                    startPatch: Patch([.oscWave: 0.72, .cutoff: 0.45, .resonance: 0.4, .lfoDepth: 0.7, .lfoRate: 0.5, .ampSustain: 0.95]),
                    routing: Routing(source: .lfo, dest: .cutoff),
                    lanes: [lane(.lfoRate, [(0.5, 0.5), (7.5, 0.8)])],
                    notes: held(36, 7.5)
                ),
                terms: [G.modulation, G.lfo, G.cutoff, G.filter],
                exercise: Exercise(
                    prompt: "Hold a low key and design a wobble bass with RATE, DEPTH, and SHAPE.",
                    visibleParams: [.lfoRate, .lfoDepth, .lfoShape],
                    basePatch: Patch([.oscWave: 0.72, .cutoff: 0.45, .resonance: 0.4, .lfoDepth: 0.7, .lfoRate: 0.3, .ampSustain: 0.95]),
                    visual: .lfo,
                    initialRouting: Routing(source: .lfo, dest: .cutoff)
                )
            )
        ]
    )
}
