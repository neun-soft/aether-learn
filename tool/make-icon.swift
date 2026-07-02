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

// Vibrant diagonal gradient — a colored icon pops on the home screen far better
// than a thin line on near-black. Blue -> indigo -> purple (app accent family).
let bg = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: [col("5ba0ff"), col("6f7bf0"), col("a066f0")] as CFArray,
                    locations: [0, 0.55, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: S), end: CGPoint(x: S, y: 0), options: [])

// Soft top-light for depth.
let light = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                       colors: [col("ffffff", 0.16), col("ffffff", 0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(light, startCenter: CGPoint(x: S*0.32, y: S*0.72), startRadius: 0,
                       endCenter: CGPoint(x: S*0.32, y: S*0.72), endRadius: S*0.7, options: [])

// Thin center axis — the "zero line" a wave crosses. Sits just inside the wave
// span so it reads as a baseline, not a line poking past the ends.
ctx.setStrokeColor(col("ffffff", 0.22)); ctx.setLineWidth(5); ctx.setLineCap(.round)
ctx.move(to: CGPoint(x: 250, y: S/2)); ctx.addLine(to: CGPoint(x: S-250, y: S/2)); ctx.strokePath()

// One clean, elegant sine wave in white — 1.5 relaxed cycles, calm amplitude.
let left: CGFloat = 170, right = S-170, mid = S/2, amp: CGFloat = 158
let path = CGMutablePath(); var first = true; var x = left
while x <= right {
    let t = (x-left)/(right-left)
    let y = mid + sin(t * 2 * .pi * 1.5) * amp
    if first { path.move(to: CGPoint(x:x,y:y)); first=false } else { path.addLine(to: CGPoint(x:x,y:y)) }
    x += 1.0
}
// Soft shadow beneath the wave for lift.
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 30, color: col("2a1f5a", 0.5))
ctx.addPath(path); ctx.setStrokeColor(col("ffffff")); ctx.setLineWidth(72)
ctx.setLineCap(.round); ctx.setLineJoin(.round); ctx.strokePath()
ctx.restoreGState()

let cg = ctx.makeImage()!
let png = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
print("icon \(size)x\(size)")
