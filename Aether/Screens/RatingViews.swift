import SwiftUI

// Where the app points people for reviews and support.
enum AppLinks {
    static let appleID = "6786776504"
    // Deep link that opens the App Store straight on the "write a review" sheet.
    static let writeReview = URL(string: "https://apps.apple.com/app/id\(appleID)?action=write-review")!
    static let supportEmail = "support@neunsoft.com"
}

// MARK: - Thumbs up / down row (module complete)

// The "did you enjoy this?" prompt shown on the module-complete screen.
// The buttons stay on screen and reflect the current choice, so a mis-tap is
// a single tap to correct. Reports each change; the parent decides what to show.
struct RatingPrompt: View {
    var accent: Color
    var selection: Bool?                    // current stored rating (nil = not yet rated)
    var onRate: (_ thumbsUp: Bool) -> Void

    @EnvironmentObject var lang: LangStore

    private var prompt: String {
        switch selection {
        case .some(true): return "Glad you enjoyed it — thanks!"
        case .some(false): return "Thanks for the honesty."
        case .none: return "Did you enjoy this module?"
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            Text(lang.t(prompt))
                .ui(14, .medium).foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.2), value: selection)

            HStack(spacing: 14) {
                thumb(up: true)
                thumb(up: false)
            }
        }
    }

    private func thumb(up: Bool) -> some View {
        let isSel = selection == up
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { onRate(up) }
        } label: {
            Image(systemName: up ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(isSel ? (up ? accent : Theme.textPrimary) : Theme.textDim)
                .frame(width: 72, height: 60)
                .background(isSel ? (up ? accent.opacity(0.14) : Theme.inset) : Theme.panelAlt)
                .clipShape(RoundedRectangle(cornerRadius: Theme.rRow, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.rRow, style: .continuous)
                        .stroke(isSel ? (up ? accent.opacity(0.45) : Theme.hairline(0.18)) : Theme.hairline(), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Review request (shown after 3 happy modules)

struct ReviewRequestView: View {
    var accent: Color
    var onClose: () -> Void

    @EnvironmentObject var lang: LangStore
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            Theme.bgGradient.ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer()

                ZStack {
                    Circle().fill(accent.opacity(0.10)).frame(width: 150, height: 150)
                    Circle().stroke(accent.opacity(0.30), lineWidth: 1.5).frame(width: 126, height: 126)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundColor(accent)
                }

                Text(lang.t("ENJOYING AETHER?"))
                    .mono(12, .semibold).tracking(3).foregroundColor(accent)

                Text(lang.t("Would you leave us a review?"))
                    .ui(30, .semibold).foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)

                Text(lang.t("We're a tiny studio, and a few kind words on the App Store is what helps new people find Aether. It genuinely makes a difference — thank you."))
                    .ui(15).foregroundColor(Theme.textMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        openURL(AppLinks.writeReview)
                        onClose()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                            Text(lang.t("Leave a review"))
                        }
                        .font(AppFont.ui(15, .semibold)).foregroundColor(.black)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(accent).clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Button(action: onClose) {
                        Text(lang.t("Maybe later"))
                            .font(AppFont.ui(15, .semibold)).foregroundColor(Theme.textMuted)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20).padding(.bottom, 16)
            }
        }
    }
}

// MARK: - Feedback (shown after a thumbs down)

struct FeedbackView: View {
    var accent: Color
    var moduleID: String
    var onClose: () -> Void

    @EnvironmentObject var lang: LangStore
    @EnvironmentObject var progress: ProgressStore
    @State private var text = ""
    @State private var sent = false
    @FocusState private var editing: Bool

    private var canSend: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        ZStack {
            Theme.bgGradient.ignoresSafeArea()
            VStack(spacing: 18) {
                Spacer(minLength: 24)

                ZStack {
                    Circle().fill(accent.opacity(0.10)).frame(width: 120, height: 120)
                    Image(systemName: sent ? "checkmark.circle.fill" : "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(accent)
                }

                Text(lang.t(sent ? "Thank you — we hear you." : "What can we do better?"))
                    .ui(28, .semibold).foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)

                Text(lang.t(sent
                    ? "We read every note. This is exactly how a small studio gets better."
                    : "You know this one didn't land, and we'd really like to know why. We read every note — it's how a small studio gets better."))
                    .ui(15).foregroundColor(Theme.textMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)

                if !sent {
                    ZStack(alignment: .topLeading) {
                        if text.isEmpty {
                            Text(lang.t("Tell us what tripped you up…"))
                                .ui(15).foregroundColor(Theme.textDim)
                                .padding(.horizontal, 16).padding(.vertical, 14)
                        }
                        TextEditor(text: $text)
                            .focused($editing)
                            .font(AppFont.ui(15))
                            .foregroundColor(Theme.textPrimary)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                    }
                    .frame(height: 130)
                    .panel(14)
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 12)

                VStack(spacing: 12) {
                    if sent {
                        Button(action: onClose) {
                            Text(lang.t("Done"))
                                .font(AppFont.ui(15, .semibold)).foregroundColor(.black)
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(accent).clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            editing = false
                            progress.recordFeedback(moduleID: moduleID, text: text)
                            withAnimation(.easeInOut(duration: 0.2)) { sent = true }
                        } label: {
                            Text(lang.t("Send feedback"))
                                .font(AppFont.ui(15, .semibold)).foregroundColor(.black)
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(accent).clipShape(RoundedRectangle(cornerRadius: 14))
                                .opacity(canSend ? 1 : 0.5)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSend)

                        Button(action: onClose) {
                            Text(lang.t("Not now"))
                                .font(AppFont.ui(15, .semibold)).foregroundColor(Theme.textMuted)
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 16)
            }
        }
        .onTapGesture { editing = false }
    }
}
