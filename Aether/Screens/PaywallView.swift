import SwiftUI

// The one and only paywall. Presented when someone finishes the free module or taps a
// locked lesson. Sells a single non-consumable: the rest of the course, forever.
struct PaywallView: View {
    var onDismiss: () -> Void

    @EnvironmentObject var store: Store
    @EnvironmentObject var lang: LangStore

    // Apple's standard EULA, which applies unless we ship our own terms. Required alongside
    // the privacy link on any screen that sells something.
    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let privacyURL = URL(string: "https://aether.neunsoft.com/privacy")!

    private var lockedModules: [Module] {
        Curriculum.course.modules.filter { !Curriculum.isFree(moduleID: $0.id) }
    }

    var body: some View {
        ZStack {
            Theme.bgGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                closeButton

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        headline
                        moduleList
                        Text(lang.t("You keep everything you've already finished. Your progress carries straight over."))
                            .ui(13).foregroundColor(Theme.textDim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 24)
                }

                footer
            }
        }
        .task { await store.loadProduct() }
        .onChange(of: store.isUnlocked) { _, unlocked in
            if unlocked { onDismiss() }   // bought or restored — get out of the way
        }
        .alert("Something went wrong",
               isPresented: Binding(get: { store.errorMessage != nil },
                                    set: { if !$0 { store.errorMessage = nil } })) {
            Button("OK", role: .cancel) { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    private var closeButton: some View {
        HStack {
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.textDim)
                    .frame(width: 32, height: 32)
                    .background(Theme.panel).clipShape(Circle())
                    .overlay(Circle().stroke(Theme.hairline(), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(lang.t("KEEP GOING"))
                .mono(11, .semibold).tracking(2.5)
                .foregroundColor(Theme.tone)
            Text(lang.t("The rest of the course"))
                .ui(30, .semibold)
                .foregroundColor(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            // Desire first, inventory second. "4 modules, 19 lessons" is a receipt; what they
            // actually want is to make the thing growl and move.
            Text(lang.t("Filters, envelopes, modulation — the parts that turn a tone into a sound you actually want. \(Curriculum.paidModuleCount) more modules, \(Curriculum.paidLessonCount) hands-on lessons."))
                .ui(15).foregroundColor(Theme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    private var moduleList: some View {
        VStack(spacing: 8) {
            ForEach(lockedModules) { module in
                HStack(spacing: 13) {
                    Circle().fill(module.accent).frame(width: 9, height: 9)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lang.t(module.title))
                            .ui(15, .medium).foregroundColor(Theme.textPrimary)
                        Text(lang.t(module.subtitle))
                            .ui(12).foregroundColor(Theme.textDim).lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    Text("\(module.lessons.count)")
                        .mono(12).foregroundColor(Theme.textFaint)
                }
                .padding(14)
                .panel(Theme.rRow)
            }
        }
    }

    // The real ask. Only ever rendered when StoreKit has given us a price to put on it.
    private var buyButton: some View {
        Button {
            Task { await store.purchase() }
        } label: {
            ZStack {
                if store.isWorking {
                    ProgressView().tint(.black)
                } else {
                    HStack(spacing: 8) {
                        Text(lang.t("Unlock everything"))
                        if let price = store.displayPrice {
                            Text("·").foregroundColor(.black.opacity(0.45))
                            Text(price)
                        }
                    }
                    .font(AppFont.ui(16, .semibold))
                    .foregroundColor(.black)
                }
            }
            .frame(maxWidth: .infinity).padding(.vertical, 15)
            .background(Theme.tone)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(store.isWorking)
    }

    // The App Store didn't answer. Say so plainly and let them try again, rather than
    // dangling a buy button that can only fail.
    private var retryButton: some View {
        Button {
            Task { await store.loadProduct() }
        } label: {
            VStack(spacing: 3) {
                Text(lang.t("Price unavailable"))
                    .font(AppFont.ui(15, .semibold)).foregroundColor(Theme.textPrimary)
                Text(lang.t("Tap to try again"))
                    .font(AppFont.data(11)).foregroundColor(Theme.textDim)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 11)
            .panel(14)
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        VStack(spacing: 10) {
            switch store.productState {
            case .ready:
                buyButton
            case .loading:
                // Never a buy button without a price — hold the shape, show it's coming.
                ZStack { ProgressView().tint(Theme.textMuted) }
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(Theme.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            case .failed:
                retryButton
            }

            Text(lang.t("One-time purchase. No subscription."))
                .ui(12).foregroundColor(Theme.textDim)

            HStack(spacing: 16) {
                Button { Task { await store.restore() } } label: {
                    Text(lang.t("Restore purchase"))
                        .mono(11).foregroundColor(Theme.textMuted)
                }
                .buttonStyle(.plain)
                .disabled(store.isWorking)

                Link(lang.t("Terms"), destination: termsURL)
                    .font(AppFont.data(11)).foregroundColor(Theme.textFaint)
                Link(lang.t("Privacy"), destination: privacyURL)
                    .font(AppFont.data(11)).foregroundColor(Theme.textFaint)
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 18)
        .background(
            Theme.bgBottom.opacity(0.92)
                .overlay(Rectangle().fill(Theme.hairline()).frame(height: 1), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// The lock chip drawn on paid lesson rows in the course list.
struct LockBadge: View {
    var body: some View {
        Image(systemName: "lock.fill")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Theme.textDim)
            .frame(width: 30, height: 30)
            .background(Theme.inset).clipShape(Circle())
            .overlay(Circle().stroke(Theme.hairline(0.10), lineWidth: 1))
    }
}
