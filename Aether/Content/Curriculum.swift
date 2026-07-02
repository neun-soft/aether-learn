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
                    "How low a device can go depends on physical size. Low notes are long, slow vibrations that move a lot of air, and only a big driver, a woofer or a subwoofer, can push that much air.",
                    "A tiny phone speaker cannot move enough air for deep bass, so it rolls the low end away. Bigger drivers, in headphones, in studio monitors, or in a club rig with subs, reach lower and lower.",
                    "Pick a device below and the chart highlights the range it can reproduce. Play a note and a line shows where it sits, so you can see when a low note falls below a small speaker's reach. You will hear the real difference for yourself in the next lesson."
                ],
                takeaways: ["Low frequencies need to move a lot of air", "Only big drivers, woofers and subs, reproduce deep bass"],
                demo: nil,
                exercise: Exercise(
                    prompt: "Pick a device to highlight its range. Play a note and watch where it lands. A low note can fall below what a small speaker can reach.",
                    visibleParams: [],
                    basePatch: Patch([.oscWave: 0.4, .cutoff: 0.85, .ampSustain: 0.95, .ampRelease: 0.3]),
                    visual: .equipment,
                    keyboardRoot: 36,
                    showOctave: true,
                    holdDefault: false
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
                    "When you design or mix sound yourself, this matters most of all. Work on studio monitors or accurate, professional headphones, like the Audio-Technica studio range. They are built to tell you the truth, so what you make holds up everywhere else. Cheap or bass-boosted gear flatters the sound and lies to you, and your work will fall apart on other systems.",
                    "You still check on a phone speaker, because that is where many people will actually listen. A club needs subs to move air for a crowd, and a commute needs sealed earbuds. Different job, different tool.",
                    "Matching sound to a space is a whole field of its own. Every room, venue, and pair of headphones has its own acoustics, and shaping sound for each one is why sound engineering exists. This app is only the first step into it."
                ],
                takeaways: [
                    "Design and mix on honest monitors or pro headphones",
                    "The right setup depends on the purpose",
                    "Shaping sound for a space is what sound engineering is"
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
                    "Sound is a vibration moving through a medium. Something vibrates, that shakes the molecules of the air or water around it, and the disturbance travels outward until it reaches your ears.",
                    "The medium is what matters. Underwater you still hear, because water carries the vibration. In the vacuum of space there is nothing to carry it, so there is complete silence.",
                    "The display shows that vibration. A flat line means the medium is still and there is silence. A wiggle means it is vibrating, and you hear a tone."
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
                concept: "How many times per second the medium vibrates. Slow is low, fast is high.",
                theory: [
                    "Frequency is how many times per second the medium vibrates. We measure it in hertz, written Hz. Ten vibrations per second is 10 Hz.",
                    "Slow vibrations sound low. Fast vibrations sound high. As you speed them up, the wiggling line packs together more tightly.",
                    "Sweep the slider from slow to fast and listen to the sound climb."
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
                id: "m1l3", title: "Frequency Becomes Pitch",
                concept: "A steady, fast enough vibration is what we hear as a musical note.",
                theory: [
                    "When a vibration is steady and fast enough, your ear stops hearing separate vibrations and hears one clear musical note instead.",
                    "Every note has an exact frequency. The note A above middle C vibrates 440 times per second, or 440 Hz. Double the frequency and you get the same note one octave higher.",
                    "This is the big idea: musical notes are just specific frequencies. Sweep the slider and watch the note name land on each one."
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
                    "Amplitude is the height of the wave, which is how far the speaker cone is driven on each swing. A tall wave pushes the cone far out and pulls it far back, moving a lot of air, which your ear hears as loud. A short wave barely nudges it, quiet. The flat centerline is the cone at rest, silence.",
                    "The knob below sets the amplitude inside the app. Turn it up and the wave grows taller, turn it down and it shrinks. This is the app's own volume.",
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
                    tip: "On screen this height is really just a number, roughly between minus one and plus one. It is not real loudness yet. It travels out through a converter, an amplifier, and a speaker, and each stage scales it, which is why the same wave is quiet on a phone and huge on a club system.",
                    labels: [.ampSustain: "Amplitude"]
                )
            ),
            Lesson(
                id: "m1l4b", title: "Loudness",
                concept: "Loudness is how loud a sound actually seems to you, which is not the same as its amplitude.",
                theory: [
                    "Amplitude is the physical height of the wave. Loudness is what your ears make of it, how loud it truly seems.",
                    "Put another way: amplitude is a fact about the wave, loudness is the opinion your ears form about it. The very same wave can seem loud or quiet depending on its pitch.",
                    "The reason is that your ears are not equally sensitive to every frequency. They pick up mid frequencies easily and deep bass poorly, so a low note has to move a lot more air to feel as loud as a mid one.",
                    "See it for yourself. Sweep the tone below: the amplitude stays exactly the same the whole way, yet the low notes sound much quieter than the mids. Same wave height, different loudness.",
                    "One heads-up for later: in music mastering, loudness is not left vague. It is measured with a standard called LUFS, which models how ears actually hear and gives loudness an exact number so tracks can be matched to a target. It is this same perceived loudness, turned into a precise measurement."
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
                    "Amplitude is the height of the wave. Volume is the control that scales it. Both are physical and can be measured.",
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
                    "First, read the display properly. Left to right is time, so you are watching the sound unfold. The flat centerline is the speaker at rest, silence.",
                    "Up and down is the speaker cone. The height tells the cone how far to push out or pull back at each instant: above the line it pushes out, below it pulls in, on the line it sits still. You are not moving air directly, you are moving the cone, and the cone shoving out squeezes the air in front of it while pulling back leaves it thinner. That squeeze and thin is the sound. A taller wiggle means the cone travels further, a bigger push your ear hears as louder. The waveform is the shape of one full push and pull, repeated over and over.",
                    "Each basic shape has a character. A sine is smooth and pure, good for sub bass and soft, flute-like tones. A triangle is a little brighter but still mellow. A saw is rich and buzzy, the backbone of strings, brass, and big supersaw leads. A square is hollow and woody, used for clarinet-like tones and classic chiptune sounds.",
                    "Tap a key, try each shape, and watch the display. Sharper shapes carry more harmonics and sound brighter."
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
                id: "m1l6", title: "Harmonics",
                concept: "A bright shape is really many sine waves, at different frequencies, stacked up.",
                theory: [
                    "Here is the surprise. Every complex shape is secretly a stack of simple sine waves added together. Those hidden sine waves are called harmonics.",
                    "Each bar below is one of those sine waves. The tall bar on the left is the fundamental, the main pitch you hear. Each bar to its right is a harmonic at a higher frequency, a whole-number multiple of the fundamental. How tall a bar is shows how strong that harmonic is.",
                    "A pure sine has a single bar, only the fundamental, so it sounds plain. A saw or square stacks up many bars, which is why they sound bright and rich.",
                    "Change the shape and watch the bars appear. More bars, and taller ones, means a brighter sound."
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
                    "Hold a key and raise Detune. Watch the lower display, the loudness over time: it rises and falls. That pulse is the beating, and the top display shows the two waves combining."
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
                    prompt: "Hold a key and raise Detune. Watch the loudness pulse below. More detune, faster beating.",
                    visibleParams: [.detune],
                    basePatch: Patch([.oscWave: 0.3, .cutoff: 0.9, .detune: 0.1, .ampSustain: 0.95, .ampRelease: 0.3]),
                    visual: .beating
                )
            ),
            Lesson(
                id: "m1l8", title: "Detune",
                concept: "A little detune adds width. A lot is not wrong, it is a sound of its own.",
                theory: [
                    "Beating is not just an oddity, it is a tool. A small amount of detune keeps a sound gently moving, which makes it feel wide and alive instead of flat and static.",
                    "Push it far and it tips into sounding out of tune, but that is not a mistake. On a bright saw it becomes the huge supersaw lead of dance music, and pushed harder it becomes a wild, unstable effect. Out of tune is a color you can reach for on purpose.",
                    "There is no single right amount. Move Detune around, from a subtle shimmer to a seasick wobble, and keep whatever sounds good to you."
                ],
                takeaways: ["A little detune adds width and life", "Out of tune is not wrong, it is a creative tool"],
                demo: DemoScript(
                    duration: 7,
                    startPatch: Patch([.oscWave: 0.62, .cutoff: 0.9, .detune: 0, .ampSustain: 0.9, .ampRelease: 0.3]),
                    lanes: [lane(.detune, [(0.5, 0), (6, 0.7)])],
                    notes: held(48, 6.5)
                ),
                exercise: Exercise(
                    prompt: "Move Detune anywhere from a subtle shimmer to a wild wobble. There is no wrong answer.",
                    visibleParams: [.detune, .oscWave],
                    basePatch: Patch([.oscWave: 0.62, .cutoff: 0.9, .detune: 0.15, .ampSustain: 0.9, .ampRelease: 0.3]),
                    visual: .scope,
                    tip: "Idea: automate Detune while a note plays for a rising, unstable sweep. Producers reach for it constantly on pads, supersaws, and effects. Trust your ears, not the tuning."
                )
            )
        ]
    )

    // MARK: Module 2 - Subtractive

    static let subtractive = Module(
        id: "m2", title: "Subtractive", subtitle: "Shaping tone with filters", accent: Theme.filter,
        lessons: [
            Lesson(
                id: "m2l1", title: "Cutoff",
                concept: "A low-pass filter removes the faster harmonics above a point you set.",
                theory: [
                    "You know now that a bright shape is a stack of harmonics. Subtractive synthesis starts with all of them and carves some away.",
                    "The low-pass filter keeps the low harmonics and removes the faster ones above its cutoff point. Sweep the cutoff down and the tone gets darker as those harmonics disappear from the display.",
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
                concept: "Resonance lifts a narrow band right at the cutoff, adding a sharp peak that can ring and whistle.",
                theory: [
                    "The cutoff decides where the filter starts removing sound. Resonance decides what happens right at that point.",
                    "Turn it up and the filter boosts a thin slice of frequencies exactly at the cutoff, making them much louder than everything around them. On the graph you see it as a sharp spike rising right at the cutoff line.",
                    "Another way to picture it: resonance makes the filter emphasize, or ring at, one frequency. A little gives a vocal, expressive edge, as if the sound is talking. A lot makes that spike so strong the filter almost plays a note of its own, a clear whistle sitting at the cutoff.",
                    "Raise RES to grow the peak, then sweep CUT to slide that peak up and down through the sound. That sweeping whistle is the singing filter behind countless leads and basses."
                ],
                takeaways: [
                    "Resonance is a loud, narrow peak right at the cutoff",
                    "It makes the filter ring, adding a vocal edge or a whistle",
                    "Sweeping the cutoff slides the peak, the classic filter sweep"
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
                    "Step through TYPE and hear how the same note changes character."
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
                id: "m3l1", title: "Attack",
                concept: "Attack is how long a sound takes to fade in when a note starts.",
                theory: [
                    "So far a note has just switched on at full volume. Real sounds fade in and out instead. An envelope controls that change over the life of a note, and the first stage is attack.",
                    "Attack sets how long the sound takes to rise from silence to full volume. A fast attack is instant and percussive, like a pluck. A slow attack swells in gently, like a pad rising out of nowhere.",
                    "Tap a key and raise ATTACK. Watch the first slope of the envelope get longer as the sound takes more time to arrive."
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
                    "Tap a key and change DECAY. Watch the second slope of the envelope, the fall right after the peak."
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
                    "Hold a key and change SUSTAIN. Watch the flat holding section of the envelope move up and down."
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
                    "Tap a key and let go, then change RELEASE. Watch the final slope of the envelope fall to nothing."
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
                    "Hold is an extra stage that sits between attack and decay. It keeps the sound at full volume for a set time before it starts to fall.",
                    "This is the piece many simple synths skip. It creates a deliberate plateau at the top, great for punchy plucks and stabs that need a moment of full body first.",
                    "Tap a key and raise HOLD. Watch a flat section appear at the very top of the envelope, before the fall."
                ],
                takeaways: ["Hold is a plateau at full volume before decay", "It adds punch and body to the start of a sound"],
                demo: DemoScript(
                    duration: 8,
                    startPatch: Patch([.oscWave: 0.5, .cutoff: 0.85, .ampAttack: 0.03, .ampHold: 0, .ampDecay: 0.3, .ampSustain: 0.15, .ampRelease: 0.2]),
                    lanes: [lane(.ampHold, [(0, 0), (7.5, 0.7)])],
                    notes: pulses(53, count: 8, every: 1, dur: 0.7)
                ),
                exercise: Exercise(
                    prompt: "Tap a key and raise HOLD. A flat plateau appears at the top before the sound falls.",
                    visibleParams: [.ampHold],
                    basePatch: Patch([.oscWave: 0.5, .cutoff: 0.85, .ampAttack: 0.03, .ampHold: 0.4, .ampDecay: 0.3, .ampSustain: 0.15, .ampRelease: 0.2]),
                    visual: .envelope, holdDefault: false
                )
            ),
            Lesson(
                id: "m3l6", title: "Delay",
                concept: "Delay makes the sound wait a moment before it even begins.",
                theory: [
                    "Delay is a pause at the very start. When you press a note, the sound waits for a set time before the attack begins.",
                    "It is useful for staggered, rhythmic sounds, or for layering, so one part comes in a beat after another.",
                    "Tap a key and raise DELAY. Watch a flat gap appear at the start of the envelope, before the rise."
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
                    "Play with all of them at once and design a shape you like. Watch the whole envelope move on the display as you go."
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
                    visual: .envelope, holdDefault: false
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
                    "An oscillator that vibrates fast enough makes a tone. Slow that same looping shape right down and it is too slow to hear as a pitch. Instead of making sound, it can move another control up and down, over and over.",
                    "That slow looping shape is called an LFO. Here it is pointed at the volume, so the sound gets louder and quieter by itself, over and over, with no help from you. RATE sets how fast it loops, DEPTH sets how far it moves, and SHAPE sets the wave it traces.",
                    "Change the DEST to send the same LFO somewhere else, like the pitch or the filter. This picker is the mod matrix in miniature."
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
                    "It works best on a clean, sustained tone, which is what you have here, so the pitch movement is easy to hear. Keep the depth small and the rate musical: too much depth sounds seasick, too fast sounds like a warble.",
                    "Vibrato is the clearest example of modulation you already know from real instruments and singers."
                ],
                takeaways: ["An LFO on pitch is vibrato", "It reads clearest on a clean, held tone"],
                demo: DemoScript(
                    duration: 6,
                    startPatch: Patch([.oscWave: 0.12, .cutoff: 0.9, .detune: 0, .lfoDepth: 0, .lfoRate: 0.7, .ampSustain: 0.95]),
                    routing: Routing(source: .lfo, dest: .pitch),
                    lanes: [lane(.lfoDepth, [(0.5, 0), (5.5, 0.3)])],
                    notes: held(60, 5.5)
                ),
                exercise: Exercise(
                    prompt: "Hold a key and dial in a natural vibrato with a small DEPTH and a musical RATE.",
                    visibleParams: [.lfoRate, .lfoDepth],
                    basePatch: Patch([.oscWave: 0.12, .cutoff: 0.9, .detune: 0, .lfoDepth: 0.25, .lfoRate: 0.7, .ampSustain: 0.95]),
                    visual: .lfo,
                    initialRouting: Routing(source: .lfo, dest: .pitch)
                )
            ),
            Lesson(
                id: "m4l3", title: "Tremolo",
                concept: "An LFO pointed at loudness, a steady pulsing of the volume.",
                theory: [
                    "Send the same LFO to loudness instead and the volume rises and falls over and over. That is tremolo.",
                    "A slow tremolo breathes. A fast one chops the sound into a rhythm. A square LFO shape turns it into a hard on and off gate.",
                    "It is the same LFO, pointed at a new place. The pattern of modulation repeats across the whole synth."
                ],
                takeaways: ["An LFO on loudness is tremolo", "Shape and rate turn it from breathing to chopping"],
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
                    duration: 7,
                    startPatch: Patch([.oscWave: 0.72, .cutoff: 0.45, .resonance: 0.4, .lfoDepth: 0.7, .lfoRate: 0.3, .ampSustain: 0.95]),
                    routing: Routing(source: .lfo, dest: .cutoff),
                    lanes: [lane(.lfoRate, [(0.5, 0.2), (6.5, 0.55)])],
                    notes: held(36, 6.5)
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
