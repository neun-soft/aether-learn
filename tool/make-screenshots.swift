import AppKit
import CoreGraphics
import CoreText

let W = 1290, H = 2796
let WF = CGFloat(W), HF = CGFloat(H)

func col(_ hex: String, _ a: CGFloat = 1) -> CGColor {
    var v: UInt64 = 0; Scanner(string: hex).scanHexInt64(&v)
    return CGColor(red: CGFloat((v>>16)&0xff)/255, green: CGFloat((v>>8)&0xff)/255, blue: CGFloat(v&0xff)/255, alpha: a)
}
func ns(_ c: CGColor) -> NSColor { NSColor(cgColor: c)! }

// Register the app's real fonts; return usable PostScript names.
func regFont(_ path: String) -> String {
    let url = URL(fileURLWithPath: path)
    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    if let data = try? Data(contentsOf: url), let prov = CGDataProvider(data: data as CFData),
       let cg = CGFont(prov), let n = cg.postScriptName { return n as String }
    return "HelveticaNeue"
}
let base = "Aether/Resources/"
let grotesk = regFont(base + "SpaceGrotesk.ttf")
let mono = regFont(base + "JetBrainsMono.ttf")
func font(_ name: String, _ sz: CGFloat, bold: Bool = false) -> NSFont {
    if let f = NSFont(name: name, size: sz) {
        if bold, let b = NSFontManager.shared.convert(f, toHaveTrait: .boldFontMask) as NSFont? { return b }
        return f
    }
    return NSFont.systemFont(ofSize: sz, weight: bold ? .bold : .regular)
}

func draw(_ text: String, _ f: NSFont, _ c: CGColor, _ rect: NSRect, _ align: NSTextAlignment = .center) {
    let p = NSMutableParagraphStyle(); p.alignment = align; p.lineSpacing = 6
    let a: [NSAttributedString.Key: Any] = [.font: f, .foregroundColor: ns(c), .paragraphStyle: p]
    (text as NSString).draw(in: rect, withAttributes: a)
}

// ---- app-accurate visual renderers, drawn into a panel rect --------------
func panel(_ ctx: CGContext, _ r: CGRect, _ accent: CGColor, _ body: (CGContext, CGRect) -> Void) {
    let path = CGPath(roundedRect: r, cornerWidth: 44, cornerHeight: 44, transform: nil)
    ctx.saveGState()
    ctx.addPath(path); ctx.setFillColor(col("141821")); ctx.fillPath()
    ctx.addPath(path); ctx.setStrokeColor(col("ffffff", 0.06)); ctx.setLineWidth(2); ctx.strokePath()
    ctx.addPath(path); ctx.clip()
    body(ctx, r)
    ctx.restoreGState()
    ctx.addPath(path); ctx.setStrokeColor(accent.copy(alpha: 0.35)!); ctx.setLineWidth(2); ctx.strokePath()
}

func stroke(_ ctx: CGContext, _ pts: [CGPoint], _ c: CGColor, _ w: CGFloat, glow: Bool = true) {
    guard pts.count > 1 else { return }
    let p = CGMutablePath(); p.move(to: pts[0]); pts.dropFirst().forEach { p.addLine(to: $0) }
    if glow { ctx.saveGState(); ctx.setShadow(offset: .zero, blur: 26, color: c.copy(alpha: 0.7)!) }
    ctx.addPath(p); ctx.setStrokeColor(c); ctx.setLineWidth(w); ctx.setLineCap(.round); ctx.setLineJoin(.round); ctx.strokePath()
    if glow { ctx.restoreGState() }
}

func vSine(_ ctx: CGContext, _ r: CGRect) {
    var pts: [CGPoint] = []; var x = r.minX + 40
    while x <= r.maxX - 40 { let t = (x - r.minX - 40)/(r.width - 80)
        pts.append(CGPoint(x: x, y: r.midY + sin(t * 2 * .pi * 2) * r.height * 0.32)); x += 3 }
    stroke(ctx, pts, col("5b9dff"), 12)
}
func vAdditive(_ ctx: CGContext, _ r: CGRect) {
    func partial(_ k: Int, _ norm: CGFloat) -> [CGPoint] {
        var pts: [CGPoint] = []; var x = r.minX + 40
        while x <= r.maxX - 40 { let t = Double((x - r.minX - 40)/(r.width - 80))
            let y = sin(2 * .pi * Double(k) * t * 2) / Double(k)
            pts.append(CGPoint(x: x, y: r.midY + CGFloat(y)/norm * r.height * 0.30)); x += 3 }
        return pts
    }
    let N = 6; let norm: CGFloat = 1.0
    for k in 1...N { stroke(ctx, partial(k, norm), col("9db4d0", 0.28), 3, glow: false) }
    // sum
    var sum: [CGPoint] = []; var x = r.minX + 40
    while x <= r.maxX - 40 { let t = Double((x - r.minX - 40)/(r.width - 80))
        var s = 0.0; for k in 1...N { s += sin(2 * .pi * Double(k) * t * 2)/Double(k) }
        sum.append(CGPoint(x: x, y: r.midY + CGFloat(s) * r.height * 0.14)); x += 3 }
    stroke(ctx, sum, col("9db4d0"), 12)
}
func vFilter(_ ctx: CGContext, _ r: CGRect) {
    let fc = 0.5, q = 4.5
    // faint spectrum bars
    for i in 0..<26 { let t = CGFloat(i)/25
        let bx = r.minX + 40 + t*(r.width-80)
        let h = max(0.04, CGFloat(pow(0.72, Double(i)))) * r.height * 0.5
        ctx.setStrokeColor(col("c79bff", 0.30)); ctx.setLineWidth(6); ctx.setLineCap(.round)
        ctx.move(to: CGPoint(x: bx, y: r.minY + 40)); ctx.addLine(to: CGPoint(x: bx, y: r.minY + 40 + h)); ctx.strokePath()
    }
    var pts: [CGPoint] = []; var x = r.minX + 40
    while x <= r.maxX - 40 { let t = Double((x - r.minX - 40)/(r.width - 80))
        let xr = pow(2.0, (t - fc) * 5)         // freq ratio to cutoff
        let x2 = xr*xr
        let denom = (1 - x2)*(1 - x2) + x2/(q*q)
        let g = 1/denom.squareRoot()
        let db = 20*log10(max(g, 0.001)); let n = min(1, max(0, (db + 30)/48))
        pts.append(CGPoint(x: x, y: r.minY + 30 + CGFloat(n)*(r.height - 60))); x += 3 }
    stroke(ctx, pts, col("c79bff"), 12)
}
func vEnvelope(_ ctx: CGContext, _ r: CGRect) {
    let a = 0.14, h = 0.10, d = 0.22, s = 0.55, rel = 0.24
    let total = a + h + d + 0.30 + rel
    func lvl(_ t: Double) -> Double {
        if t < a { return t/a }
        if t < a+h { return 1 }
        if t < a+h+d { return 1 - (1-s)*((t-a-h)/d) }
        if t < a+h+d+0.30 { return s }
        return s*(1 - (t-a-h-d-0.30)/rel)
    }
    var pts: [CGPoint] = []; var x = r.minX + 40
    while x <= r.maxX - 40 { let t = Double((x - r.minX - 40)/(r.width - 80)) * total
        pts.append(CGPoint(x: x, y: r.minY + 40 + CGFloat(lvl(t))*(r.height - 80))); x += 3 }
    // fill
    let fp = CGMutablePath(); fp.move(to: CGPoint(x: pts[0].x, y: r.minY+40))
    pts.forEach { fp.addLine(to: $0) }; fp.addLine(to: CGPoint(x: pts.last!.x, y: r.minY+40)); fp.closeSubpath()
    ctx.addPath(fp); ctx.setFillColor(col("e8c07d", 0.12)); ctx.fillPath()
    stroke(ctx, pts, col("e8c07d"), 12)
}
func vLFO(_ ctx: CGContext, _ r: CGRect) {
    var pts: [CGPoint] = []; var x = r.minX + 40
    while x <= r.maxX - 40 { let t = Double((x - r.minX - 40)/(r.width - 80))
        pts.append(CGPoint(x: x, y: r.midY + CGFloat(sin(t * 2 * .pi)) * r.height * 0.32)); x += 3 }
    stroke(ctx, pts, col("7fd6a0"), 12)
    // playhead dot
    let hx = r.minX + 40 + 0.68*(r.width-80)
    let hy = r.midY + CGFloat(sin(0.68 * 2 * .pi)) * r.height * 0.32
    ctx.setFillColor(col("ffffff")); ctx.fillEllipse(in: CGRect(x: hx-16, y: hy-16, width: 32, height: 32))
}
func vKeys(_ ctx: CGContext, _ r: CGRect) {
    // waveform strip on top
    let wr = CGRect(x: r.minX+30, y: r.midY+30, width: r.width-60, height: r.height*0.4)
    var pts: [CGPoint] = []; var x = wr.minX
    while x <= wr.maxX { let t = (x-wr.minX)/wr.width
        pts.append(CGPoint(x: x, y: wr.midY + sin(Double(t)*2 * .pi*3)*Double(wr.height*0.4))); x += 3 }
    stroke(ctx, pts, col("5b9dff"), 10)
    // keys
    let n = 7; let kw = (r.width-60)/CGFloat(n)
    for i in 0..<n {
        let kr = CGRect(x: r.minX+30+CGFloat(i)*kw+4, y: r.minY+30, width: kw-8, height: r.height*0.42)
        let on = (i == 2)
        ctx.addPath(CGPath(roundedRect: kr, cornerWidth: 12, cornerHeight: 12, transform: nil))
        ctx.setFillColor(on ? col("5b9dff") : col("1c212d")); ctx.fillPath()
    }
}

struct Shot { let file: String; let head: String; let sub: String; let accent: String; let chip: String; let vis: (CGContext, CGRect) -> Void }
let shots = [
    Shot(file: "01-sound", head: "Learn how\nsound really works", sub: "Start from the very first vibration — no jargon, no prerequisites.", accent: "5b9dff", chip: "SOUND & FREQUENCY", vis: vSine),
    Shot(file: "02-harmonics", head: "See a wave built\nfrom pure sines", sub: "Add sine waves one at a time and watch a saw take shape.", accent: "9db4d0", chip: "WAVEFORMS & HARMONICS", vis: vAdditive),
    Shot(file: "03-filter", head: "Shape tone\nwith filters", sub: "Sweep the cutoff, add resonance, hear the classic filter sweep.", accent: "c79bff", chip: "SUBTRACTIVE", vis: vFilter),
    Shot(file: "04-envelope", head: "Sculpt sound\nover time", sub: "Attack, hold, decay, sustain, release — the shape of every note.", accent: "e8c07d", chip: "ENVELOPES", vis: vEnvelope),
    Shot(file: "05-motion", head: "Add motion\nand movement", sub: "LFOs, vibrato, tremolo, and the wobble at the heart of bass music.", accent: "7fd6a0", chip: "MODULATION", vis: vLFO),
    Shot(file: "06-play", head: "Play a real synth\nas you learn", sub: "Every lesson has a live instrument you play with your finger.", accent: "5b9dff", chip: "HANDS-ON", vis: vKeys),
]

let outDir = CommandLine.arguments[1]
for shot in shots {
    let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    let ns = NSGraphicsContext(cgContext: ctx, flipped: false); NSGraphicsContext.current = ns
    // bg
    let bg = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                        colors: [col("161b27"), col("0a0c12")] as CFArray, locations: [0,1])!
    ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: HF), end: CGPoint(x: 0, y: 0), options: [])
    // accent glow top
    let acc = col(shot.accent)
    let gl = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [acc.copy(alpha: 0.18)!, acc.copy(alpha: 0)!] as CFArray, locations: [0,1])!
    ctx.drawRadialGradient(gl, startCenter: CGPoint(x: WF/2, y: HF*0.82), startRadius: 0, endCenter: CGPoint(x: WF/2, y: HF*0.82), endRadius: WF*0.9, options: [])

    // chip
    draw(shot.chip, font(mono, 34), acc, NSRect(x: 0, y: H-300, width: W, height: 44))
    // headline (coordinates are bottom-left origin; place high on screen)
    draw(shot.head, font(grotesk, 96, bold: true), col("eef1f7"), NSRect(x: 80, y: H-560, width: W-160, height: 230))
    // subtitle
    draw(shot.sub, font(grotesk, 44), col("9aa0ad"), NSRect(x: 110, y: H-720, width: W-220, height: 120))

    // hero panel
    let pr = CGRect(x: 90, y: 440, width: WF-180, height: HF*0.50)
    panel(ctx, pr, acc) { c, r in shot.vis(c, r.insetBy(dx: 60, dy: 90)) }

    // footer wordmark
    draw("AETHER LEARN", font(mono, 30), col("6c7689"), NSRect(x: 0, y: 120, width: W, height: 40))

    let cg = ctx.makeImage()!
    let png = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])!
    try! png.write(to: URL(fileURLWithPath: "\(outDir)/\(shot.file).png"))
    print("wrote \(shot.file)")
}
