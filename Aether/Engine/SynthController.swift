import Foundation
import SwiftUI
import AVFoundation

// The output device currently playing sound, with its rough frequency limits.
struct OutputInfo: Equatable {
    var name: String
    var low: Double
    var high: Double
}

// Single source of truth bridging UI ↔ engine. Knobs and visuals bind to this; the demo player
// mutates the same state, so a demo literally moves the controls the user will then touch.
final class SynthController: ObservableObject {
    @Published var patch = Patch()
    @Published var routing = Routing.off
    @Published var meter: Double = 0
    @Published var scope: [Float] = []
    @Published var spectrum: [Float] = []      // live FFT-style bars of the actual output
    @Published var ampHistory: [Float] = []   // rolling output peak over ~4s, for the beating display

    private let analyzer = SpectrumAnalyzer()

    // Key-latch: one held note at a time. Tap a key to hold it, tap again (or another) to switch.
    @Published var latchedNote: Int? = nil

    // Seconds since the current note started (negative = idle), for the envelope playhead.
    @Published var noteAge: Double = -1
    private var noteStart: Date?

    // Seconds since the current note was released (negative = still held or idle),
    // so the envelope playhead can travel through the release stage.
    @Published var releaseAge: Double = -1
    private var releaseStart: Date?

    // Pure test tone (frequency lessons)
    @Published var toneOn = false
    @Published var toneHz: Double = 220

    // Current audio output device (playback lessons)
    @Published var output = OutputInfo(name: "iPhone speaker", low: 500, high: 12000)

    // Live system (phone) volume, 0…1 (amplitude lesson)
    @Published var systemVolume: Double = 0.5

    private let engine = SynthEngine()
    private var displayTimer: Timer?
    private var volObserver: NSKeyValueObservation?

    init() {
        engine.push(base: patch.values, routing: routing)
    }

    func start() {
        engine.start()
        engine.push(base: patch.values, routing: routing)
        refreshRoute()
        #if os(iOS)
        NotificationCenter.default.addObserver(
            self, selector: #selector(routeChanged),
            name: AVAudioSession.routeChangeNotification, object: nil)
        let sess = AVAudioSession.sharedInstance()
        systemVolume = Double(sess.outputVolume)
        volObserver = sess.observe(\.outputVolume, options: [.new]) { [weak self] s, _ in
            DispatchQueue.main.async { self?.systemVolume = Double(s.outputVolume) }
        }
        #endif
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.meter = self.engine.meter
            self.scope = self.engine.scopeSnapshot()
            self.noteAge = self.noteStart.map { Date().timeIntervalSince($0) } ?? -1
            self.releaseAge = self.releaseStart.map { Date().timeIntervalSince($0) } ?? -1
            let peak = self.scope.map { abs($0) }.max() ?? 0
            self.ampHistory.append(peak)
            if self.ampHistory.count > 120 { self.ampHistory.removeFirst(self.ampHistory.count - 120) }
            self.spectrum = self.analyzer.process(self.scope)
        }
    }

    func stop() {
        displayTimer?.invalidate(); displayTimer = nil
        volObserver?.invalidate(); volObserver = nil
        clearLatch()
        engine.toneOff(); toneOn = false
        engine.allOff()
        clearSim()
        engine.shutdown()
    }

    // MARK: Parameters

    func set(_ id: ParamID, _ value: Double) {
        patch[id] = value
        engine.setBase(id, patch[id])
    }

    func binding(_ id: ParamID) -> Binding<Double> {
        Binding(get: { self.patch[id] }, set: { self.set(id, $0) })
    }

    func apply(_ p: Patch) {
        patch = p
        engine.push(base: p.values, routing: routing)
    }

    func setRouting(_ r: Routing) {
        routing = r
        engine.push(base: patch.values, routing: r)
    }

    // MARK: Notes + latch

    func noteOn(_ midi: Int, velocity: Double = 0.85) {
        engine.noteOn(midi, velocity: velocity)
        noteStart = Date(); releaseStart = nil
    }
    func noteOff(_ midi: Int) { engine.noteOff(midi); releaseStart = Date() }
    func allOff() { engine.allOff(); noteStart = nil; releaseStart = nil }

    func toggleLatch(_ midi: Int) {
        if latchedNote == midi {
            engine.noteOff(midi); latchedNote = nil; releaseStart = Date()
        } else {
            if let old = latchedNote { engine.noteOff(old) }
            latchedNote = midi
            engine.noteOn(midi)
            noteStart = Date(); releaseStart = nil
        }
    }

    func clearLatch() {
        if let n = latchedNote { engine.noteOff(n); releaseStart = Date() }
        latchedNote = nil
    }

    // MARK: Test tone

    func setToneHz(_ hz: Double) {
        toneHz = hz
        engine.setTone(hz: hz, on: toneOn)
    }

    func toggleTone() {
        toneOn.toggle()
        engine.setTone(hz: toneHz, on: toneOn)
    }

    func stopTone() {
        toneOn = false
        engine.toneOff()
    }

    // MARK: Additive lesson (build a saw from sine partials)

    func setAdditive(_ n: Int) { engine.setAdditive(n) }

    // MARK: Playback-gear simulation

    func setSim(low: Double, high: Double) { engine.setSim(low: low, high: high) }
    func clearSim() { engine.setSim(low: 0, high: 22000) }

    // MARK: Bass / kick test (real-device gear lesson)

    func triggerKick() { engine.triggerKick() }
    func toggleSubBass() {
        if toneOn { stopTone() } else { setToneHz(45); toggleTone() }
    }

    // MARK: Output route

    @objc private func routeChanged() { DispatchQueue.main.async { self.refreshRoute() } }

    func refreshRoute() {
        #if os(iOS)
        guard let port = AVAudioSession.sharedInstance().currentRoute.outputs.first else { return }
        output = Self.mapPort(port)
        #endif
    }

    #if os(iOS)
    private static func mapPort(_ p: AVAudioSessionPortDescription) -> OutputInfo {
        switch p.portType {
        case .builtInSpeaker:   return OutputInfo(name: "iPhone speaker", low: 250, high: 12000)
        case .builtInReceiver:  return OutputInfo(name: "Earpiece", low: 500, high: 8000)
        case .headphones:       return OutputInfo(name: "Wired headphones", low: 15, high: 22000)
        case .bluetoothA2DP:    return OutputInfo(name: p.portName, low: 55, high: 18000)
        case .airPlay:          return OutputInfo(name: p.portName, low: 40, high: 20000)
        case .usbAudio:         return OutputInfo(name: p.portName, low: 30, high: 22000)
        default:                return OutputInfo(name: p.portName, low: 45, high: 20000)
        }
    }
    #endif

    deinit {
        NotificationCenter.default.removeObserver(self)
        displayTimer?.invalidate()
        volObserver?.invalidate()
        engine.shutdown()
    }
}
