# Aether Learn

Learn sound design from first principles, by turning real knobs. Each lesson runs
**Learn → Watch → Play**: read the concept, watch the synth demo itself (knobs move
automatically while notes play), then play the same partial synth freely.

## Run

```sh
cd aether/learn
xcodegen generate
xcodebuild -project AetherLearn.xcodeproj -scheme AetherLearn \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Or open `AetherLearn.xcodeproj` and run on a simulator/device.

## What's in the MVP

A single teaching synth engine (fresh Swift, AVAudioEngine) drives every lesson:
morphing wavetable osc → multimode SV filter → **DAHDSR** envelope (proper Hold + curve),
one **LFO**, and a single editable **modulation slot** (source → destination → depth).

Each lesson runs **Learn → Watch → Play** (Watch is skipped when a lesson has no demo).
Every exercise is built around an audio-reactive visual, uses key-latch (tap a key to hold
the sound, tap again to stop), and has no pass check.

**18 lessons across 4 modules:**
- **Sound & Frequency** (foundation), What Sound Is · Frequency · Frequency Becomes Pitch ·
  Loudness · Waveforms · Harmonics · Two Notes & Beating · Detune
- **Subtractive**, Cutoff · Resonance · Filter Types
- **The Shape**, Attack & Release · Decay & Sustain · Hold & Delay
- **Motion**, The LFO (mod matrix) · Vibrato · Tremolo · Filter Wobble

Every module has a purpose-built visual:
- **Sound & Frequency**, live **waveform scope**, **harmonic spectrum**, **frequency explorer**
  (sweep Hz, watch it snap to a note), drawn **wave-shape presets**
- **Subtractive**, an **EQ/filter graph**, harmonic bars with the filter curve cutting them,
  draggable cutoff/resonance, plus drawn filter-type icons (LP/HP/BP/notch)
- **The Shape**, a **DAHDSR envelope editor** that reshapes live and rides a playhead
- **Motion**, an **LFO display** with the moving looping shape and destination picker

Progress persists locally.

## Layout

```
Aether/
  Engine/        synth core, Params, DSP, ModMatrix, Voice, SynthEngine,
                 SynthController (UI↔audio bridge), SequencePlayer (demo automation)
  Content/       Models (Course/Module/Lesson + ProgressStore), Curriculum (the lessons)
  Components/    Knob, Keyboard
  Screens/       RootView, CourseScreen, LessonScreen
  DesignSystem/  Theme (colors + fonts, matched to the Aether app)
```

## Architecture notes

- **Core vs front-end:** every knob is an addressable `ParamID`; a lesson exposes a *subset*.
  One data-driven `LessonScreen` renders any lesson from its `LessonConfig`.
- **Demo = Exercise substrate:** `SequencePlayer` mutates the same `SynthController` the user
  touches, so a demo literally moves the knobs of the exercise that follows.
- **No pass checks**, exercises are free sandboxes of the concept just taught.

## Not yet (next scope)

FM / additive / ring-mod tone generation, a second oscillator per voice with independent
pitch, a multi-slot mod matrix, and the Capstone "from-scratch" sandboxes.
