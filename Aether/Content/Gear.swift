import Foundation

// Approximate low/high frequency limits of common playback gear (Hz). These are teaching
// figures, not spec sheets: the point is the shape of the trade-off, not exact numbers.
struct Gear: Identifiable {
    let id: String
    let name: String
    let short: String
    let low: Double
    let high: Double
    let blurb: String
}

enum Playback {
    static let gear: [Gear] = [
        Gear(id: "phone", name: "Phone speaker", short: "Phone", low: 500, high: 12000,
             blurb: "Tiny drivers can't move much air, so there is almost no bass. Fine for voices, weak for music."),
        Gear(id: "earbuds", name: "AirPods / earbuds", short: "Earbuds", low: 60, high: 18000,
             blurb: "Small drivers, but sealed in your ear canal, so they reach more low end than a phone speaker."),
        Gear(id: "headphones", name: "Studio headphones", short: "Headphones", low: 15, high: 22000,
             blurb: "Larger drivers right next to your ears reproduce the full range, deep bass included."),
        Gear(id: "monitors", name: "Studio monitors", short: "Monitors", low: 45, high: 22000,
             blurb: "Accurate speakers built to tell the truth about a mix rather than flatter it."),
        Gear(id: "jbl", name: "Bluetooth speaker", short: "Bluetooth", low: 65, high: 20000,
             blurb: "Loud with boosted, punchy bass, but it colors the sound and still misses the lowest notes."),
        Gear(id: "club", name: "Club system with subs", short: "Club rig", low: 28, high: 20000,
             blurb: "Big subwoofers move enough air to make the deep bass you feel in your chest, not just hear.")
    ]

    static func gear(_ id: String) -> Gear { gear.first { $0.id == id } ?? gear[0] }

    struct Scenario: Identifiable { let id: String; let title: String; let gearID: String; let why: String }
    static let scenarios: [Scenario] = [
        Scenario(id: "mix", title: "Mixing a track to release", gearID: "monitors",
                 why: "Monitors are honest, so choices you make translate to other systems."),
        Scenario(id: "club", title: "A techno night at a club", gearID: "club",
                 why: "Only big subs move the air needed for deep bass a crowd can feel."),
        Scenario(id: "commute", title: "Listening on a noisy commute", gearID: "earbuds",
                 why: "Sealed earbuds are portable and keep outside noise out."),
        Scenario(id: "worst", title: "Checking a mix survives cheap gear", gearID: "phone",
                 why: "The phone speaker is the worst case. If it holds up there, it holds up anywhere.")
    ]
}
