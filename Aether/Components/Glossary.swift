import SwiftUI

// MARK: - Tappable jargon
//
// A beginner hits a word like "timbre" or "harmonic", does not know it, and keeps reading anyway
// — from that sentence on, nothing lands. The fix is not to avoid every technical word, because
// the words are the point: the reviewer who asked for "more terms and jargon" wants to recognise
// them in a DAW later. The fix is to make every one of them one tap from a plain definition,
// without leaving the lesson.

/// Renders a paragraph with any of `terms` underlined and tappable.
///
/// Built as one `Text` over an `AttributedString`, so the paragraph wraps, pads, and line-breaks
/// exactly like every other paragraph in the app. An earlier version laid each word out
/// individually and lost the parent's padding, pushing text off the screen edge.
///
/// Taps ride on link attributes with a private scheme, caught by an `OpenURLAction` on the
/// paragraph. Nothing ever reaches the system URL handler.
struct TermText: View {
    let paragraph: String
    let terms: [Term]
    let accent: Color
    var onTap: (Term) -> Void

    static let scheme = "aether-term"

    var body: some View {
        Text(Self.attributed(paragraph, terms: terms, accent: accent))
            .ui(15)
            .foregroundColor(Theme.textSecondary)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .environment(\.openURL, OpenURLAction { url in
                guard url.scheme == Self.scheme,
                      let term = terms.first(where: { $0.id == url.host })
                else { return .discarded }
                onTap(term)
                return .handled
            })
    }

    /// Marks up the first whole-word match of each term, longest term first so "pink noise" wins
    /// over "noise" and "noisy" never matches "noise".
    static func attributed(_ text: String, terms: [Term], accent: Color) -> AttributedString {
        var out = AttributedString(text)
        guard !terms.isEmpty else { return out }

        for term in terms.sorted(by: { $0.word.count > $1.word.count }) {
            var searchRange = out.startIndex..<out.endIndex
            while let found = out[searchRange].range(of: term.word, options: [.caseInsensitive]) {
                // Only accept the match if it is a whole word.
                let beforeOK = found.lowerBound == out.startIndex
                    || !isWordCharacter(out.characters[out.index(beforeCharacter: found.lowerBound)])
                let afterOK = found.upperBound == out.endIndex
                    || !isWordCharacter(out.characters[found.upperBound])

                // Style only once the link exists. Underlining a word whose URL failed to build
                // is worse than leaving it plain: it advertises a definition and then does
                // nothing when tapped.
                if beforeOK, afterOK, out[found].link == nil,
                   let url = URL(string: "\(scheme)://\(term.id)") {
                    out[found].link = url
                    out[found].foregroundColor = accent
                    out[found].underlineStyle = .single
                    // Only the first mention in a paragraph is marked. A word that repeats four
                    // times reads as four separate offers to explain something, and the paragraph
                    // turns into a field of underlines nobody wants to read.
                    break
                }

                guard found.upperBound < out.endIndex else { break }
                searchRange = found.upperBound..<out.endIndex
            }
        }
        return out
    }

    private static func isWordCharacter(_ c: Character) -> Bool { c.isLetter || c.isNumber }
}

private extension AttributedString {
    func index(beforeCharacter i: AttributedString.Index) -> AttributedString.Index {
        characters.index(before: i)
    }
}

// MARK: - Definition card
//
// Presented over the lesson rather than pushed, so "back" returns you to the exact sentence you
// were reading. Losing your place is the thing that makes people stop looking words up.

struct TermSheet: View {
    let term: Term
    let accent: Color
    var onBack: () -> Void

    @EnvironmentObject var lang: LangStore

    var body: some View {
        ZStack {
            Theme.bgGradient.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Button(action: onBack) {
                    HStack(spacing: 7) {
                        Image(systemName: "chevron.left").font(.system(size: 13, weight: .bold))
                        Text(lang.t("Back to the lesson")).ui(14, .medium)
                    }
                    .foregroundColor(Theme.textMuted)
                }
                .buttonStyle(.plain)
                .padding(.top, 18).padding(.bottom, 26)

                Text(lang.t("IN PLAIN WORDS"))
                    .mono(11, .semibold).tracking(2).foregroundColor(accent)
                    .padding(.bottom, 10)

                Text(term.word)
                    .ui(30, .semibold).foregroundColor(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 14)

                Text(lang.t(term.plain))
                    .ui(17).foregroundColor(Theme.textSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                if let more = term.more {
                    Text(lang.t(more))
                        .ui(15).foregroundColor(Theme.textMuted)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 14)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
}
