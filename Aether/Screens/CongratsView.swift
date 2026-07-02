import SwiftUI

struct CongratsView: View {
    let moduleID: String
    var path: Binding<[Route]>

    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var lang: LangStore

    private var module: Module? { Curriculum.course.modules.first { $0.id == moduleID } }
    private var nextModule: Module? {
        guard let i = Curriculum.course.modules.firstIndex(where: { $0.id == moduleID }),
              i + 1 < Curriculum.course.modules.count else { return nil }
        return Curriculum.course.modules[i + 1]
    }

    var body: some View {
        let accent = module?.accent ?? Theme.tone
        ZStack {
            Theme.bgGradient.ignoresSafeArea()
            VStack(spacing: 18) {
                Spacer()

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
                Text(lang.t(nextModule == nil
                     ? "You have finished the whole course. Go make some sounds."
                     : "Nice work. You have the foundation for what comes next."))
                    .ui(15).foregroundColor(Theme.textMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)

                Spacer()

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
                    Button { path.wrappedValue = [] } label: {
                        Text(lang.t("Back to catalog"))
                            .font(AppFont.ui(15, .semibold)).foregroundColor(Theme.textPrimary)
                            .frame(maxWidth: .infinity).padding(.vertical, 14).panel(14)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20).padding(.bottom, 16)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
    }
}
