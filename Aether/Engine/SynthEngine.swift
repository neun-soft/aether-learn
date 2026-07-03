import Foundation
import AVFoundation

// MARK: - Spinlock for UI → audio parameter handoff

final class Spinlock {
    private var lock = os_unfair_lock()
    @inline(__always) func sync<T>(_ body: () -> T) -> T {
        os_unfair_lock_lock(&lock); defer { os_unfair_lock_unlock(&lock) }
        return body()
    }
}

// MARK: - Compact Freeverb-style reverb

final class Reverb {
    private let combs: [Comb]
    private let allpasses: [Allpass]
    init(sampleRate: Double) {
        let scale = sampleRate / 44100.0
        let combTunings = [1116, 1188, 1277, 1356].map { Int(Double($0) * scale) }
        let apTunings = [556, 441].map { Int(Double($0) * scale) }
        combs = combTunings.map { Comb(size: $0) }
        allpasses = apTunings.map { Allpass(size: $0) }
    }
    @inline(__always) func process(_ x: Double, size: Double) -> Double {
        let feedback = 0.7 + 0.28 * clamp01(size)
        var out = 0.0
        for c in combs { out += c.process(x, feedback: feedback) }
        out /= Double(combs.count)
        for a in allpasses { out = a.process(out) }
        return out
    }
    final class Comb {
        private var buf: [Double]; private var i = 0; private var store = 0.0
        init(size: Int) { buf = [Double](repeating: 0, count: max(1, size)) }
        @inline(__always) func process(_ x: Double, feedback: Double) -> Double {
            let y = buf[i]
            store = y * 0.2 + store * 0.8            // damping
            buf[i] = x + store * feedback
            i = (i + 1) % buf.count
            return y
        }
    }
    final class Allpass {
        private var buf: [Double]; private var i = 0
        init(size: Int) { buf = [Double](repeating: 0, count: max(1, size)) }
        @inline(__always) func process(_ x: Double) -> Double {
            let y = buf[i]
            buf[i] = x + y * 0.5
            i = (i + 1) % buf.count
            return -x + y
        }
    }
}

// MARK: - Engine

final class SynthEngine {
    private let engine = AVAudioEngine()
    private var srcNode: AVAudioSourceNode!
    private let format = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 2)!
    private let sr: Double = 48000

    private var voices: [Voice] = []
    private let lfo: LFO
    private let reverb: Reverb
    private let simHP: SVFilter
    private let simLP: SVFilter
    private let kick: KickSynth
    private var kickArm = false
    private let lock = Spinlock()

    private var pending = RenderSnapshot.empty     // written by UI, read at block start
    private var current = RenderSnapshot.empty     // audio-thread copy
    private var noteCounter = 0
    private var ctrl = 0
    private var lfoV = 0.0
    private var lfoS = 0.0    // smoothed LFO, kills the click when saw/square shapes jump
    private var started = false

    // Live scope: a ring of recent output samples for the waveform display. Raw pointer so the
    // UI can copy it without locking the audio thread (visual only; a torn read is harmless).
    private let scopeSize = 1024
    private let scope: UnsafeMutablePointer<Float>
    private var scopeW = 0

    // Pure test tone for the frequency lessons (a clean sine, no filter or envelope).
    private var tonePhase = 0.0
    private var toneGain = 0.0
    private var flutterPhase = 0.0    // wingbeat/puff phase for the bee
    private var puffEnv = 0.0         // per-flap air-puff envelope
    private var beeLP = 0.0           // one-pole softening of the puff noise
    private var noiseSeed: UInt32 = 0x9E3779B9   // fast PRNG for the bee's air noise

    init() {
        scope = UnsafeMutablePointer<Float>.allocate(capacity: scopeSize)
        scope.initialize(repeating: 0, count: scopeSize)
        lfo = LFO(sampleRate: sr / 32)   // the LFO is advanced once per 32-sample control block
        reverb = Reverb(sampleRate: sr)
        simHP = SVFilter(sampleRate: sr)
        simLP = SVFilter(sampleRate: sr)
        kick = KickSynth(sampleRate: sr)
        let rate = sr
        voices = (0..<8).map { _ in Voice(sampleRate: rate) }
    }

    deinit { scope.deallocate() }

    private func setupNode() {
        srcNode = AVAudioSourceNode(format: format) { [unowned self] _, _, frameCount, abl -> OSStatus in
            self.render(Int(frameCount), abl)
            return noErr
        }
        engine.attach(srcNode)
        engine.connect(srcNode, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.9
    }

    func start() {
        guard !started else { return }
        started = true
        if srcNode == nil { setupNode() }
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
        #endif
        engine.prepare()
        try? engine.start()
    }

    func stop() {
        for v in voices { v.kill() }
    }

    /// Fully stop the audio engine. Must run before the owner deallocates: the render block
    /// captures self unowned and writes into the scope buffer, so rendering past deinit is a
    /// use-after-free (the intermittent crash when leaving a lesson).
    func shutdown() {
        guard started else { return }
        started = false
        engine.stop()
    }

    // MARK: UI-facing setters (thread-safe)

    func push(base: [ParamID: Double], routing: Routing) {
        lock.sync {
            for (id, val) in base { pending.base[id.index] = val }
            pending.routingSource = routing.source == .lfo ? 0 : 1
            pending.routingDest = ModDest.allCases.firstIndex(of: routing.dest) ?? 0
        }
    }

    func setBase(_ id: ParamID, _ v: Double) {
        lock.sync { pending.base[id.index] = min(1, max(0, v)) }
    }

    func setTone(hz: Double, on: Bool, buzz: Bool = false) {
        lock.sync { pending.toneHz = hz; pending.toneOn = on; pending.toneBuzz = buzz }
    }
    // Bee: a train of air-puffs at the flap rate (3 Hz separate flaps → ~220 Hz buzz).
    func setBee(on: Bool, flapRate: Double) {
        lock.sync { pending.toneOn = on; pending.toneBuzz = on; pending.toneFlutterHz = flapRate }
    }
    func setToneHz(_ hz: Double) { lock.sync { pending.toneHz = hz } }
    func toneOff() { lock.sync { pending.toneOn = false } }

    /// Band-limit the master output to simulate a piece of gear (0 low / 22000 high = full range).
    func setSim(low: Double, high: Double) { lock.sync { pending.simLow = low; pending.simHigh = high } }

    func triggerKick() { lock.sync { kickArm = true } }

    /// 0 disables additive mode; 1…WaveTables.maxPartials plays a saw built from that many sine partials.
    func setAdditive(_ n: Int) { lock.sync { pending.additiveCount = n } }

    /// Copy of the recent output samples for the live waveform display.
    func scopeSnapshot() -> [Float] {
        var arr = [Float](repeating: 0, count: scopeSize)
        let start = scopeW
        for i in 0..<scopeSize { arr[i] = scope[(start + i) % scopeSize] }
        return arr
    }

    func noteOn(_ midi: Int, velocity: Double = 0.85) {
        let snap = lock.sync { pending }
        noteCounter += 1
        var v = voices.first { !$0.active }
        if v == nil { v = voices.min { $0.startedAt < $1.startedAt } }
        v?.noteOn(midi, velocity: velocity, snap: snap, order: noteCounter)
    }

    func noteOff(_ midi: Int) {
        for v in voices where v.active && v.midi == midi { v.noteOff() }
    }

    func allOff() { for v in voices { v.noteOff() } }

    /// Peak amp-envelope level across voices, lets the UI draw a live "playing" indicator.
    var meter: Double { voices.map { $0.active ? $0.envLevel : 0 }.max() ?? 0 }

    // MARK: Render

    private func render(_ frames: Int, _ abl: UnsafeMutablePointer<AudioBufferList>) {
        let bufs = UnsafeMutableAudioBufferListPointer(abl)
        let L = bufs[0].mData!.assumingMemoryBound(to: Float.self)
        let R = bufs.count > 1 ? bufs[1].mData!.assumingMemoryBound(to: Float.self) : L

        for i in 0..<frames {
            if ctrl == 0 {
                current = lock.sync {
                    if kickArm { kickArm = false; kick.trigger() }
                    return pending
                }
                let rateHz = 0.05 * pow(2.0, current.v(.lfoRate) * 8.6)
                lfoV = lfo.render(hz: rateHz, shape: current.v(.lfoShape) * 3.0)
                lfoS += (lfoV - lfoS) * 0.35   // ~2 ms slew at block rate; edges stay audibly sharp
            }
            ctrl = (ctrl + 1) & 31

            var mix = 0.0
            for v in voices where v.active { mix += v.render(current, lfoValue: lfoS) }
            mix = mix * 0.4 + kick.render()

            let drive = current.v(.drive)
            if drive > 0.001 { mix = tanh(mix * (1 + drive * 5)) }

            let wet = reverb.process(mix, size: current.v(.reverb))
            let mixAmt = current.v(.reverbMix)
            var out = mix * (1 - mixAmt) + wet * mixAmt

            // Pure test tone, added clean on top (frequency lessons). Ramp the gain to avoid clicks.
            let toneTarget = current.toneOn ? 1.0 : 0.0
            toneGain += (toneTarget - toneGain) * 0.002
            if toneGain > 0.0001 {
                let toneSample: Double
                if current.toneBuzz {
                    // Each wingbeat is one short, soft puff of moving air (a quick "fff").
                    // At a slow flap rate you hear separate puffs; speed them up and they
                    // fuse into a buzzy bee tone — the flap rate becomes the pitch.
                    flutterPhase += current.toneFlutterHz / sr
                    if flutterPhase >= 1 { flutterPhase -= 1; puffEnv = 1.0 }
                    puffEnv *= 0.9977                       // ~9 ms per puff
                    noiseSeed = noiseSeed &* 1664525 &+ 1013904223
                    let n = Double(Int32(bitPattern: noiseSeed)) / Double(Int32.max)
                    beeLP += (n - beeLP) * 0.45             // soften the hiss into airy 'fff'
                    toneSample = beeLP * puffEnv * 0.5
                } else {
                    tonePhase += current.toneHz / sr
                    if tonePhase >= 1 { tonePhase -= 1 }
                    toneSample = sin(2.0 * .pi * tonePhase)
                }
                out += toneSample * 0.28 * toneGain
            }

            // Playback-gear simulation: roll off the lows and/or highs the device can't reproduce.
            if current.simLow > 25 { out = simHP.process(out, cutoffHz: current.simLow, res: 0, mode: .highpass) }
            if current.simHigh < 20000 { out = simLP.process(out, cutoffHz: current.simHigh, res: 0, mode: .lowpass) }

            out = tanh(out)   // soft limit: chords saturate gently instead of hard-clipping
            scope[scopeW] = Float(out)
            scopeW = (scopeW + 1) % scopeSize

            L[i] = Float(out)
            if R != L { R[i] = Float(out) }
        }
    }
}
