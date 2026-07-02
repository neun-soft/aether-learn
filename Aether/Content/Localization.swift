import Foundation
import SwiftUI

// In-app language. English-only for now; add cases and populate Translations.table when needed.
enum Lang: String, CaseIterable, Identifiable {
    case en
    var id: String { rawValue }
    var short: String { rawValue.uppercased() }
    var label: String { "English" }
}

final class LangStore: ObservableObject {
    @Published var lang: Lang = .en

    /// Returns the string as-is (English-only). When other languages are added,
    /// restore the lookup: Translations.table[s]?[lang] ?? s
    func t(_ s: String) -> String { s }
}
