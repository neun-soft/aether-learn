import SwiftUI

struct CongratsView: View {
    let moduleID: String
    var path: Binding<[Route]>

    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var lang: LangStore

    @State private var showReview = false
    @State private var showFeedback = false
    @State private var showShare = false

    private var module: Module? { Curriculum.course.modules.first { $0.id == moduleID } }
    private var nextModule: Module? {
        guard let i = Curriculum.course.modules.firstIndex(where: { $0.id == moduleID }),
              i + 1 < Curriculum.course.modules.count else { return nil }
        return Curriculum.course.modules[i + 1]
    }

    private var courseDone: Bool {
        nextModule == nil && Curriculum.course.allLessons.allSatisfy { progress.isDone($0.id) }
    }

    var body: some View {
        let accent = module?.accent ?? Theme.tone
        ZStack {
            Theme.bgGradient.ignoresSafeArea()
            VStack(spacing: 18) {
                Spacer()

                if courseDone {
                    ZStack {
                        Circle().fill(accent.opacity(0.10)).frame(width: 168, height: 168)
                        Circle().stroke(accent.opacity(0.35), lineWidth: 1.5).frame(width: 140, height: 140)
                        Circle().fill(accent.opacity(0.16)).frame(width: 118, height: 118)
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 54, weight: .semibold))
                            .foregroundColor(accent)
                    }
                    Text(lang.t("COURSE COMPLETE"))
                        .mono(12, .semibold).tracking(3).foregroundColor(accent)
                    Text(lang.t("Introduction to\nSound Design"))
                        .ui(32, .semibold).foregroundColor(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(lang.t("Waves, frequency, harmonics, filters, envelopes, and modulation. You now hold the vocabulary every synthesizer speaks. Go make some sounds."))
                        .ui(15).foregroundColor(Theme.textMuted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 32)
                } else {
                    ZStack {
                        Circle().fill(accent.opacity(0.15)).frame(width: 108, height: 108)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 56, weight: .semibold))
                            .foregroundColor(accent)
                    }
                    Text(lang.t("MODULE COMPLETE"))
                        .mono(12, .semibold).tracking(2).foregroundColor(Theme.textDim)
                    Text(lang.t(module?.title ?? ""))
                        .ui(30, .semibold).foregroundColor(Theme.textPrimary)
                    Text(lang.t("Nice work. You have the foundation for what comes next."))
                        .ui(15).foregroundColor(Theme.textMuted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 32)
                }

                Spacer()

                RatingPrompt(accent: accent, selection: progress.ratingFor(moduleID)) { thumbsUp in
                    switch progress.setRating(moduleID, thumbsUp: thumbsUp) {
                    case .requestReview: showReview = true
                    case .askFeedback: showFeedback = true
                    case .none: break
                    }
                }
                .padding(.bottom, 6)

                VStack(spacing: 12) {
                    if let next = nextModule {
                        Button {
                            path.wrappedValue = [.lesson(Curriculum.indexOf(next.lessons[0].id))]
                        } label: {
                            HStack(spacing: 6) {
                                Text("\(lang.t("Start")) \(lang.t(next.title))")
                                Image(systemName: "arrow.right")
                            }
                            .font(AppFont.ui(15, .semibold)).foregroundColor(.black)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(next.accent).clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                    Button { showShare = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                            Text(lang.t("Share on socials"))
                        }
                        .font(AppFont.ui(15, .semibold)).foregroundColor(Theme.textPrimary)
                        .frame(maxWidth: .infinity).padding(.vertical, 14).panel(14)
                    }
                    .buttonStyle(.plain)

                    Button { path.wrappedValue = [] } label: {
                        Text(lang.t("Back to catalog"))
                            .font(AppFont.ui(15, .semibold)).foregroundColor(Theme.textMuted)
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20).padding(.bottom, 16)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showReview) {
            ReviewRequestView(accent: module?.accent ?? Theme.tone) { showReview = false }
                .environmentObject(lang)
        }
        .fullScreenCover(isPresented: $showFeedback) {
            FeedbackView(accent: module?.accent ?? Theme.tone, moduleID: moduleID) { showFeedback = false }
                .environmentObject(lang)
                .environmentObject(progress)
        }
        .fullScreenCover(isPresented: $showShare) {
            if let m = module {
                StoryShareView(module: m) { showShare = false }
                    .environmentObject(lang)
            }
        }
    }
}
