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

    static let course = Course(
        id: "foundations",
        title: "Sound Design Foundations",
        subtitle: "Learn synthesis from the ground up, by turning real knobs.",
        modules: [frequency, playback, subtractive, shape, motion]
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
