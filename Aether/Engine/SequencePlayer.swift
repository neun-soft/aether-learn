import Foundation
import SwiftUI

// A demo is a hardcoded script: knob-automation lanes over time + a note pattern. Playing it
// mutates the live SynthController, so the real knobs move and real notes sound, the user just
// watches. The same controller is what they touch in the Exercise, so demo and exercise match.

struct Keyframe { let t: Double; let value: Double }

struct AutomationLane {
    let param: ParamID
    let frames: [Keyframe]

    func value(at t: Double) -> Double? {
        guard let first = frames.first else { return nil }
        if t <= first.t { return first.value }
        if let last = frames.last, t >= last.t { return last.value }
        for i in 1..<frames.count where t <= frames[i].t {
            let a = frames[i - 1], b = frames[i]
            let span = b.t - a.t
            let f = span <= 0 ? 0 : (t - a.t) / span
            return lerp(a.value, b.value, f)
        }
        return frames.last?.value
    }
}

struct NoteEvent { let t: Double; let midi: Int; let dur: Double }

struct DemoScript {
    var duration: Double
    var startPatch: Patch
    var routing: Routing = .off
    var lanes: [AutomationLane] = []
    var notes: [NoteEvent] = []
}

final class DemoPlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var progress = 0.0

    private weak var controller: SynthController?
    private var script: DemoScript?
    private var timer: Timer?
    private var startDate = Date()
    private var firedOn = Set<Int>()
    private var firedOff = Set<Int>()

    func play(_ script: DemoScript, on controller: SynthController) {
        stop()
        self.script = script
        self.controller = controller
        controller.setRouting(script.routing)
        controller.apply(script.startPatch)
        firedOn.removeAll(); firedOff.removeAll()
        startDate = Date()
        isPlaying = true
        progress = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.step()
        }
    }

    func stop() {
        timer?.invalidate(); timer = nil
        if isPlaying { controller?.allOff() }
        isPlaying = false
    }

    private func step() {
        guard let script, let controller else { return }
        let t = Date().timeIntervalSince(startDate)
        progress = min(1, t / script.duration)

        for lane in script.lanes {
            if let v = lane.value(at: t) { controller.set(lane.param, v) }
        }
        for (i, n) in script.notes.enumerated() {
            if t >= n.t && !firedOn.contains(i) { firedOn.insert(i); controller.noteOn(n.midi) }
            if t >= n.t + n.dur && !firedOff.contains(i) { firedOff.insert(i); controller.noteOff(n.midi) }
        }

        if t >= script.duration {
            controller.allOff()
            timer?.invalidate(); timer = nil
            isPlaying = false
            progress = 1
        }
    }
}
