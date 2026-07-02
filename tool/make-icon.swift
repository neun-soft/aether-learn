import AppKit
import CoreGraphics

// Aether Learn icon — matches the Aether Jam family: dark navy->black background
// with a lifted center, and a bold glyph filled with the signature vertical
// gold -> lavender -> blue gradient. Learn's glyph is a sine wave (vs Jam's "A").
let size = 1024
let S = CGFloat(size)

func col(_ hex: String, _ a: CGFloat = 1) -> CGColor {
    var v: UInt64 = 0; Scanner(string: hex).scanHexInt64(&v)
    return CGColor(red: CGFloat((v>>16)&0xff)/255, green: CGFloat((v>>8)&0xff)/255, blue: CGFloat(v&0xff)/255, alpha: a)
}

let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!

// Background: diagonal navy (top-left) -> near-black (bottom-right), sampled from
// the Jam icon (#20293b -> #050b19).
let bg = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: [col("20293b"), col("0b1220"), col("050b19")] as CFArray, locations: [0, 0.6, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: S), end: CGPoint(x: S, y: 0), options: [])
// Soft center lift (#383c51) behind the glyph.
let lift = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                      colors: [col("383c51", 0.55), col("383c51", 0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(lift, startCenter: CGPoint(x: S/2, y: S*0.54), startRadius: 0,
                       endCenter: CGPoint(x: S/2, y: S*0.54), endRadius: S*0.5, options: [])

// Bold sine wave path — 1.5 relaxed cycles, rounded terminals like the Jam "A".
let left: CGFloat = 175, right = S-175, mid = S/2, amp: CGFloat = 168
let path = CGMutablePath(); var first = true; var x = left
while x <= right {
    let t = (x-left)/(right-left)
    let y = mid + sin(t * 2 * .pi * 1.5) * amp
    if first { path.move(to: CGPoint(x:x,y:y)); first=false } else { path.addLine(to: CGPoint(x:x,y:y)) }
    x += 0.75
}

// Fill the stroked wave with the family's vertical gold -> lavender -> blue gradient:
// crests (top) gold, troughs (bottom) blue, lavender through the middle.
ctx.saveGState()
ctx.addPath(path); ctx.setLineWidth(84); ctx.setLineCap(.round); ctx.setLineJoin(.round)
ctx.replacePathWithStrokedPath(); ctx.clip()
let waveGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                          colors: [col("f1d3a0"), col("d2c0ff"), col("7dbeff")] as CFArray, locations: [0, 0.5, 1])!
ctx.drawLinearGradient(waveGrad, start: CGPoint(x: 0, y: mid+amp), end: CGPoint(x: 0, y: mid-amp),
                       options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
ctx.restoreGState()

let cg = ctx.makeImage()!
let png = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
print("icon \(size)x\(size)")
