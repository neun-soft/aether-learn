import SwiftUI

// MARK: - The Bee (vibration → pitch)
//
// The flapping wings stand in for a vibrating speaker cone: the faster it moves
// back and forth, the higher the note. A "flap speed" slider sets both the wing
// rate and the buzz pitch, so you see and hear the same idea.

struct BeeView: View {
    @Binding var norm: Double            // 0…1 flap speed
    var buzzing: Bool
    var accent: Color
    var onHz: (Double) -> Void           // push the pitch as the slider moves
    var onToggle: () -> Void             // start/stop the buzz

    // Map the slider to a bee-ish pitch range (a real honeybee buzzes ~230 Hz).
    private func hz(_ n: Double) -> Double { 40.0 * pow(360.0 / 40.0, n) }
    // Visible wingbeat, decoupled from audio so it stays watchable: slow flaps
    // you can count at the bottom, a blur at the top.
    private var flapHz: Double { 2.0 + norm * 15.0 }

    var body: some View {
        VStack(spacing: 16) {
            TimelineView(.animation) { tl in
                Canvas { ctx, size in
                    let t = tl.date.timeIntervalSinceReferenceDate
                    let wing = sin(t * flapHz * 2 * .pi)          // -1…1
                    drawBee(ctx, size, wing: wing)
                }
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.28))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline(), lineWidth: 1))
                .overlay(alignment: .topLeading) {
                    Text(buzzing ? "\(Int(hz(norm))) Hz" : "tap to buzz")
                        .mono(11, .semibold).foregroundColor(buzzing ? accent : Theme.textDim)
                        .padding(10)
                }
            }

            Button(action: onToggle) {
                HStack(spacing: 8) {
                    Image(systemName: buzzing ? "stop.fill" : "play.fill")
                    Text(buzzing ? "Stop" : "Buzz")
                }
                .font(AppFont.ui(15, .semibold)).foregroundColor(buzzing ? .black : Theme.textPrimary)
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(buzzing ? accent : Theme.inset)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            VStack(spacing: 6) {
                Text("FLAP SPEED").mono(10, .semibold).tracking(1.5).foregroundColor(Theme.textDim)
                AnalogySlider(value: $norm, accent: accent) { n in onHz(hz(n)) }
                HStack {
                    Text("slow · low").mono(9).foregroundColor(Theme.textFaint)
                    Spacer()
                    Text("fast · high").mono(9).foregroundColor(Theme.textFaint)
                }
            }
        }
        .onAppear { onHz(hz(norm)) }
    }

    private func drawBee(_ ctx: GraphicsContext, _ size: CGSize, wing: Double) {
        let cx = size.width / 2, cy = size.height * 0.60
        let bodyW = 92.0, bodyH = 60.0

        // Motion shimmer behind the bee when flapping fast.
        if norm > 0.55 {
            for i in 1...3 {
                let off = Double(i) * 10
                let rect = CGRect(x: cx - bodyW/2 - off, y: cy - bodyH/2, width: bodyW, height: bodyH)
                ctx.stroke(Path(ellipseIn: rect), with: .color(Theme.textFaint.opacity(0.12 * norm)), lineWidth: 2)
            }
        }

        // Wings: two long translucent wings hinged at the upper back, fanning up
        // and out and beating together. Drawn before the body so their roots tuck
        // behind it. wing (-1…1) sweeps them up on the upbeat.
        let hinge = CGPoint(x: cx + 16, y: cy - bodyH * 0.34)
        let flap = wing * 0.5
        // right wing (extends up-right)
        do {
            var w = ctx
            w.translateBy(x: hinge.x, y: hinge.y)
            w.rotate(by: .radians(-0.62 - flap))
            let r = CGRect(x: 2, y: -18, width: 84, height: 34)
            w.fill(Path(ellipseIn: r), with: .color(.white.opacity(0.30)))
            w.stroke(Path(ellipseIn: r), with: .color(.white.opacity(0.55)), lineWidth: 1.3)
        }
        // left wing (extends up-left)
        do {
            var w = ctx
            w.translateBy(x: hinge.x, y: hinge.y)
            w.rotate(by: .radians(0.62 + flap))
            let r = CGRect(x: -86, y: -18, width: 84, height: 34)
            w.fill(Path(ellipseIn: r), with: .color(.white.opacity(0.30)))
            w.stroke(Path(ellipseIn: r), with: .color(.white.opacity(0.55)), lineWidth: 1.3)
        }

        // Body: amber ellipse with dark stripes.
        let bodyRect = CGRect(x: cx - bodyW/2, y: cy - bodyH/2, width: bodyW, height: bodyH)
        let body = Path(ellipseIn: bodyRect)
        ctx.fill(body, with: .color(Theme.shape))
        ctx.drawLayer { layer in
            layer.clip(to: body)
            for k in 0..<3 {
                let x = bodyRect.minX + bodyW * (0.32 + Double(k) * 0.2)
                let stripe = CGRect(x: x, y: bodyRect.minY - 4, width: bodyW * 0.1, height: bodyH + 8)
                layer.fill(Path(stripe), with: .color(.black.opacity(0.65)))
            }
        }
        ctx.stroke(body, with: .color(.black.opacity(0.35)), lineWidth: 1.5)

        // Little head + eye on the left.
        let head = CGRect(x: bodyRect.minX - 22, y: cy - 16, width: 30, height: 32)
        ctx.fill(Path(ellipseIn: head), with: .color(Theme.shape.opacity(0.95)))
        ctx.fill(Path(ellipseIn: CGRect(x: head.minX + 6, y: head.midY - 4, width: 7, height: 7)),
                 with: .color(.black.opacity(0.7)))
    }
}

// MARK: - The Door (low-pass filter cutoff)
//
// Closing a door on a room muffles the sound: the highs are shut out first while
// the bass leaks through. The door's opening tracks the cutoff — wide open is
// bright, nearly shut is dark.

struct DoorView: View {
    @Binding var cutoff: Double          // 0…1, same value the filter uses
    var accent: Color
    var height: CGFloat = 190

    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSinceReferenceDate
                draw(ctx, size, t: t)
            }
        }
        .frame(height: height)
        .background(Color.black.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline(), lineWidth: 1))
        .overlay(alignment: .topLeading) {
            Text(cutoff > 0.66 ? "door open · bright"
                 : cutoff > 0.33 ? "half closed · muffled" : "shut · dark")
                .mono(11, .semibold).foregroundColor(accent).padding(10)
        }
        .animation(.easeOut(duration: 0.15), value: cutoff)
    }

    private func draw(_ ctx: GraphicsContext, _ size: CGSize, t: Double) {
        let w = size.width, h = size.height
        // Speaker on the left, inside the room.
        let spk = CGRect(x: 34, y: h/2 - 26, width: 26, height: 52)
        ctx.fill(Path(roundedRect: spk, cornerRadius: 5), with: .color(Theme.inset))
        ctx.stroke(Path(roundedRect: spk, cornerRadius: 5), with: .color(Theme.hairline(0.4)), lineWidth: 1)
        ctx.fill(Path(ellipseIn: CGRect(x: spk.midX - 8, y: spk.midY - 8, width: 16, height: 16)),
                 with: .color(accent.opacity(0.8)))

        // Sound rings travelling right. More rings, and brighter, when the door is open
        // (highs get through); nearly gone when shut (only muffled lows leak).
        let bright = cutoff
        let doorX = w * 0.66
        for i in 0..<5 {
            let phase = (t * 0.7 + Double(i) * 0.22).truncatingRemainder(dividingBy: 1)
            let x = spk.maxX + CGFloat(phase) * (w - spk.maxX - 30)
            let past = x > doorX
            // Rings past the door are attenuated by how closed it is.
            let alpha = (past ? 0.15 + 0.55 * bright : 0.55) * (1 - phase * 0.5)
            let r = 10 + CGFloat(phase) * 40
            ctx.stroke(Path(ellipseIn: CGRect(x: x - r/2, y: h/2 - r/2, width: r/2, height: r)),
                       with: .color(accent.opacity(max(0, alpha))), lineWidth: 2)
        }

        // Doorframe on the right, and the swinging door.
        ctx.stroke(Path { p in
            p.move(to: CGPoint(x: doorX, y: 18)); p.addLine(to: CGPoint(x: doorX, y: h - 18))
        }, with: .color(Theme.hairline(0.5)), lineWidth: 2)

        // Door hinged at the top of the frame, swinging shut as cutoff drops.
        let openAngle = (0.08 + cutoff * 0.82) * Double.pi / 2   // ~90° open → ~5° shut
        var d = ctx
        d.translateBy(x: doorX, y: h/2)
        d.rotate(by: .radians(-.pi / 2 + openAngle))            // 0 = flat/open toward viewer
        let doorLen = h * 0.62
        let doorRect = CGRect(x: -6, y: -doorLen/2, width: 12, height: doorLen)
        d.fill(Path(roundedRect: doorRect, cornerRadius: 3),
               with: .linearGradient(
                Gradient(colors: [Theme.panel, Theme.panelAlt]),
                startPoint: CGPoint(x: -6, y: 0), endPoint: CGPoint(x: 6, y: 0)))
        d.stroke(Path(roundedRect: doorRect, cornerRadius: 3), with: .color(accent.opacity(0.5)), lineWidth: 1.5)
        // handle
        d.fill(Path(ellipseIn: CGRect(x: -3, y: doorLen/2 - 16, width: 6, height: 6)),
               with: .color(accent))
    }
}

// MARK: - Shared minimal slider for the analogy widgets

struct AnalogySlider: View {
    @Binding var value: Double
    var accent: Color
    var onChange: (Double) -> Void

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.hairline(0.1)).frame(height: 6)
                Capsule().fill(accent).frame(width: max(6, w * value), height: 6)
                Circle().fill(.white).frame(width: 22, height: 22)
                    .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
                    .offset(x: max(0, min(w - 22, w * value - 11)))
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                let v = min(1, max(0, g.location.x / w))
                value = v
                onChange(v)
            })
        }
        .frame(height: 26)
    }
}
