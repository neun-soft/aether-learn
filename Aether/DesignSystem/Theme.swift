import SwiftUI

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
}

// MARK: - Theme tokens (matched to the Aether app)

enum Theme {
    static let bgTop = Color(hex: "12151f")
    static let bgBottom = Color(hex: "0a0c12")

    static var bgGradient: LinearGradient {
        LinearGradient(
            stops: [.init(color: bgTop, location: 0), .init(color: bgBottom, location: 1)],
            startPoint: UnitPoint(x: 0.10, y: 0),
            endPoint: UnitPoint(x: -0.10, y: 1)
        )
    }

    static let panel = Color(hex: "161a24")
    static let panelAlt = Color(hex: "13161e")
    static let inset = Color(hex: "1c212d")
    static func hairline(_ a: Double = 0.06) -> Color { Color.white.opacity(a) }

    static let textPrimary = Color(hex: "eef1f7")
    static let textSecondary = Color(hex: "cfd4dd")
    static let textMuted = Color(hex: "9aa0ad")
    static let textDim = Color(hex: "6c7689")
    static let textFaint = Color(hex: "5a606e")

    static let rec = Color(hex: "e8553a")

    // Concept accents (borrowed from the app's layer palette)
    static let basics = Color(hex: "9db4d0")   // how sound works
    static let playback = Color(hex: "e39a5b") // speakers & gear
    static let tone = Color(hex: "5b9dff")     // oscillators
    static let filter = Color(hex: "c79bff")   // subtractive
    static let shape = Color(hex: "e8c07d")    // envelopes
    static let motion = Color(hex: "7fd6a0")   // modulation

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
