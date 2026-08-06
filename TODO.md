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

### 4. Keyboard too tall — **done**

**Want:** `Keyboard.swift` cut the height by half without changing the size of the keys. this is possible because the black keys are taking too much space so if I visually cut it I can see it will still be functional and good UI/UX

**Fix:** 74pt → 38pt, black keys 0.62 → 0.58 of that. Tap targets are unchanged, because a thumb
aims at key *width* and that comes from the panel width, not the height.

### 5. FM Synthesis repeated wording (`msr2`) — **done**

**Want:** title and first theory paragraph stop restating each other. Copy edit only.

**Fix:** the `concept` line spent the whole slow-wobble/fast-wobble pair that paragraphs 2 and 3
then deliver properly. It is now just the hook.

### 6. Filter-cutoff visual under the Sync knob (`msr4`, "Restarting Adds Harmonics") — **done**

**Want:** a small spectrum display below the Sync knob showing which frequencies are actually
sounding, so "restarting adds harmonics" is visible, not just claimed.

**Fix:** new `Exercise.showSpectrum` flag renders `SpectrumBars` under the knob row, with a new
`markerHz` line on the fundamental — without that marker you see energy move but not the point,
which is that the note stayed put. Verified on device: the sync plot lost 24pt and the prompt a
line so the whole thing fits above the keyboard without scrolling.

---

## P2 — Content completeness

### 8. The Bee plays a song (`m1l2b`) — order Learn → **Play** → Watch — **done**

**Want:** you hear the bee as an actual short piece. Play comes _before_ Watch here: fiddle first,
then watch it click.

**Fix:** `DemoScript.bee` plays a tune on the wingbeat itself (Twinkle Twinkle — C3/G3/A3 are all
inside a bee's real range, so nothing is faked). `Lesson.watchLast` reorders the phases, and the
Watch screen grows the same Done/Next buttons the exercise has, since it is now the last step.
The slider and wings follow the demo's rate. Verified on device.

### 9. "Frequency Becomes Pitch" gets a Watch (`m1l3`) — **done**

**Want:** same exercise UI, playing a short lullaby, so the frequency→pitch mapping is heard as
music rather than as a sweep.

**Fix:** `DemoScript.tone` plays Brahms' lullaby as raw frequencies; the Watch screen shows the
frequency explorer itself (the generic visual would have been an empty panel) with the handle and
the note name following the tune. Verified on device: 494 Hz reads B4 mid-melody.

### 10. Effects lessons use real effects (module `mfx`) — **done**

**Want:** add a lesson that teaches why every audio effect is either gain, delay or both

**Fix:** new lesson `mfx5`, "It Is All Level and Time", closing the effects module. Sorts the five
effects the module just built into the two ingredients, with a table (`EffectFamiliesView`) whose
point is that no row needs a third column. The exercise gives one knob per ingredient — DRIVE and
ECHO — so the claim is testable, not just asserted. Verified on device.

---

## P3 — New capabilities

### 12. Feedback goes to a backend — **done, needs the endpoint confirmed**

**Want:** `progress.recordFeedback` also POSTs to our endpoint — anonymous id, module id, text, app
version, locale. Keep the on-device write as the offline queue and retry; never block or fail the UI.

**Fix:** `Aether/Store/Feedback.swift`. The device copy is the queue, not a fallback: written to
disk first, removed only once the server takes it, drained on launch and on every foreground.
Retries reuse the note's id so a delivered-but-unacknowledged note is not stored twice. A 4xx other
than 408/429 counts as delivered, otherwise a permanently rejected note blocks the queue forever.

Verified against a local collector: send, offline retention with the server down, and delivery of
the retained note on the next launch with its original id.

**Open:** the endpoint defaults to `https://aether.neunsoft.com/api/feedback` (the domain the
privacy link already uses) and is overridable with the `AetherFeedbackEndpoint` Info.plist key.
Nothing is live there yet — confirm the real URL and stand up the collector.

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
