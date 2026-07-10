import SwiftUI
import UIKit

// A shareable 9:16 Instagram-story image celebrating a finished module.
// The background is built from the visual motifs the module actually taught,
// tinted with the module's accent — so every module's card looks distinct.

// MARK: - Motifs (static, audio-free echoes of the lesson visuals)

private struct WaveMotif: Shape {
    var cycles: Double = 1
    var amp: Double = 1
    func path(in r: CGRect) -> Path {
        var p = Path()
        let mid = r.midY, a = (r.height / 2 - 2) * amp
        p.move(to: CGPoint(x: 0, y: mid))
        stride(from: 0.0, through: 1.0, by: 0.02).forEach { x in
            p.addLine(to: CGPoint(x: r.width * x, y: mid - sin(x * 2 * .pi * cycles) * a))
        }
        return p
    }
}

private struct EnvelopeMotif: Shape {
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: 0, y: h))
        p.addLine(to: CGPoint(x: w * 0.18, y: 2))                       // attack
        p.addLine(to: CGPoint(x: w * 0.38, y: h * 0.42))               // decay
        p.addLine(to: CGPoint(x: w * 0.72, y: h * 0.42))               // sustain
        p.addLine(to: CGPoint(x: w, y: h))                             // release
        return p
    }
}

private struct FilterMotif: Shape {
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: 0, y: 2))
        p.addLine(to: CGPoint(x: w * 0.45, y: 2))
        p.addQuadCurve(to: CGPoint(x: w * 0.68, y: h), control: CGPoint(x: w * 0.6, y: h))
        p.addLine(to: CGPoint(x: w, y: h))
        return p
    }
}

// One motif tile representing a single lesson visual.
private struct Motif: View {
    let visual: LessonVisual
    let accent: Color
    var lineWidth: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let stroke = StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
            switch visual {
            case .spectrum:
                bars([1, 0.72, 0.9, 0.55, 0.68, 0.4, 0.5, 0.3], w: w, h: h)
            case .additive:
                ZStack {
                    WaveMotif(cycles: 1).stroke(accent, style: stroke)
                    WaveMotif(cycles: 2, amp: 0.55).stroke(accent.opacity(0.6), style: stroke)
                    WaveMotif(cycles: 3, amp: 0.35).stroke(accent.opacity(0.4), style: stroke)
                }
            case .detune, .beating:
                ZStack {
                    WaveMotif(cycles: 2).stroke(accent, style: stroke)
                    WaveMotif(cycles: 2.25, amp: 0.9).stroke(accent.opacity(0.5), style: stroke)
                }
            case .filter:
                FilterMotif().stroke(accent, style: stroke)
            case .envelope:
                EnvelopeMotif().stroke(accent, style: stroke)
            case .lfo:
                WaveMotif(cycles: 1.5, amp: 0.8).stroke(accent, style: stroke)
            default: // scope, bee, door, equipment, output, match, none
                WaveMotif(cycles: 2).stroke(accent, style: stroke)
            }
        }
    }

    private func bars(_ hs: [Double], w: CGFloat, h: CGFloat) -> some View {
        let gap: CGFloat = w * 0.03
        let bw = (w - gap * CGFloat(hs.count - 1)) / CGFloat(hs.count)
        return HStack(alignment: .bottom, spacing: gap) {
            ForEach(hs.indices, id: \.self) { i in
                RoundedRectangle(cornerRadius: bw * 0.35)
                    .fill(accent)
                    .frame(width: bw, height: max(bw * 0.5, h * hs[i]))
            }
        }
        .frame(height: h, alignment: .bottom)
    }
}

// MARK: - The story card (rendered to PNG at 1080×1920)

struct StoryCard: View {
    let module: Module

    // Distinct visuals this module taught, in first-seen order.
    private var visuals: [LessonVisual] {
        var seen = Set<String>(), out: [LessonVisual] = []
        for l in module.lessons {
            let key = "\(l.exercise.visual)"
            if seen.insert(key).inserted { out.append(l.exercise.visual) }
        }
        return Array(out.prefix(6))
    }

    private var position: (index: Int, total: Int) {
        let mods = Curriculum.course.modules
        let i = mods.firstIndex { $0.id == module.id } ?? 0
        return (i + 1, mods.count)
    }

    var body: some View {
        let accent = module.accent
        ZStack {
            // Accent-tinted dark background.
            LinearGradient(
                colors: [Theme.bgTop.mix(accent, 0.16), Theme.bgBottom],
                startPoint: .top, endPoint: .bottom
            )

            // Big faint hero wave sweeping behind the content.
            WaveMotif(cycles: 2.2, amp: 0.7)
                .stroke(accent.opacity(0.10), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 1200, height: 560)
                .rotationEffect(.degrees(-8))
                .offset(y: 120)
                .blur(radius: 1)

            VStack(spacing: 0) {
                Spacer().frame(height: 150)

                Text("AETHER")
                    .font(.custom(AppFont.display, size: 44).weight(.semibold))
                    .tracking(14)
                    .foregroundColor(Theme.textPrimary)
                Text("LEARN SYNTHESIS BY EAR")
                    .font(.custom(AppFont.mono, size: 22).weight(.medium))
                    .tracking(6)
                    .foregroundColor(Theme.textDim)
                    .padding(.top, 12)

                Spacer()

                // Seal
                ZStack {
                    Circle().fill(accent.opacity(0.12)).frame(width: 300, height: 300)
                    Circle().stroke(accent.opacity(0.35), lineWidth: 3).frame(width: 250, height: 250)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 130, weight: .semibold))
                        .foregroundColor(accent)
                }

                Text("MODULE COMPLETE")
                    .font(.custom(AppFont.mono, size: 30).weight(.semibold))
                    .tracking(6)
                    .foregroundColor(accent)
                    .padding(.top, 44)

                Text(module.title)
                    .font(.custom(AppFont.display, size: 96).weight(.semibold))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 20)
                    .padding(.horizontal, 90)

                Text(module.subtitle)
                    .font(.custom(AppFont.display, size: 40))
                    .foregroundColor(Theme.textMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 24)
                    .padding(.horizontal, 110)

                Spacer()

                // What this module taught — a shelf of its visual motifs.
                HStack(spacing: 22) {
                    ForEach(visuals.indices, id: \.self) { i in
                        Motif(visual: visuals[i], accent: accent, lineWidth: 5)
                            .padding(22)
                            .frame(width: 132, height: 104)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1.5)
                            )
                    }
                }
                .padding(.bottom, 40)

                Text("Module \(position.index) of \(position.total)  ·  \(module.lessons.count) lessons")
                    .font(.custom(AppFont.mono, size: 26))
                    .foregroundColor(Theme.textDim)

                Spacer().frame(height: 60)

                VStack(spacing: 14) {
                    Text("Learn sound design with me at")
                        .font(.custom(AppFont.display, size: 32))
                        .foregroundColor(Theme.textMuted)

                    Text("aether.neunsoft.com/learn")
                        .font(.custom(AppFont.mono, size: 34).weight(.semibold))
                        .foregroundColor(accent)
                }
                .multilineTextAlignment(.center)
                .padding(.bottom, 120)
            }
        }
        .frame(width: 1080, height: 1920)
    }
}

// MARK: - Share screen (preview + share buttons)

struct StoryShareView: View {
    let module: Module
    var onClose: () -> Void

    @EnvironmentObject var lang: LangStore
    @State private var image: UIImage?
    @State private var showActivity = false
    @State private var saved = false
    @State private var saveFailed = false
    @State private var saver = PhotoSaver()

    var body: some View {
        let accent = module.accent
        ZStack {
            Theme.bgGradient.ignoresSafeArea()
            VStack(spacing: 20) {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Theme.textMuted)
                            .frame(width: 40, height: 40)
                            .background(Theme.panel).clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text(lang.t("Share your progress"))
                        .ui(15, .semibold).foregroundColor(Theme.textPrimary)
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20).padding(.top, 8)

                // Scaled preview of the 1080×1920 card.
                GeometryReader { geo in
                    let scale = min(geo.size.width / 1080, geo.size.height / 1920)
                    StoryCard(module: module)
                        .scaleEffect(scale)
                        .frame(width: 1080 * scale, height: 1920 * scale)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Theme.hairline(0.12), lineWidth: 1)
                        )
                        .frame(width: geo.size.width, height: geo.size.height)
                }

                VStack(spacing: 12) {
                    Button { saveToPhotos() } label: {
                        HStack(spacing: 8) {
                            Image(systemName: saved ? "checkmark" : "square.and.arrow.down")
                            Text(lang.t(saved ? "Saved to Photos" : "Save to Photos"))
                        }
                        .font(AppFont.ui(15, .semibold)).foregroundColor(.black)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(accent).clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .disabled(image == nil)

                    if saveFailed {
                        Text(lang.t("Couldn't save — allow photo access in Settings, or use Share."))
                            .ui(12).foregroundColor(Theme.textDim)
                            .multilineTextAlignment(.center)
                    }

                    Button { showActivity = true } label: {
                        Text(lang.t("Share…"))
                            .font(AppFont.ui(15, .semibold)).foregroundColor(Theme.textPrimary)
                            .frame(maxWidth: .infinity).padding(.vertical, 14).panel(14)
                    }
                    .buttonStyle(.plain)
                    .disabled(image == nil)
                }
                .padding(.horizontal, 20).padding(.bottom, 16)
            }
        }
        .task { renderImage() }
        .sheet(isPresented: $showActivity) {
            if let image { ShareSheet(items: [image]) }
        }
    }

    @MainActor private func renderImage() {
        guard image == nil else { return }
        let renderer = ImageRenderer(content: StoryCard(module: module))
        renderer.scale = 1                       // card is already 1080×1920 pt → 1080×1920 px
        image = renderer.uiImage
    }

    private func saveToPhotos() {
        guard let image else { return }
        saver.save(image) { error in
            if error == nil {
                withAnimation { saved = true }
            } else {
                withAnimation { saveFailed = true }
            }
        }
    }
}

// Saves an image to the camera roll and reports the result on the main queue.
final class PhotoSaver: NSObject {
    private var completion: ((Error?) -> Void)?

    func save(_ image: UIImage, completion: @escaping (Error?) -> Void) {
        self.completion = completion
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(finished(_:error:context:)), nil)
    }

    @objc private func finished(_ image: UIImage, error: Error?, context: UnsafeRawPointer) {
        let done = completion
        completion = nil
        DispatchQueue.main.async { done?(error) }
    }
}

// MARK: - Helpers

// System share sheet.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

private extension Color {
    // Blend toward another color by t (0…1). Used for the accent-tinted background.
    func mix(_ other: Color, _ t: Double) -> Color {
        let a = UIColor(self), b = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let f = CGFloat(t)
        return Color(.sRGB,
                     red: Double(r1 + (r2 - r1) * f),
                     green: Double(g1 + (g2 - g1) * f),
                     blue: Double(b1 + (b2 - b1) * f))
    }
}
