import Foundation

// DEBUG-only screenshot harness. Driven by environment variables so a simulator
// build can jump straight to a lesson, in a chosen phase, with a note playing —
// for capturing real in-app App Store screenshots. Compiled out of Release
// builds (the shipped binary), and inert unless AETHER_SHOT_LESSON is set.
enum Shot {
    static var lessonID: String? { env("AETHER_SHOT_LESSON") }
    static var phase: String { env("AETHER_SHOT_PHASE") ?? "play" }
    static var play: Bool { env("AETHER_SHOT_PLAY") == "1" }
    static var additive: Int? { env("AETHER_SHOT_ADDITIVE").flatMap { Int($0) } }
    static var noteOffset: Int { env("AETHER_SHOT_NOTE").flatMap { Int($0) } ?? 7 }
    static var active: Bool { lessonID != nil }

    private static func env(_ key: String) -> String? {
        let v = ProcessInfo.processInfo.environment[key]
        return (v?.isEmpty ?? true) ? nil : v
    }
}
