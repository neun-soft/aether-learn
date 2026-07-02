import SwiftUI

// A compact keyboard. It reports raw press/release (onDown/onUp); the caller decides whether
// that latches a note (keep-playing on) or plays only while held (keep-playing off), which is
// what you want when a lesson is about the lifespan of a note.
struct Keyboard: View {
    var latched: Int?
    let onDown: (Int) -> Void
    let onUp: (Int) -> Void
    var root: Int = 48
    var octaves: Int = 2
    var accent: Color = Theme.tone

    private let whitePattern = [0, 2, 4, 5, 7, 9, 11]
    private let blackOffsets = [1, 3, 6, 8, 10]
    private let blackAfterWhite = [0, 1, 3, 4, 5]

    private var whiteMidis: [Int] {
        var arr: [Int] = []
        for o in 0..<octaves { for p in whitePattern { arr.append(root + o * 12 + p) } }
        arr.append(root + octaves * 12)
        return arr
    }

    private struct BlackKey: Identifiable { let id = UUID(); let midi: Int; let boundary: Int }
    private var blackKeys: [BlackKey] {
        var arr: [BlackKey] = []
        for o in 0..<octaves {
            for (i, off) in blackOffsets.enumerated() {
                arr.append(BlackKey(midi: root + o * 12 + off, boundary: o * 7 + blackAfterWhite[i] + 1))
            }
        }
        return arr
    }

    var body: some View {
        GeometryReader { geo in
            let n = whiteMidis.count
            let w = (geo.size.width - CGFloat(n - 1) * 2) / CGFloat(n)
            ZStack(alignment: .topLeading) {
                HStack(spacing: 2) {
                    ForEach(whiteMidis, id: \.self) { m in
                        Key(midi: m, white: true, latched: latched, accent: accent, onDown: onDown, onUp: onUp)
                    }
                }
                ForEach(blackKeys) { bk in
                    Key(midi: bk.midi, white: false, latched: latched, accent: accent, onDown: onDown, onUp: onUp)
                        .frame(width: w * 0.62, height: geo.size.height * 0.62)
                        .offset(x: CGFloat(bk.boundary) * (w + 2) - w * 0.31 - 1)
                }
            }
        }
        .frame(height: 130)
    }

    private struct Key: View {
        let midi: Int
        let white: Bool
        let latched: Int?
        let accent: Color
        let onDown: (Int) -> Void
        let onUp: (Int) -> Void
        @State private var held = false

        var body: some View {
            let lit = held || latched == midi
            let fill: Color = lit ? accent : (white ? Color(hex: "d7dce6") : Color(hex: "1a1e28"))
            return RoundedRectangle(cornerRadius: white ? 7 : 5)
                .fill(fill)
                .overlay(RoundedRectangle(cornerRadius: white ? 7 : 5)
                    .stroke(Color.black.opacity(white ? 0.25 : 0.5), lineWidth: 1))
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in if !held { held = true; onDown(midi) } }
                        .onEnded { _ in held = false; onUp(midi) }
                )
        }
    }
}
