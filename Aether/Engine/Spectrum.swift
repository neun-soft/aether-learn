import Foundation

// Real-time spectrum analyzer. Correlates the live output against a bank of log-spaced
// frequencies (a direct DFT with precomputed sine/cosine tables), so the bars reflect the
// actual sound playing, filter and all, the way an Ableton-style analyzer does.
final class SpectrumAnalyzer {
    static let barCount = 52
    static let fMin: Float = 40
    static let fMax: Float = 17000
    static let sr: Float = 48000
    static let n = 1024

    static let barHz: [Float] = (0..<barCount).map {
        fMin * powf(fMax / fMin, Float($0) / Float(barCount - 1))
    }

    private var cosT: [[Float]]
    private var sinT: [[Float]]
    private var window: [Float]

    init() {
        let n = SpectrumAnalyzer.n
        window = (0..<n).map { 0.5 - 0.5 * cosf(2 * .pi * Float($0) / Float(n - 1)) }  // Hann
        cosT = []; sinT = []
        for f in SpectrumAnalyzer.barHz {
            let w = 2 * Float.pi * f / SpectrumAnalyzer.sr
            cosT.append((0..<n).map { cosf(w * Float($0)) })
            sinT.append((0..<n).map { sinf(w * Float($0)) })
        }
    }

    func process(_ samples: [Float]) -> [Float] {
        let n = SpectrumAnalyzer.n
        guard samples.count >= n else { return [] }
        let buf = Array(samples.suffix(n))
        var out = [Float](repeating: 0, count: SpectrumAnalyzer.barCount)
        buf.withUnsafeBufferPointer { s in
            window.withUnsafeBufferPointer { win in
                for b in 0..<SpectrumAnalyzer.barCount {
                    var re: Float = 0, im: Float = 0
                    cosT[b].withUnsafeBufferPointer { ct in
                        sinT[b].withUnsafeBufferPointer { st in
                            for i in 0..<n {
                                let x = s[i] * win[i]
                                re += x * ct[i]
                                im -= x * st[i]
                            }
                        }
                    }
                    let amp = sqrtf(re * re + im * im) / Float(n) * 4
                    out[b] = min(1, powf(amp, 0.62) * 1.7)   // gentle curve so quiet harmonics show
                }
            }
        }
        return out
    }
}
