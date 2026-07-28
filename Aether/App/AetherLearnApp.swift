import SwiftUI

@main
struct AetherLearnApp: App {
    @StateObject private var langStore = LangStore()
    @StateObject private var store = Store()
    @StateObject private var theme = ThemeStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(langStore)
                .environmentObject(store)
                .environmentObject(theme)
                .environment(\.locale, .init(identifier: langStore.lang.rawValue))
                .preferredColorScheme(theme.appearance.scheme)
        }
    }
}
