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
        let hinge = CGPoint(x: cx - 6, y: cy - bodyH * 0.34)
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
// Seen from outside: a doorway into a room where a speaker plays music. Drag the
// door open or closed. Open lets the bright highs through; closing it muffles the
// sound. The open amount is the filter cutoff.

struct DoorView: View {
    @Binding var cutoff: Double          // door open amount = cutoff
    var accent: Color
    var height: CGFloat = 300

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in draw(ctx, size) }
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                    cutoff = min(1, max(0, Double(g.location.x / geo.size.width)))
                })
        }
        .frame(height: height)
        .background(Color.black.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline(), lineWidth: 1))
        .overlay(alignment: .topLeading) {
            Text(cutoff > 0.66 ? "open · bright"
                 : cutoff > 0.33 ? "half open · muffled" : "shut · dark")
                .mono(11, .semibold).foregroundColor(accent).padding(10)
        }
        .overlay(alignment: .bottom) {
            Text("drag the door").mono(10).foregroundColor(Theme.textFaint).padding(.bottom, 8)
        }
        .animation(.easeOut(duration: 0.12), value: cutoff)
    }

    private func draw(_ ctx: GraphicsContext, _ size: CGSize) {
        let w = size.width, h = size.height
        let open = cutoff

        // The doorway opening in the wall.
        let dw = w * 0.46, dh = h * 0.80
        let doorway = CGRect(x: (w - dw) / 2, y: (h - dh) / 2, width: dw, height: dh)
        let frame = Path(roundedRect: doorway, cornerRadius: 10)

        // Room seen through the doorway: warmer than the wall, with a floor,
        // a table, a speaker, and music notes when the door is open.
        ctx.drawLayer { room in
            room.clip(to: frame)
            room.fill(frame, with: .color(Color(red: 0.12, green: 0.13, blue: 0.18)))
            // floor
            let floorTop = doorway.minY + dh * 0.62
            room.fill(Path { p in
                p.move(to: CGPoint(x: doorway.minX, y: doorway.maxY))
                p.addLine(to: CGPoint(x: doorway.maxX, y: doorway.maxY))
                p.addLine(to: CGPoint(x: doorway.maxX - dw * 0.12, y: floorTop))
                p.addLine(to: CGPoint(x: doorway.minX + dw * 0.12, y: floorTop))
                p.closeSubpath()
            }, with: .color(Color(red: 0.16, green: 0.17, blue: 0.23)))

            // table (top + two legs)
            let tCx = doorway.midX, tY = floorTop + dh * 0.06
            let topRect = CGRect(x: tCx - dw * 0.28, y: tY, width: dw * 0.56, height: dh * 0.05)
            room.fill(Path(roundedRect: topRect, cornerRadius: 3), with: .color(Theme.panel))
            for lx in [tCx - dw * 0.22, tCx + dw * 0.22 - dw * 0.04] {
                room.fill(Path(CGRect(x: lx, y: topRect.maxY, width: dw * 0.04, height: dh * 0.16)),
                          with: .color(Theme.panelAlt))
            }
            // speaker on the table
            let spk = CGRect(x: tCx - dw * 0.09, y: topRect.minY - dh * 0.16, width: dw * 0.18, height: dh * 0.16)
            room.fill(Path(roundedRect: spk, cornerRadius: 4), with: .color(Theme.inset))
            room.stroke(Path(roundedRect: spk, cornerRadius: 4), with: .color(Theme.hairline(0.4)), lineWidth: 1)
            room.fill(Path(ellipseIn: CGRect(x: spk.midX - dw * 0.05, y: spk.midY - dw * 0.05,
                                             width: dw * 0.1, height: dw * 0.1)),
                      with: .color(accent.opacity(0.85)))
            // music notes drifting up, fading as the door closes
            for (i, note) in ["♪", "♫", "♪"].enumerated() {
                let nx = spk.midX + CGFloat(i - 1) * dw * 0.16
                let ny = spk.minY - dh * (0.06 + Double(i) * 0.05)
                room.draw(Text(note).font(.system(size: 20, weight: .semibold))
                            .foregroundColor(accent.opacity(0.25 + 0.6 * open)),
                          at: CGPoint(x: nx, y: ny))
            }
        }

        // The door panel, hinged at the left of the frame. Its width shrinks as it
        // opens, revealing the room on the right.
        let doorW = doorway.width * (1 - open * 0.9)
        if doorW > 3 {
            let panel = CGRect(x: doorway.minX, y: doorway.minY, width: doorW, height: doorway.height)
            let pPath = Path(roundedRect: panel, cornerRadius: 8)
            ctx.fill(pPath, with: .linearGradient(
                Gradient(colors: [Theme.panel, Theme.panelAlt]),
                startPoint: CGPoint(x: panel.minX, y: 0), endPoint: CGPoint(x: panel.maxX, y: 0)))
            // recessed inner rectangles for a paneled-door look
            let inset = min(doorW * 0.18, 22)
            if doorW > inset * 2 + 6 {
                for half in [0.0, 1.0] {
                    let ir = CGRect(x: panel.minX + inset, y: panel.minY + inset + CGFloat(half) * panel.height / 2,
                                    width: panel.width - inset * 2, height: panel.height / 2 - inset * 1.5)
                    ctx.stroke(Path(roundedRect: ir, cornerRadius: 4), with: .color(.black.opacity(0.25)), lineWidth: 1.5)
                }
            }
            // leading edge highlight + handle
            ctx.stroke(Path { p in
                p.move(to: CGPoint(x: panel.maxX - 1, y: panel.minY + 6))
                p.addLine(to: CGPoint(x: panel.maxX - 1, y: panel.maxY - 6))
            }, with: .color(accent.opacity(0.5)), lineWidth: 2)
            ctx.fill(Path(ellipseIn: CGRect(x: panel.maxX - 12, y: panel.midY - 4, width: 7, height: 7)),
                     with: .color(accent))
        }

        // Frame outline over everything.
        ctx.stroke(frame, with: .color(Theme.hairline(0.6)), lineWidth: 2)
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
