import SwiftUI

struct RootView: View {
    @StateObject private var progress = ProgressStore()
    @EnvironmentObject private var store: Store
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            CourseScreen(course: Curriculum.course)
                .environmentObject(progress)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .lesson(let i):
                        // Guard against a stale/out-of-range index ever landing in the path.
                        let idx = min(max(0, i), Curriculum.flat.count - 1)
                        let ref = Curriculum.flat[idx]
                        // Backstop gate: whatever put a paid lesson in the path — a deep
                        // link, a stale route — it gets the paywall, not the lesson.
                        if !store.isUnlocked && !Curriculum.isFree(lessonID: ref.lesson.id) {
                            PaywallView { path = [] }
                                .navigationBarBackButtonHidden(true)
                        } else {
                            LessonScreen(index: idx, lesson: ref.lesson, accent: ref.module.accent, path: $path)
                                .environmentObject(progress)
                                .id(i)   // fresh identity per lesson so it opens on Learn, not the prior tab
                        }
                    case .congrats(let moduleID):
                        CongratsView(moduleID: moduleID, path: $path)
                            .environmentObject(progress)
                    }
                }
        }
        .tint(Theme.tone)
        // Existing users who already worked through what is now paid content keep it.
        .task { store.grandfatherIfLegacyUser(progress: progress) }
        #if DEBUG
        .onAppear {
            if let id = Shot.lessonID { path = [.lesson(Curriculum.indexOf(id))] }
        }
        #endif
    }
}

// Small reusable card background matching the app's panel style.
struct Panel: ViewModifier {
    var radius: CGFloat = Theme.rCard
    func body(content: Content) -> some View {
        content
            .background(Theme.panel)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Theme.hairline(), lineWidth: 1)
            )
            .shadow(color: Theme.cardShadow, radius: 2, y: 1)
    }
}
extension View {
    func panel(_ radius: CGFloat = Theme.rCard) -> some View { modifier(Panel(radius: radius)) }
}

#Preview {
    RootView()
        .environmentObject(LangStore())
        .environmentObject(Store())
        .environmentObject(ThemeStore())
}
