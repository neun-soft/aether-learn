import SwiftUI

// Navigation targets pushed onto the NavigationStack path.
enum Route: Hashable {
    case lesson(Int)        // index into Curriculum.flat
    case congrats(String)   // module id
}

// Content and progress are separate models: content is static data shipped in the binary,
// progress is per-user state persisted locally. Updating a lesson never wipes progress.

enum LessonVisual { case none, scope, spectrum, additive, detune, bee, door, filter, envelope, lfo, equipment, output, match, beating }

// Configures the frequency-explorer control for the frequency/pitch lessons.
struct ToneConfig {
    var minHz: Double
    var maxHz: Double
    var startNorm: Double
    var snap: Bool
}

// Maps a 0…1 slider position to a frequency (log scale), snapping to the nearest note if asked.
func frequencyFor(_ c: ToneConfig, norm: Double) -> Double {
    let raw = c.minHz * pow(c.maxHz / c.minHz, norm)
    guard c.snap else { return raw }
    let midi = (69.0 + 12.0 * log2(raw / 440.0)).rounded()
    return 440.0 * pow(2.0, (midi - 69.0) / 12.0)
}

struct Exercise {
    var prompt: String
    var visibleParams: [ParamID]
    var basePatch: Patch
    var visual: LessonVisual = .none                    // big audio-reactive display
    var wavePresets: Bool = false                       // sine/tri/saw/square shape buttons
    var filterTypePicker: Bool = false                  // LP/HP/BP/notch icon buttons
    var tone: ToneConfig? = nil                         // if set, show the frequency explorer
    var showRouting: Bool = false                       // show the source/dest picker
    var initialRouting: Routing = .off                  // routing applied on load
    var allowedSources: [ModSource] = ModSource.allCases
    var allowedDests: [ModDest] = ModDest.allCases
    var showKeyboard: Bool = true
    var keyboardRoot: Int = 48                          // lowest key on the keyboard
    var showOctave: Bool = true                         // octave up/down buttons
    var holdDefault: Bool = true                        // start with keep-note-playing on?
    var showSystemVolume: Bool = false                  // live phone-volume readout
    var showBassTest: Bool = false                      // sub-bass + kick test buttons
    var tip: String? = nil                              // an idea/tip callout
    var controlsHint: String? = nil                     // one line above the knobs saying what they are
    var labels: [ParamID: String] = [:]                 // per-lesson knob label overrides
}

struct Lesson: Identifiable {
    let id: String
    let title: String
    let concept: String            // one-line "what you'll learn"
    let theory: [String]           // paragraphs
    let takeaways: [String]
    let demo: DemoScript?
    let exercise: Exercise
}

struct Module: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let accent: Color
    let lessons: [Lesson]
}

struct Course: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let modules: [Module]

    var allLessons: [Lesson] { modules.flatMap { $0.lessons } }
}

// MARK: - Progress (persisted)

final class ProgressStore: ObservableObject {
    @Published private(set) var completed: Set<String> = []
    @Published var lastLessonID: String?

    private let key = "aetherlearn.progress.v1"

    init() { load() }

    func isDone(_ lessonID: String) -> Bool { completed.contains(lessonID) }

    func markDone(_ lessonID: String) {
        completed.insert(lessonID)
        save()
    }

    func moduleProgress(_ module: Module) -> Double {
        guard !module.lessons.isEmpty else { return 0 }
        let done = module.lessons.filter { completed.contains($0.id) }.count
        return Double(done) / Double(module.lessons.count)
    }

    func courseProgress(_ course: Course) -> Double {
        let all = course.allLessons
        guard !all.isEmpty else { return 0 }
        let done = all.filter { completed.contains($0.id) }.count
        return Double(done) / Double(all.count)
    }

    private func save() {
        let payload = ["completed": Array(completed), "last": lastLessonID.map { [$0] } ?? []]
        if let data = try? JSONSerialization.data(withJSONObject: payload) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: [String]]
        else { return }
        completed = Set(obj["completed"] ?? [])
        lastLessonID = obj["last"]?.first
    }
}
