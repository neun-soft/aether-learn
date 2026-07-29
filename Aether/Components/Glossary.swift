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
/// Built as a single concatenated `Text` rather than a wrapped `HStack` of words, so the
/// paragraph keeps normal line breaking and justification. The tap is caught by an invisible
/// overlay of buttons — `Text` cannot host a per-run gesture before iOS 17's `AttributedString`
/// link handling, and this stays legible on the older deployment target.
struct TermText: View {
    let paragraph: String
    let terms: [Term]
    let accent: Color
    var onTap: (Term) -> Void

    var body: some View {
        // Split the paragraph into alternating plain / term runs, longest terms first so
        // "pink noise" wins over "noise" when both are defined.
        let runs = TermText.split(paragraph, terms: terms.sorted { $0.word.count > $1.word.count })

        // Flow the runs as wrapping text. Each term run becomes its own tappable Text.
        FlowLayout(spacing: 0) {
            ForEach(Array(runs.enumerated()), id: \.offset) { _, run in
                switch run {
                case .plain(let s):
                    Text(s).ui(15).foregroundColor(Theme.textSecondary)
                case .term(let word, let term):
                    Text(word)
                        .ui(15, .medium)
                        .foregroundColor(accent)
                        .underline(true, color: accent.opacity(0.45))
                        .onTapGesture { onTap(term) }
                }
            }
        }
    }

    enum Run {
        case plain(String)
        case term(String, Term)
    }

    /// Splits on whole-word matches only, so "noisy" never matches the term "noise".
    static func split(_ text: String, terms: [Term]) -> [Run] {
        guard !terms.isEmpty else { return [.plain(text)] }
        var out: [Run] = []
        var buffer = ""
        let scalars = Array(text)
        var i = 0

        func isBoundary(_ idx: Int) -> Bool {
            guard idx >= 0, idx < scalars.count else { return true }
            return !scalars[idx].isLetter && !scalars[idx].isNumber
        }

        outer: while i < scalars.count {
            for term in terms {
                let w = Array(term.word)
                guard i + w.count <= scalars.count else { continue }
                let candidate = String(scalars[i..<(i + w.count)])
                guard candidate.lowercased() == term.word.lowercased() else { continue }
                guard isBoundary(i - 1), isBoundary(i + w.count) else { continue }
                if !buffer.isEmpty { out.append(.plain(buffer)); buffer = "" }
                out.append(.term(candidate, term))
                i += w.count
                continue outer
            }
            buffer.append(scalars[i])
            i += 1
        }
        if !buffer.isEmpty { out.append(.plain(buffer)) }
        return out
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

// MARK: - Wrapping layout for the term runs

/// Lays children out left to right, wrapping like text. Used so a paragraph containing tappable
/// words still breaks lines normally instead of running off the edge.
struct FlowLayout: Layout {
    var spacing: CGFloat = 0

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0
        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0; y += lineHeight + spacing; lineHeight = 0
            }
            x += size.width
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineHeight: CGFloat = 0
        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX; y += lineHeight + spacing; lineHeight = 0
            }
            sv.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width
            lineHeight = max(lineHeight, size.height)
        }
    }
}
