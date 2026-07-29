import SwiftUI

// MARK: - What makes a sound a hit

/// The envelope drawn as a shape you could describe out loud, with the three things that make it
/// percussive called out by name on the drawing itself: it starts instantly, it never holds, and
/// it is over quickly. A plain envelope graph shows the same numbers but does not make the point.
struct HitShapeView: View {
    var attack: Double
    var decay: Double
    var sustain: Double
    var playhead: Double     // seconds since the note started, negative when silent
    var accent: Color

    /// Same mapping the voice uses, so the drawing is the real envelope.
    private var attackSec: Double { 0.002 + pow(attack, 2) * 3.0 }
    private var decaySec: Double { 0.005 + pow(decay, 2) * 3.0 }
    private var isPercussive: Bool { attackSec < 0.05 && sustain < 0.08 && decaySec < 0.6 }
    private let window = 1.6

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("LOUDNESS OVER TIME").mono(9, .semibold).tracking(1.2).foregroundColor(Theme.textDim)
                Spacer()
                Text(isPercussive ? "this is a hit" : "this is still a note")
                    .mono(9, .semibold)
                    .foregroundColor(isPercussive ? accent : Theme.textMuted)
            }

            GeometryReader { g in
                ZStack {
                    Path { p in
                        let n = 240
                        p.move(to: CGPoint(x: 0, y: g.size.height))
                        for i in 0...n {
                            let t = Double(i) / Double(n) * window
                            let v: Double
                            if t < attackSec {
                                v = attackSec <= 0 ? 1 : t / attackSec
                            } else if t < attackSec + decaySec {
                                let p2 = (t - attackSec) / max(0.0001, decaySec)
                                v = 1 + (sustain - 1) * p2
                            } else {
                                v = sustain
                            }
                            p.addLine(to: CGPoint(x: g.size.width * (t / window),
                                                  y: g.size.height * (1 - v * 0.9)))
                        }
                        p.addLine(to: CGPoint(x: g.size.width, y: g.size.height))
                        p.closeSubpath()
                    }
                    .fill(LinearGradient(colors: [accent.opacity(0.45), accent.opacity(0.06)],
                                         startPoint: .top, endPoint: .bottom))

                    // Where we are right now, so a tap shows the shape being traced out.
                    if playhead >= 0, playhead < window {
                        let x = g.size.width * (playhead / window)
                        Path { p in
                            p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: g.size.height))
                        }
                        .stroke(Theme.textPrimary.opacity(0.8), lineWidth: 1.5)
                    }

                    // The two facts that make it a hit, marked on the drawing.
                    if isPercussive {
                        Text("starts instantly").mono(8).foregroundColor(Theme.textMuted)
                            .position(x: 62, y: 16)
                        Text("nothing left to hold").mono(8).foregroundColor(Theme.textMuted)
                            .position(x: g.size.width * 0.66, y: g.size.height - 14)
                    }
                }
            }
            .frame(height: 128)
            .background(Theme.inset)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(isPercussive
                 ? "Straight up, straight down, gone. That shape is what percussive means."
                 : "Bring DECAY down and SUSTAIN to zero and watch it turn into a hit.")
                .mono(9).foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Hi-hat: cutting the bottom off noise

/// Noise drawn as a full block of frequencies, with everything below the cutoff visibly removed.
/// The point is that nothing is being added: a hat is noise with its bottom taken away.
struct HighPassNoiseView: View {
    var cutoff: Double
    var decay: Double
    var accent: Color

    private var cutoffHz: Double { 60.0 * pow(2.0, clamp01(cutoff) * 8.0) }
    private var decaySec: Double { 0.005 + pow(decay, 2) * 3.0 }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("EVERY FREQUENCY IN THE SOUND").mono(9, .semibold).tracking(1.2)
                    .foregroundColor(Theme.textDim)
                Spacer()
                Text(decaySec < 0.12 ? "closed hat" : (decaySec < 0.45 ? "half open" : "open hat"))
                    .mono(9, .semibold).foregroundColor(accent)
            }

            GeometryReader { g in
                let n = 44
                // Where the cutoff sits along the drawn range, on the same log scale as the filter.
                let cutFrac = clamp01(log2(cutoffHz / 60) / 8)
                ZStack(alignment: .bottomLeading) {
                    HStack(alignment: .bottom, spacing: 1.5) {
                        ForEach(0..<n, id: \.self) { i in
                            let f = Double(i) / Double(n - 1)
                            // Noise is flat; the high-pass removes what sits below the cutoff.
                            let kept = f < cutFrac ? max(0, 1 - (cutFrac - f) * 9) : 1.0
                            RoundedRectangle(cornerRadius: 1)
                                .fill(kept > 0.05 ? accent.opacity(0.75) : Theme.textDim.opacity(0.16))
                                .frame(width: max(1, g.size.width / CGFloat(n) - 1.5),
                                       height: max(2, g.size.height * (0.15 + 0.8 * kept)))
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)

                    // The line the filter is cutting at.
                    let x = g.size.width * cutFrac
                    Path { p in p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: g.size.height)) }
                        .stroke(Theme.textPrimary.opacity(0.75), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                }
            }
            .frame(height: 118)
            .background(Theme.inset)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack {
                Text("low — thrown away").mono(9).foregroundColor(Theme.textDim)
                Spacer()
                Text("high — kept").mono(9).foregroundColor(accent)
            }
        }
    }
}

// MARK: - Snare: two sounds at once

/// A balance drawn as two stacked blocks whose sizes follow the Noise knob, because the entire
/// lesson is that a snare is one part drum and one part rattle, and the knob decides the ratio.
struct SnareMixView: View {
    var noise: Double
    var accent: Color

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("WHAT IS IN THE HIT").mono(9, .semibold).tracking(1.2).foregroundColor(Theme.textDim)
                Spacer()
                Text(noise < 0.3 ? "mostly drum: a soft thud"
                     : (noise > 0.75 ? "mostly rattle: a thin crack" : "both: a snare"))
                    .mono(9, .semibold)
                    .foregroundColor(noise >= 0.3 && noise <= 0.75 ? accent : Theme.textMuted)
            }

            GeometryReader { g in
                VStack(spacing: 4) {
                    block(height: g.size.height * (1 - clamp01(noise)) - 2,
                          title: "THE DRUM SKIN", subtitle: "a real note, around 200 times a second",
                          fill: accent.opacity(0.75), wave: true, width: g.size.width)
                    block(height: g.size.height * clamp01(noise) - 2,
                          title: "THE WIRES UNDERNEATH", subtitle: "noise: a rattle, no note in it",
                          fill: Theme.textDim.opacity(0.55), wave: false, width: g.size.width)
                }
            }
            .frame(height: 128)
        }
    }

    @ViewBuilder private func block(height: CGFloat, title: String, subtitle: String,
                                    fill: Color, wave: Bool, width: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(fill.opacity(0.28))
            RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(fill, lineWidth: 1)
            if height > 34 {
                VStack(spacing: 2) {
                    Text(title).mono(9, .semibold).tracking(1).foregroundColor(Theme.textPrimary)
                    Text(subtitle).mono(8).foregroundColor(Theme.textDim)
                }
                .padding(.horizontal, 8)
                .multilineTextAlignment(.center)
            }
        }
        .frame(width: width, height: max(0, height))
        .clipped()
    }
}

// MARK: - Kick: the pitch falling at the very start

/// Pitch plotted against time, so the drop that makes a kick sound struck is a shape rather than
/// a claim. Depth moves how far it falls; decay moves how long the fall takes.
struct PitchDropView: View {
    var depth: Double        // modulation depth, how far the pitch falls
    var decay: Double        // envelope decay, how long the fall lasts
    var accent: Color

    private var decaySec: Double { 0.005 + pow(decay, 2) * 3.0 }
    private let window = 0.6

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("PITCH OVER TIME").mono(9, .semibold).tracking(1.2).foregroundColor(Theme.textDim)
                Spacer()
                Text(decaySec < 0.09 ? "a click at the front"
                     : (decaySec > 0.35 ? "a slide you can follow" : "a kick"))
                    .mono(9, .semibold)
                    .foregroundColor(decaySec >= 0.09 && decaySec <= 0.35 ? accent : Theme.textMuted)
            }

            GeometryReader { g in
                ZStack {
                    // Where the note settles: the pitch you would have had with no drop at all.
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: g.size.height * 0.82))
                        p.addLine(to: CGPoint(x: g.size.width, y: g.size.height * 0.82))
                    }
                    .stroke(Theme.textDim.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

                    Path { p in
                        let n = 200
                        for i in 0...n {
                            let t = Double(i) / Double(n) * window
                            // The envelope falls from 1 to 0 over the decay, and it is driving pitch.
                            let env = t < decaySec ? 1 - (t / max(0.0001, decaySec)) : 0
                            let y = g.size.height * (0.82 - env * clamp01(depth) * 0.72)
                            let pt = CGPoint(x: g.size.width * (t / window), y: y)
                            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                        }
                    }
                    .stroke(accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

                    Text("starts high").mono(8).foregroundColor(Theme.textMuted)
                        .position(x: 48, y: max(10, g.size.height * (0.82 - clamp01(depth) * 0.72) - 12))
                    Text("settles here").mono(8).foregroundColor(Theme.textDim)
                        .position(x: g.size.width - 46, y: g.size.height * 0.82 - 12)
                }
            }
            .frame(height: 126)
            .background(Theme.inset)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text("That fall at the start is the beater hitting the skin. Without it you have a hum.")
                .mono(9).foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity)
        }
    }
}
