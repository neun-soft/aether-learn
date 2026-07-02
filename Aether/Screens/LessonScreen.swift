import SwiftUI

struct LessonScreen: View {
    var index: Int = 0
    let lesson: Lesson
    var accent: Color
    var path: Binding<[Route]>? = nil

    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var lang: LangStore
    @StateObject private var synth = SynthController()
    @StateObject private var demo = DemoPlayer()
    @State private var phase: Phase = .theory
    @State private var toneNorm: Double = 0.3
    @State private var holdMode = true
    @State private var selectedGear: String? = nil
    @State private var matches: [String: String] = [:]
    @State private var showCover = true
    @State private var octaveShift = 0
    @State private var additiveCount = 1

    enum Phase: String, CaseIterable { case theory = "Learn", demo = "Watch", play = "Play" }

    private var module: Module { Curriculum.flat[index].module }
    private var hasNextLesson: Bool {
        index + 1 < Curriculum.flat.count && Curriculum.flat[index + 1].module.id == module.id
    }

    private func finish(goNext: Bool) {
        progress.markDone(lesson.id)
        // Next lesson always advances to the next one, even when redoing a completed module.
        if goNext, hasNextLesson { path?.wrappedValue = [.lesson(index + 1)]; return }
        // On the last lesson of the module: celebrate only once the whole module is done.
        let moduleDone = module.lessons.allSatisfy { progress.isDone($0.id) }
        if goNext, !hasNextLesson, moduleDone { path?.wrappedValue = [.congrats(module.id)] }
        else { path?.wrappedValue = [] }
    }

    private var phases: [Phase] {
        lesson.demo == nil ? [.theory, .play] : [.theory, .demo, .play]
    }

    private func go(to p: Phase) { withAnimation(.easeInOut(duration: 0.28)) { phase = p } }

    var body: some View {
        ZStack {
            Theme.bgGradient.ignoresSafeArea()
            if showCover {
                coverView.transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    phasePicker
                    Divider().overlay(Theme.hairline())
                    content
                        .id(phase)
                        .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    moduleProgress
                }
                .transition(.opacity)
            }
        }
        .navigationTitle(lang.t(lesson.title))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            synth.start(); loadExercise(); holdMode = lesson.exercise.holdDefault
            #if DEBUG
            applyShotIfNeeded()
            #endif
        }
        .onDisappear { demo.stop(); synth.stop() }
        .onChange(of: phase) { _, new in
            demo.stop(); synth.clearLatch(); synth.stopTone()
            if new == .play { loadExercise() }
        }
    }

    // How far through the current lesson's phases we are (Learn → Watch → Play).
    private var phaseFraction: Double {
        let idx = phases.firstIndex(of: phase) ?? 0
        return phases.count > 1 ? Double(idx) / Double(phases.count - 1) : 1
    }
    // Overall position in the module, counting the phase progress inside the current lesson.
    private var moduleFraction: Double {
        (Double(lessonNumber - 1) + phaseFraction) / Double(max(1, module.lessons.count))
    }

    // Progress within the module, locked to the bottom of every lesson screen.
    private var moduleProgress: some View {
        HStack(spacing: 10) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.hairline(0.08))
                    Capsule().fill(accent).frame(width: max(5, geo.size.width * CGFloat(moduleFraction)))
                        .animation(.easeInOut(duration: 0.3), value: moduleFraction)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 5)
            Text("\(lang.t(module.title).uppercased()) \(lessonNumber)/\(module.lessons.count)")
                .mono(9).foregroundColor(Theme.textDim).fixedSize()
        }
        .padding(.horizontal, 20).padding(.top, 5).padding(.bottom, 7)
        .background(Theme.panelAlt)
        .overlay(alignment: .top) { Divider().overlay(Theme.hairline()) }
    }

    private func loadExercise() {
        synth.apply(lesson.exercise.basePatch)
        synth.setRouting(lesson.exercise.initialRouting)
        if lesson.exercise.visual == .additive { synth.setAdditive(additiveCount) }
        if let t = lesson.exercise.tone {
            toneNorm = t.startNorm
            synth.setToneHz(frequencyFor(t, norm: t.startNorm))
        }
    }

    #if DEBUG
    // Screenshot harness: jump this lesson into a phase with a note playing.
    private func applyShotIfNeeded() {
        guard Shot.lessonID == lesson.id else { return }
        showCover = false
        switch Shot.phase {
        case "theory": phase = .theory
        case "watch":  phase = .demo
        default:       phase = .play
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            loadExercise()
            if let n = Shot.additive { additiveCount = n; synth.setAdditive(n) }
            if Shot.play {
                if phase == .demo, let script = lesson.demo {
                    demo.play(script, on: synth)
                } else {
                    holdMode = true
                    synth.toggleLatch(lesson.exercise.keyboardRoot + Shot.noteOffset)
                }
            }
        }
    }
    #endif

    // MARK: Cover

    private var lessonNumber: Int {
        (module.lessons.firstIndex { $0.id == lesson.id } ?? 0) + 1
    }

    private var coverView: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("\(lang.t(module.title).uppercased())  ·  \(lang.t("LESSON")) \(lessonNumber)")
                .mono(11, .semibold).tracking(2).foregroundColor(accent)
                .multilineTextAlignment(.center)
            Text(lang.t(lesson.title))
                .ui(34, .semibold).foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Rectangle().fill(accent).frame(width: 40, height: 3).padding(.top, 4)
            Spacer()
            Button { withAnimation(.easeInOut(duration: 0.3)) { showCover = false } } label: {
                HStack(spacing: 6) {
                    Text(lang.t("Begin"))
                    Image(systemName: "arrow.right")
                }
                .font(AppFont.ui(16, .semibold)).foregroundColor(.black)
                .frame(maxWidth: .infinity).padding(.vertical, 15)
                .background(accent).clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 28).padding(.bottom, 24)
    }

    // MARK: Phase switcher

    private var phasePicker: some View {
        HStack(spacing: 0) {
            ForEach(phases, id: \.self) { p in
                let on = phase == p
                Button { go(to: p) } label: {
                    Text(lang.t(p.rawValue))
                        .ui(14, on ? .semibold : .regular)
                        .foregroundColor(on ? Theme.textPrimary : Theme.textDim)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(alignment: .bottom) {
                            Rectangle().fill(on ? accent : .clear).frame(height: 2)
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
    }

    @ViewBuilder private var content: some View {
        switch phase {
        case .theory: theoryView
        case .demo:   demoView
        case .play:   playView
        }
    }

    // MARK: Learn

    private var theoryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(lang.t(lesson.concept))
                    .ui(18, .medium).foregroundColor(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(Array(lesson.theory.enumerated()), id: \.offset) { _, para in
                    Text(lang.t(para))
                        .ui(15).foregroundColor(Theme.textSecondary)
                        .lineSpacing(4).fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(lang.t("TAKEAWAYS")).mono(11, .semibold).tracking(1.5).foregroundColor(Theme.textDim)
                    ForEach(lesson.takeaways, id: \.self) { t in
                        HStack(alignment: .top, spacing: 10) {
                            Circle().fill(accent).frame(width: 6, height: 6).padding(.top, 6)
                            Text(lang.t(t)).ui(14).foregroundColor(Theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading).panel()

                Button { go(to: phases.contains(.demo) ? .demo : .play) } label: {
                    Text(lang.t(phases.contains(.demo) ? "Watch the demo" : "Try it"))
                        .ui(15, .semibold).foregroundColor(.black)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(accent).clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
    }

    // MARK: Watch

    private var demoView: some View {
        VStack(spacing: 18) {
            Text(lang.t(lesson.concept))
                .ui(14).foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24).padding(.top, 16)

            visual(interactive: false)
            knobRow(interactive: false)

            ProgressBar(value: demo.progress, tint: accent).padding(.horizontal, 40)

            Button {
                if demo.isPlaying { demo.stop() }
                else if let script = lesson.demo { demo.play(script, on: synth) }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: demo.isPlaying ? "stop.fill" : "play.fill")
                    Text(lang.t(demo.isPlaying ? "Stop" : "Play demo"))
                }
                .font(AppFont.ui(15, .semibold)).foregroundColor(.black)
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(accent).clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain).padding(.horizontal, 20)

            Button { demo.stop(); go(to: .play) } label: {
                HStack(spacing: 6) {
                    Text(lang.t("Try it yourself"))
                    Image(systemName: "arrow.right")
                }
                .font(AppFont.ui(15, .semibold)).foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity).padding(.vertical, 13).panel(14)
            }
            .buttonStyle(.plain).padding(.horizontal, 20)

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: Play

    private var playView: some View {
        VStack(spacing: 14) {
            ScrollView {
                VStack(spacing: 16) {
                    Text(lang.t(lesson.exercise.prompt))
                        .ui(14).foregroundColor(Theme.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20).padding(.top, 14)

                    if let tone = lesson.exercise.tone {
                        FrequencyExplorer(
                            norm: $toneNorm,
                            minHz: tone.minHz, maxHz: tone.maxHz, snap: tone.snap,
                            toneOn: synth.toneOn, scope: synth.scope, accent: accent,
                            onHz: { synth.setToneHz($0) },
                            onToggle: { synth.toggleTone() }
                        )
                    } else {
                        visual(interactive: true)
                        if lesson.exercise.wavePresets {
                            WavePresets(morph: synth.binding(.oscWave), accent: accent)
                        }
                        if lesson.exercise.filterTypePicker {
                            FilterTypePicker(value: synth.binding(.filterType), accent: accent)
                        }
                        if lesson.exercise.visual == .equipment {
                            GearChips(gear: Playback.gear, selectedID: $selectedGear, accent: accent)
                            if let id = selectedGear {
                                Text(lang.t(Playback.gear(id).blurb))
                                    .ui(12).foregroundColor(Theme.textMuted)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        if let hint = lesson.exercise.controlsHint, !lesson.exercise.visibleParams.isEmpty {
                            Text(lang.t(hint)).ui(12).foregroundColor(Theme.textDim)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 8)
                        }
                        knobRow(interactive: true)
                        if lesson.exercise.showSystemVolume { systemVolumeBar }
                        if lesson.exercise.showRouting {
                            RoutingPicker(
                                routing: Binding(get: { synth.routing }, set: { synth.setRouting($0) }),
                                sources: lesson.exercise.allowedSources,
                                dests: lesson.exercise.allowedDests,
                                accent: accent
                            )
                        }
                    }

                    if lesson.exercise.showBassTest { bassTestButtons }
                    if let tip = lesson.exercise.tip { ideaTip(lang.t(tip)) }
                }
                .padding(.horizontal, 20)
            }

            if lesson.exercise.showKeyboard {
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        holdToggle
                        if lesson.exercise.showOctave { octaveStepper }
                    }
                    Keyboard(latched: holdMode ? synth.latchedNote : nil,
                             onDown: onKeyDown, onUp: onKeyUp,
                             root: lesson.exercise.keyboardRoot + octaveShift * 12, accent: accent)
                        .padding(.horizontal, 14)
                    Text(lang.t(keyboardHint)).ui(11).foregroundColor(Theme.textFaint)
                }
            }

            bottomBar
        }
    }

    // Keep-playing on = latch (tap toggles). Keep-playing off = play only while held.
    private func onKeyDown(_ key: Int) {
        if holdMode { synth.toggleLatch(key) } else { synth.noteOn(key) }
    }
    private func onKeyUp(_ key: Int) {
        if !holdMode { synth.noteOff(key) }
    }

    private var keyboardHint: String {
        if !holdMode { return "Press and hold a key. Let go to release it." }
        return synth.latchedNote == nil ? "Tap a key to hold the sound. Tap again to stop." : "Tap the lit key again to stop"
    }

    private var holdToggle: some View {
        Button {
            holdMode.toggle()
            if !holdMode { synth.clearLatch() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: holdMode ? "infinity" : "hand.tap.fill")
                Text(lang.t(holdMode ? "Keep note playing: On" : "Keep note playing: Off"))
            }
            .font(AppFont.ui(12, .medium))
            .foregroundColor(holdMode ? .black : Theme.textMuted)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(holdMode ? accent : Theme.inset)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button { finish(goNext: false) } label: {
                Text(lang.t("Done"))
                    .font(AppFont.ui(15, .semibold)).foregroundColor(Theme.textPrimary)
                    .frame(maxWidth: .infinity).padding(.vertical, 13).panel(14)
            }
            .buttonStyle(.plain)

            Button { finish(goNext: true) } label: {
                HStack(spacing: 6) {
                    Text(lang.t(hasNextLesson ? "Next lesson" : "Finish module"))
                    Image(systemName: "arrow.right")
                }
                .font(AppFont.ui(15, .semibold)).foregroundColor(.black)
                .frame(maxWidth: .infinity).padding(.vertical, 13)
                .background(accent).clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20).padding(.bottom, 8)
    }

    // MARK: Shared pieces

    @ViewBuilder private func visual(interactive: Bool) -> some View {
        switch lesson.exercise.visual {
        case .scope:
            WaveScope(samples: synth.scope, accent: accent)
        case .spectrum:
            SpectrumBars(spectrum: synth.spectrum, accent: accent)
        case .additive:
            AdditiveGraph(count: $additiveCount, accent: accent)
                .onChange(of: additiveCount) { _, n in synth.setAdditive(n) }
        case .filter:
            FilterGraph(cutoff: synth.binding(.cutoff), resonance: synth.binding(.resonance),
                        filterType: synth.patch[.filterType], spectrum: synth.spectrum,
                        accent: accent, interactive: interactive)
        case .detune:
            DetuneGraph(detune: synth.binding(.detune), accent: accent)
        case .envelope:
            EnvelopeGraph(delay: synth.patch[.ampDelay], attack: synth.patch[.ampAttack],
                          hold: synth.patch[.ampHold], decay: synth.patch[.ampDecay],
                          sustain: synth.patch[.ampSustain], release: synth.patch[.ampRelease],
                          curve: synth.patch[.ampCurve], playhead: synth.noteAge,
                          releaseAge: synth.releaseAge, accent: accent,
                          height: lesson.exercise.visibleParams.count > 4 ? 140 : 180)
        case .lfo:
            LFOGraph(rate: synth.patch[.lfoRate], shape: synth.patch[.lfoShape],
                     depth: synth.patch[.lfoDepth], dest: synth.routing.dest, accent: accent)
        case .equipment:
            FrequencyRangeChart(gear: Playback.gear, selectedID: selectedGear,
                                markerHz: markerHz, accent: accent)
        case .output:
            outputView
        case .match:
            ScenarioMatchView(scenarios: Playback.scenarios, gear: Playback.gear,
                              matches: $matches, accent: accent)
        case .beating:
            // Compact stack so the knobs stay visible above the keyboard on first render.
            VStack(spacing: 8) {
                WaveScope(samples: synth.scope, accent: accent, height: 92)
                Text(lang.t("VOLUME OVER TIME")).mono(10, .semibold).tracking(1.5).foregroundColor(Theme.textDim)
                BeatScope(history: synth.ampHistory, accent: accent, height: 72)
            }
        case .none:
            EmptyView()
        }
    }

    private var markerHz: Double? { synth.latchedNote.map { midiToHz(Double($0)) } }

    private func noteName(_ midi: Int) -> String {
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        return names[((midi % 12) + 12) % 12] + "\(midi / 12 - 1)"
    }

    private var octaveStepper: some View {
        HStack(spacing: 8) {
            octaveButton("minus") { octaveShift = max(-2, octaveShift - 1) }
            VStack(spacing: 0) {
                Text(noteName(lesson.exercise.keyboardRoot + octaveShift * 12))
                    .mono(11, .semibold).foregroundColor(accent)
                Text(lang.t("octave")).mono(7).foregroundColor(Theme.textFaint)
            }
            .frame(width: 40)
            octaveButton("plus") { octaveShift = min(2, octaveShift + 1) }
        }
    }
    private func octaveButton(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 12, weight: .bold))
                .frame(width: 30, height: 30).background(Theme.inset).clipShape(Circle())
                .foregroundColor(Theme.textMuted)
        }
        .buttonStyle(.plain)
    }

    private var bassTestButtons: some View {
        HStack(spacing: 12) {
            Button { synth.toggleSubBass() } label: {
                HStack(spacing: 6) {
                    Image(systemName: synth.toneOn ? "stop.fill" : "waveform")
                    Text(lang.t(synth.toneOn ? "Stop" : "Sub bass"))
                }
                .font(AppFont.ui(14, .semibold)).foregroundColor(synth.toneOn ? .black : Theme.textPrimary)
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(synth.toneOn ? accent : Theme.inset).clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            Button { synth.triggerKick() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "circle.fill")
                    Text(lang.t("Kick"))
                }
                .font(AppFont.ui(14, .semibold)).foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(Theme.inset).clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    private func ideaTip(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill").font(.system(size: 14)).foregroundColor(accent)
            Text(text).ui(13).foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(accent.opacity(0.10)).clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent.opacity(0.3), lineWidth: 1))
    }

    private var systemVolumeBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "iphone").font(.system(size: 13)).foregroundColor(Theme.textMuted)
                Text(lang.t("Phone volume")).ui(13).foregroundColor(Theme.textMuted)
                Spacer()
                Text("\(Int((synth.systemVolume * 100).rounded()))%").mono(13).foregroundColor(accent)
            }
            ProgressBar(value: synth.systemVolume, tint: accent)
            Text(lang.t("This is your phone's own volume, set with the side buttons. It comes after the app."))
                .ui(11).foregroundColor(Theme.textFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).panel()
    }

    private var outputView: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text(lang.t("NOW PLAYING ON")).mono(11, .semibold).tracking(1.5).foregroundColor(Theme.textDim)
                Text(synth.output.name).ui(24, .semibold).foregroundColor(accent)
            }
            FrequencyRangeChart(
                gear: [Gear(id: "out", name: synth.output.name, short: "This",
                            low: synth.output.low, high: synth.output.high, blurb: "")],
                selectedID: "out", markerHz: markerHz, accent: accent)
        }
    }

    @ViewBuilder private func knobRow(interactive: Bool) -> some View {
        let ids = lesson.exercise.visibleParams
        if ids.count <= 4 {
            HStack(alignment: .top, spacing: 18) {
                ForEach(ids, id: \.self) { knobFor($0, interactive: interactive) }
            }
            .frame(maxWidth: .infinity).padding(.vertical, 6)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 74), spacing: 12)], spacing: 16) {
                ForEach(ids, id: \.self) { knobFor($0, interactive: interactive) }
            }
            .padding(.vertical, 6)
        }
    }

    private func knobFor(_ id: ParamID, interactive: Bool) -> some View {
        LKnob(
            value: synth.binding(id),
            label: lang.t(lesson.exercise.labels[id] ?? id.spec.name),
            short: lesson.exercise.labels[id].map { String($0.uppercased().prefix(4)) } ?? id.spec.short,
            accent: accent,
            interactive: interactive
        )
    }
}

// MARK: - Routing picker (the mini mod matrix)

struct RoutingPicker: View {
    @Binding var routing: Routing
    var sources: [ModSource]
    var dests: [ModDest]
    var accent: Color
    @EnvironmentObject var lang: LangStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lang.t("MODULATION")).mono(11, .semibold).tracking(1.5).foregroundColor(Theme.textDim)
            if sources.count > 1 {
                segmented(title: "Source", options: sources.map { ($0.rawValue, $0) },
                          selected: routing.source) { routing.source = $0 }
            }
            segmented(title: "Destination", options: dests.map { ($0.rawValue, $0) },
                      selected: routing.dest) { routing.dest = $0 }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).panel()
    }

    private func segmented<T: Equatable>(title: String, options: [(String, T)],
                                         selected: T, onPick: @escaping (T) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(lang.t(title)).ui(12).foregroundColor(Theme.textDim)
            HStack(spacing: 6) {
                ForEach(options.indices, id: \.self) { i in
                    let opt = options[i]
                    let on = opt.1 == selected
                    Button { onPick(opt.1) } label: {
                        Text(lang.t(opt.0))
                            .ui(13, on ? .semibold : .regular)
                            .foregroundColor(on ? .black : Theme.textMuted)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(on ? accent : Theme.inset)
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
