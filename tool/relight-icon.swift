import AppKit
import CoreGraphics

// Moonstone app icon, derived from the original dark icon so the glyph is identical
// down to the pixel — only the fill changes. The dark original is kept alongside this
// script as its source; the light result is what ships.
//
//   usage: swift relight-icon.swift tool/icon-1024-dark.png \
//                Aether/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png
//
// The dark icons are a bright glyph on a deep-navy field, so luminance alone separates
// the two cleanly (the background tops out around 0.25, the glyph starts around 0.70).
// We lift the glyph out as a soft mask — which keeps its antialiased edges — then
// repaint it flat.
//
// FLAT AND MATTE, on purpose. The dark icon's gold→lavender→blue ramp glowed because
// every stop was lighter than its navy ground. On warm white every stop has to be
// *darker* than the ground, and no gradient survives that inversion: hue rotations turn
// to mud, and even a metallic foil ramp reads as decoration bolted onto a flat UI. So
// the icon is exactly what the app is made of — textPrimary on the app background, two
// flat colours, nothing else.

let size = 1024
let S = CGFloat(size)

func col(_ hex: String) -> (CGFloat, CGFloat, CGFloat) {
    var v: UInt64 = 0; Scanner(string: hex).scanHexInt64(&v)
    return (CGFloat((v >> 16) & 0xff) / 255, CGFloat((v >> 8) & 0xff) / 255, CGFloat(v & 0xff) / 255)
}

let bg = col("f6f3ee")     // Palette.light.bgTop
let fg = col("2a2620")     // Palette.light.textPrimary

guard CommandLine.arguments.count == 3 else {
    print("usage: relight-icon.swift <dark-in.png> <light-out.png>"); exit(1)
}
let inURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outURL = URL(fileURLWithPath: CommandLine.arguments[2])

guard let src = NSImage(contentsOf: inURL)?.cgImage(forProposedRect: nil, context: nil, hints: nil),
      src.width == size, src.height == size else {
    print("expected a \(size)×\(size) PNG at \(inURL.path)"); exit(1)
}

// Read the source into a known RGBA layout.
var pixels = [UInt8](repeating: 0, count: size * size * 4)
let readCtx = CGContext(data: &pixels, width: size, height: size, bitsPerComponent: 8,
                        bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
readCtx.draw(src, in: CGRect(x: 0, y: 0, width: S, height: S))

func lum(_ i: Int) -> CGFloat {
    let r = CGFloat(pixels[i]) / 255, g = CGFloat(pixels[i + 1]) / 255, b = CGFloat(pixels[i + 2]) / 255
    return 0.2126 * r + 0.7152 * g + 0.0722 * b
}
func smoothstep(_ e0: CGFloat, _ e1: CGFloat, _ x: CGFloat) -> CGFloat {
    let t = min(1, max(0, (x - e0) / (e1 - e0)))
    return t * t * (3 - 2 * t)
}

// Soft mask: 0 = background, 1 = glyph, with the ramp landing on the antialiased edge.
var out = [UInt8](repeating: 255, count: size * size * 4)
for p in 0..<(size * size) {
    let m = smoothstep(0.30, 0.62, lum(p * 4))
    let i = p * 4
    out[i]     = UInt8(round(255 * (bg.0 + (fg.0 - bg.0) * m)))
    out[i + 1] = UInt8(round(255 * (bg.1 + (fg.1 - bg.1) * m)))
    out[i + 2] = UInt8(round(255 * (bg.2 + (fg.2 - bg.2) * m)))
    out[i + 3] = 255                  // opaque: the primary icon must have no alpha
}

let writeCtx = CGContext(data: &out, width: size, height: size, bitsPerComponent: 8,
                         bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(),
                         bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
let cg = writeCtx.makeImage()!
let png = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])!
try! png.write(to: outURL)
print("wrote \(outURL.lastPathComponent) — flat matte")
