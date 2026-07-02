import SwiftUI

@main
struct AetherLearnApp: App {
    @StateObject private var langStore = LangStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(langStore)
                .environment(\.locale, .init(identifier: langStore.lang.rawValue))
                .preferredColorScheme(.dark)
        }
    }
}
