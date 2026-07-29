import SwiftUI
import UIKit

// MARK: - Color from hex

extension Color {
    init(hex: String, opacity: Double = 1) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var v: UInt64 = 0
        Scanner(string: h).scanHexInt64(&v)
        let r = Double((v & 0xFF0000) >> 16) / 255
        let g = Double((v & 0x00FF00) >> 8) / 255
        let b = Double(v & 0x0000FF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }

    /// Resolves against the active colour scheme, so a Theme token repaints itself
    /// when the appearance changes and no call site has to know which palette is live.
    static func dyn(light: Color, dark: Color) -> Color {
        Color(uiColor: UIColor { traits in
            UIColor(traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

// MARK: - Palettes
//
// Two full token sets. `dark` is the original deep-navy look; `light` ("Moonstone")
// is a matte warm-white with earthy accents. Layout, type, radii and the
// one-accent-per-module system are shared — only these values differ.

struct Palette {
    // Screen. In light both stops are equal, so `bgGradient` paints a flat matte fill.
    let bgTop: Color
    let bgBottom: Color

    // Surfaces
    let panel: Color
    let panelAlt: Color
    let inset: Color

    /// Base for hairlines and translucent washes: white on dark, warm ink on light.
    let ink: Color
    /// Scales wash alphas — warm ink needs a little more presence on white than white does on navy.
    let inkBoost: Double

    /// Recessed bed behind graphs and scopes.
    let plot: Color
    /// Soft lift under cards. Clear on dark, where the panels already separate themselves.
    let cardShadow: Color
    let dropShadow: Color

    // Text
    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color
    let textDim: Color
    let textFaint: Color

    /// The light theme's signal colour — gold, for the eyebrow and module percentages.
    /// On dark it stays dim text, so the dark theme is unchanged.
    let signal: Color

    let rec: Color

    // Concept accents (one per module)
    let basics: Color
    let playback: Color
    let tone: Color
    let filter: Color
    let shape: Color
    let motion: Color

    static let dark = Palette(
        bgTop: Color(hex: "12151f"),
        bgBottom: Color(hex: "0a0c12"),
        panel: Color(hex: "161a24"),
        panelAlt: Color(hex: "13161e"),
        inset: Color(hex: "1c212d"),
        ink: .white,
        inkBoost: 1.0,
        plot: Color(.sRGB, white: 0, opacity: 0.28),
        cardShadow: .clear,
        dropShadow: Color(.sRGB, white: 0, opacity: 0.35),
        textPrimary: Color(hex: "eef1f7"),
        textSecondary: Color(hex: "cfd4dd"),
        textMuted: Color(hex: "9aa0ad"),
        textDim: Color(hex: "6c7689"),
        textFaint: Color(hex: "5a606e"),
        signal: Color(hex: "6c7689"),
        rec: Color(hex: "e8553a"),
        basics: Color(hex: "9db4d0"),
        playback: Color(hex: "e39a5b"),
        tone: Color(hex: "5b9dff"),
        filter: Color(hex: "c79bff"),
        shape: Color(hex: "e8c07d"),
        motion: Color(hex: "7fd6a0")
    )

    static let light = Palette(
        bgTop: Color(hex: "f6f3ee"),
        bgBottom: Color(hex: "f6f3ee"),   // equal stops = flat matte, no gradient
        panel: Color(hex: "fdfbf7"),
        panelAlt: Color(hex: "f7f3ea"),
        inset: Color(hex: "efe9de"),
        ink: Color(.sRGB, red: 60 / 255, green: 50 / 255, blue: 35 / 255, opacity: 1),
        inkBoost: 1.5,
        plot: Color(hex: "efe9de"),
        cardShadow: Color(.sRGB, red: 60 / 255, green: 45 / 255, blue: 25 / 255, opacity: 0.10),
        dropShadow: Color(.sRGB, red: 60 / 255, green: 45 / 255, blue: 25 / 255, opacity: 0.14),
        textPrimary: Color(hex: "2a2620"),
        textSecondary: Color(hex: "4a443a"),
        textMuted: Color(hex: "8c8478"),
        textDim: Color(hex: "a9a093"),
        textFaint: Color(hex: "c1b9ac"),
        signal: Color(hex: "b08d4c"),     // gold
        rec: Color(hex: "c0533a"),
        basics: Color(hex: "8a9a78"),     // sage
        playback: Color(hex: "c08a5e"),   // clay
        tone: Color(hex: "b08d4c"),       // gold — progress, tint
        filter: Color(hex: "9a8bb0"),     // muted lavender
        shape: Color(hex: "c2a24e"),      // ochre
        motion: Color(hex: "6f9068")      // moss
    )
}

// MARK: - Appearance

// Two states, not three. The app picks a side and the user flips it; "follow the device"
// is a third thing to reason about for a preference that takes one tap to correct.
enum Appearance: String, CaseIterable, Identifiable {
    case light, dark
    var id: String { rawValue }

    var scheme: ColorScheme { self == .dark ? .dark : .light }

    /// The icon shows what you'd get by tapping, not the state you're in.
    var icon: String { self == .dark ? "sun.max.fill" : "moon.fill" }

    var next: Appearance { self == .dark ? .light : .dark }
}

final class ThemeStore: ObservableObject {
    // Dark is the default: it's the look the icon and the App Store screenshots sell, and
    // the one the instrument visuals were drawn against. Anyone who already flipped this
    // keeps their choice — @AppStorage only falls back to the default when nothing is stored.
    @AppStorage("aether.appearance") var appearance: Appearance = .dark {
        willSet { objectWillChange.send() }
    }
}

// MARK: - Theme tokens (matched to the Aether app)
//
// Every colour token resolves against the active scheme, so flipping the appearance
// repaints the whole app without a single call site changing.

enum Theme {
    static let bgTop = Color.dyn(light: Palette.light.bgTop, dark: Palette.dark.bgTop)
    static let bgBottom = Color.dyn(light: Palette.light.bgBottom, dark: Palette.dark.bgBottom)

    /// Flat matte fill on light (the stops are equal), the 168° gradient on dark.
    static var bgGradient: LinearGradient {
        LinearGradient(
            stops: [.init(color: bgTop, location: 0), .init(color: bgBottom, location: 1)],
            startPoint: UnitPoint(x: 0.10, y: 0),
            endPoint: UnitPoint(x: -0.10, y: 1)
        )
    }

    static let panel = Color.dyn(light: Palette.light.panel, dark: Palette.dark.panel)
    static let panelAlt = Color.dyn(light: Palette.light.panelAlt, dark: Palette.dark.panelAlt)
    static let inset = Color.dyn(light: Palette.light.inset, dark: Palette.dark.inset)

    /// A translucent wash over whatever sits behind it.
    static func wash(_ a: Double) -> Color {
        Color.dyn(light: Palette.light.ink.opacity(min(0.95, a * Palette.light.inkBoost)),
                  dark: Palette.dark.ink.opacity(a))
    }
    static func hairline(_ a: Double = 0.06) -> Color { wash(a) }
    static let hairlineStrong = Color.dyn(light: Palette.light.ink.opacity(0.14),
                                          dark: Palette.dark.ink.opacity(0.13))

    /// Recessed bed behind graphs, scopes and canvases.
    static let plot = Color.dyn(light: Palette.light.plot, dark: Palette.dark.plot)
    static let cardShadow = Color.dyn(light: Palette.light.cardShadow, dark: Palette.dark.cardShadow)
    static let dropShadow = Color.dyn(light: Palette.light.dropShadow, dark: Palette.dark.dropShadow)

    static let textPrimary = Color.dyn(light: Palette.light.textPrimary, dark: Palette.dark.textPrimary)
    static let textSecondary = Color.dyn(light: Palette.light.textSecondary, dark: Palette.dark.textSecondary)
    static let textMuted = Color.dyn(light: Palette.light.textMuted, dark: Palette.dark.textMuted)
    static let textDim = Color.dyn(light: Palette.light.textDim, dark: Palette.dark.textDim)
    static let textFaint = Color.dyn(light: Palette.light.textFaint, dark: Palette.dark.textFaint)

    /// Gold on light, dim text on dark.
    static let signal = Color.dyn(light: Palette.light.signal, dark: Palette.dark.signal)

    /// Piano keys. Still reads as a keyboard in both themes, but the white key
    /// warms up on light instead of staying the dark theme's cool blue-grey.
    static let keyWhite = Color.dyn(light: Color(hex: "fbf8f2"), dark: Color(hex: "d7dce6"))
    static let keyBlack = Color.dyn(light: Color(hex: "2f2b24"), dark: Color(hex: "1a1e28"))

    /// High-contrast handles: slider knobs, playheads, the cutoff node.
    static let handle = textPrimary
    /// Glyphs and labels sitting on a filled accent — the accents are mid-tone in both palettes.
    static let onAccent = Color.black

    static let rec = Color.dyn(light: Palette.light.rec, dark: Palette.dark.rec)

    // Concept accents (borrowed from the app's layer palette)
    static let basics = Color.dyn(light: Palette.light.basics, dark: Palette.dark.basics)       // how sound works
    static let playback = Color.dyn(light: Palette.light.playback, dark: Palette.dark.playback) // speakers & gear
    static let tone = Color.dyn(light: Palette.light.tone, dark: Palette.dark.tone)             // oscillators
    static let filter = Color.dyn(light: Palette.light.filter, dark: Palette.dark.filter)       // subtractive
    static let shape = Color.dyn(light: Palette.light.shape, dark: Palette.dark.shape)          // envelopes
    static let motion = Color.dyn(light: Palette.light.motion, dark: Palette.dark.motion)       // modulation

    static let rCard: CGFloat = 18
    static let rRow: CGFloat = 16
    static let rPill: CGFloat = 11
}

// MARK: - Fonts

enum AppFont {
    static let display = "Space Grotesk"
    static let mono = "JetBrains Mono"

    static func ui(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        Font.custom(display, size: size).weight(weight)
    }
    static func data(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        Font.custom(mono, size: size).weight(weight)
    }
}

extension Text {
    func ui(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Text { font(AppFont.ui(size, weight)) }
    func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Text { font(AppFont.data(size, weight)) }
}
