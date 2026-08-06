# Aether Learn — TODO

Lesson IDs from `Aether/Content/Curriculum.swift`. Phases live in `LessonScreen.swift:32`
(`theory = "Learn"`, `demo = "Watch"`, `play = "Play"`); a lesson only shows **Watch** when
`Lesson.demo` is non-nil.

---

## P0 — Broken / misleading (trust killers)

### 1. "Repetition Makes a Note" doesn't demonstrate its point (`msr3`) — **done**

**Want:** stepping RATIO to an in-between value (1.5, 7) must audibly stop being a note and turn
metallic. Today every position keeps a clear pitch, so the lesson proves nothing.

**Cause:** the FM modulation index was `amount * 1.5`, so even at full depth the index topped out
at 1.5 — the carrier dominates and the ear still finds the fundamental at every ratio. The visual
used `amount * 3`, so the drawing and the sound already disagreed despite a comment claiming
otherwise.

**Fix:** `Voice.fmIndex(_:)` (= `amount * 6`) is now the single source for both engine and
`FMView`. Exercise depth starts at 0.7 so the default position already demonstrates the point.

### 2. Tremolo dot doesn't match what you hear (`m4l3`) — **done**

**Want:** dot at the top exactly when the sound is loudest.

**Cause:** `LFOGraph` ran its own wall-clock playhead (`ctx.date * rateHz`), never once reading the
engine. Same nominal rate, unrelated phase — it drifted within seconds of opening the lesson.

**Fix:** the engine publishes `lfoPhaseOut` / `lfoValueOut` (the *smoothed* value the voices
multiply by) each control block; the graph reads them per frame via `SynthController.lfoPhase` /
`.lfoValue`. Not `@Published` on purpose — the 30 Hz display timer would alias a 20 Hz LFO.

### 3. Detune visual moves while nothing is playing (`m1l8`) — **done**

**Want:** still when no note sounds; motion rate = the real beat frequency.

**Cause:** two bugs. It animated off its own timeline with no idea whether the synth was making
sound, and the rate was `detune * 1.4` — invented, and independent of the note, when the real beat
is `2 * spread * hz`. At C3 and 0.15 detune it drew 0.21 Hz against an actual 0.79 Hz.

**Fix:** rate now derives from `Voice.detuneSpread` and the engine's `soundingHz`, capped at 12 Hz
for legibility (past that you hear two pitches, not a pulse). Silent = frozen, with the caption
switching to "play a note to hear them drift" so a still picture doesn't read as broken.

---

## P1 — UX friction on every lesson

### 4. Keyboard too tall

**Want:** `Keyboard.swift` cut the height by half without changing the size of the keys. this is possible because the black keys are taking too much space so if I visually cut it I can see it will still be functional and good UI/UX

### 5. FM Synthesis repeated wording (`msr2`)

**Want:** title and first theory paragraph stop restating each other. Copy edit only.

### 6. Filter-cutoff visual under the Sync knob (`msr4`, "Restarting Adds Harmonics")

**Want:** a small spectrum/cutoff display below the Sync knob showing which frequencies are actually
sounding, so "restarting adds harmonics" is visible, not just claimed. `Engine/Spectrum.swift`
already exists — reuse it.

---

## P2 — Content completeness

### 8. The Bee plays a song (`m1l2b`) — order Learn → **Play** → Watch

**Want:** you hear the bee as an actual short piece. Uniquely, Play comes _before_ Watch here: fiddle
first, then watch it click. Needs a per-lesson phase-order override in `LessonScreen.phases`.

### 9. "Frequency Becomes Pitch" gets a Watch (`m1l3`)

**Want:** same exercise UI, playing a short lullaby, so the frequency→pitch mapping is heard as
music rather than as a sweep.

### 10. Effects lessons use real effects (module `mfx`)

**Want:** add a lesson that teaches why every audio effect is either gain, delay or both

---

## P3 — New capabilities

### 12. Feedback goes to a backend

**Want:** `progress.recordFeedback` (`RatingViews.swift:211`) also POSTs to our endpoint —
anonymous id, module id, text, app version, locale. Keep the on-device write as the offline queue and
retry; never block or fail the UI.

---

## Order of work

1 → 2 → 3 → 4 → 5 → 6 → 12 → 8 → 9 → 10

P0 first because they make the app teach the wrong thing. 12 is early despite being P3: until it
ships, every user note is stranded on a device and unrecoverable. 10 last — it is a new lesson, not
a fix, so it lands once the existing lessons are honest.

## Parallel tracks

| Track                  | Items      | Touches                                                      |
| ---------------------- | ---------- | ------------------------------------------------------------ |
| A — engine/visual sync | 1, 2, 3, 6 | `Engine/`, `Components/Visuals.swift`, `EffectVisuals.swift` |
| B — layout + copy      | 4, 5       | `Keyboard.swift`, `Curriculum.swift` (text only)             |
| C — backend           | 12         | `Store/`, `RatingViews.swift`                                |
| D — lesson content     | 8, 9, 10   | `Curriculum.swift` (demos + new lesson), `LessonScreen.phases` |

A, B, C run fully independent. D conflicts with B inside `Curriculum.swift` — same file, different
fields, so land B (two small copy edits) first and D after.

---

## Backlog — not now

### 7. Standardize every lesson on Learn → Watch → Play

**Want:** all 47 lessons have a `DemoScript`. Today 28 have `demo: nil` and skip Watch entirely, so
the app teaches a shape it doesn't keep. Each new demo = a short musical phrase plus automation
lanes that move the same params the exercise exposes.

**Deferred:** large (28 lessons). Items 8 and 9 establish the demo pattern first — pick this up after.

### 11. Voice reading of the Learn phase

**Want:** a play button on the theory text that reads it aloud (AVSpeechSynthesizer), honoring the
selected language from `Localization.swift`, pausing lesson audio while it speaks, stopping on phase
change. Term links must not be read as URLs.
