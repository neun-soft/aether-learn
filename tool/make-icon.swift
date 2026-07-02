import AppKit
import CoreGraphics

let size = 1024
let S = CGFloat(size)

func col(_ hex: String, _ a: CGFloat = 1) -> CGColor {
    var v: UInt64 = 0; Scanner(string: hex).scanHexInt64(&v)
    return CGColor(red: CGFloat((v>>16)&0xff)/255, green: CGFloat((v>>8)&0xff)/255, blue: CGFloat(v&0xff)/255, alpha: a)
}

let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!

// Background: radial-ish deep gradient, slightly lifted center.
let bg = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: [col("232a3d"), col("0b0e15")] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(bg, startCenter: CGPoint(x: S/2, y: S*0.58), startRadius: 0,
                       endCenter: CGPoint(x: S/2, y: S/2), endRadius: S*0.72, options: [.drawsAfterEndLocation])

// Subtle baseline grid ticks.
ctx.setStrokeColor(col("38415a", 0.5)); ctx.setLineWidth(2)
for i in 1..<6 { let x = S*CGFloat(i)/6; ctx.move(to: CGPoint(x:x,y:S*0.32)); ctx.addLine(to: CGPoint(x:x,y:S*0.68)); ctx.strokePath() }

// Morphing waveform: sine on the left blending to a saw on the right.
let left: CGFloat = 130, right = S-130, mid = S/2, amp: CGFloat = 220
func wave(_ t: CGFloat) -> CGFloat {
    let phase = t * 3.0                       // 3 cycles across
    let ph = phase - floor(phase)
    let sine = sin(phase * 2 * .pi)
    let saw = 1 - 2*ph                         // falling saw
    let m = t                                  // morph amount 0->1 across width
    return sine*(1-m) + saw*m
}
func buildPath() -> CGPath {
    let p = CGMutablePath(); var first = true; var x = left
    while x <= right {
        let t = (x-left)/(right-left)
        let y = mid + wave(t)*amp
        if first { p.move(to: CGPoint(x:x,y:y)); first=false } else { p.addLine(to: CGPoint(x:x,y:y)) }
        x += 1.5
    }
    return p
}
let path = buildPath()

// Glow underlay.
ctx.saveGState()
ctx.setShadow(offset: .zero, blur: 55, color: col("6aa4ff", 0.7))
ctx.setStrokeColor(col("6aa4ff")); ctx.setLineWidth(40); ctx.setLineCap(.round); ctx.setLineJoin(.round)
ctx.addPath(path); ctx.strokePath()
ctx.restoreGState()

// Gradient stroke (blue -> purple) by clipping to the stroked path.
ctx.saveGState()
ctx.addPath(path); ctx.setLineWidth(38); ctx.setLineCap(.round); ctx.setLineJoin(.round)
ctx.replacePathWithStrokedPath(); ctx.clip()
let strokeGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                            colors: [col("5b9dff"), col("8db4ff"), col("c79bff")] as CFArray, locations: [0,0.5,1])!
ctx.drawLinearGradient(strokeGrad, start: CGPoint(x:left,y:mid), end: CGPoint(x:right,y:mid), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
ctx.restoreGState()

let cg = ctx.makeImage()!
let png = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
print("icon \(size)x\(size)")
