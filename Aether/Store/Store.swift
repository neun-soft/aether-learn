import Foundation
import StoreKit

// The paid unlock. One non-consumable: buy once, own the whole course forever, on every
// device signed into the same Apple ID. There is no server and no third-party SDK —
// StoreKit is the source of truth and `Transaction.currentEntitlements` is the receipt.
@MainActor
final class Store: ObservableObject {
    /// Must match the product ID created in App Store Connect exactly.
    static let fullCourseID = "app.neun.aether.learn.fullcourse"

    /// CURRENT_PROJECT_VERSION of the first freemium release — the build where the app went
    /// from $1.99-to-download to free-with-an-unlock. Anyone whose *original* download predates
    /// it bought the whole app outright, so they own the whole course. Build numbers are
    /// timestamps (see project.yml), so a plain integer compare orders them correctly.
    ///
    /// MUST be <= the freemium build's CURRENT_PROJECT_VERSION, or paying users get locked out.
    static let firstFreemiumBuild = 202607140000

    /// How the paywall's buy button should present itself. We never render a purchase button
    /// without a price on it — asking for money without naming the amount is not something
    /// we do, so a failed product load becomes a visible retry instead of a silent blank.
    enum ProductState { case loading, ready, failed }

    @Published private(set) var product: Product?
    @Published private(set) var productState: ProductState = .loading
    @Published private(set) var isWorking = false      // a purchase or restore is in flight
    @Published var errorMessage: String?

    /// Owns the IAP, per StoreKit.
    @Published private(set) var purchased: Bool

    /// Used the app back when the whole course was free, and got real work done in what is
    /// now paid content. We don't take that away — see `grandfatherIfLegacyUser`.
    @Published private(set) var legacyUnlock: Bool

    /// The only question the UI ever asks.
    var isUnlocked: Bool { purchased || legacyUnlock }

    // Mirrors the entitlement so a paying user never sees a locked UI during the async
    // check on launch (or offline). StoreKit still has the final say: `refresh()` corrects
    // this in both directions, including after a refund.
    private static let cacheKey = "aetherlearn.unlocked.v1"
    private static let legacyKey = "aetherlearn.legacyUnlock.v1"

    // Set when a DEBUG env var pins the entitlement, so nothing downstream can quietly
    // undo it — the legacy amnesty in particular, which would otherwise re-unlock a
    // simulator that has old progress and make AETHER_UNLOCKED=0 useless for QA.
    private var debugPinned = false

    /// Price as StoreKit formats it for the user's storefront ("$4.99", "4,99 €"...).
    /// Falls back to nothing rather than a hardcoded price, which could be wrong abroad.
    var displayPrice: String? {
        #if DEBUG
        if let stub = stubbedPrice { return stub }
        #endif
        return product?.displayPrice
    }

    #if DEBUG
    /// Price to render instead of StoreKit's, set by AETHER_STUB_PRICE. Exists because the
    /// StoreKit test server only runs when Xcode launches the app from a scheme — a headless
    /// `simctl launch`, which is how the paywall screenshot gets captured, always sees an empty
    /// product list and would shoot "Price unavailable". Compiled out of the shipped binary.
    private var stubbedPrice: String? {
        let v = ProcessInfo.processInfo.environment["AETHER_STUB_PRICE"]
        return (v?.isEmpty ?? true) ? nil : v
    }
    #endif

    init() {
        purchased = UserDefaults.standard.bool(forKey: Self.cacheKey)
        legacyUnlock = UserDefaults.standard.bool(forKey: Self.legacyKey)

        #if DEBUG
        // The screenshot harness deep-links straight into paid lessons to capture App Store
        // shots — it must never be handed the paywall. AETHER_UNLOCKED forces either state
        // for QA, and skips the StoreKit listeners so nothing corrects it back.
        let env = ProcessInfo.processInfo.environment
        if Shot.active || env["AETHER_UNLOCKED"] == "1" {
            legacyUnlock = true
            debugPinned = true
            return
        }
        if env["AETHER_UNLOCKED"] == "0" {
            purchased = false
            legacyUnlock = false
            debugPinned = true
            return
        }
        #endif

        // Catches purchases made outside this launch: Ask to Buy approvals, a purchase on
        // another device, a refund revoking the entitlement.
        Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = update {
                    await transaction.finish()
                    await self.refresh()
                }
            }
        }

        Task {
            await grandfatherIfOriginalPurchaser()
            await loadProduct()
            await refresh()
        }
    }

    /// The app used to cost $1.99 to download. Everyone who bought it at that price paid for
    /// the entire course, so charging them a second time to see modules they already own is
    /// out of the question — App Review takes a dim view of it, and it would be a lousy thing
    /// to do to the only people who backed this thing early.
    ///
    /// `originalAppVersion` is the build they *first* downloaded, not the one they're running,
    /// so it survives updates and reinstalls on a new device. In TestFlight and sandbox it
    /// isn't a real build number and won't parse — that's fine, the progress-based amnesty in
    /// `grandfatherIfLegacyUser` still covers anyone who actually used the paid content.
    private func grandfatherIfOriginalPurchaser() async {
        guard !debugPinned, !legacyUnlock else { return }
        guard let result = try? await AppTransaction.shared,
              case .verified(let appTransaction) = result,
              let originalBuild = Int(appTransaction.originalAppVersion)
        else { return }

        if originalBuild < Self.firstFreemiumBuild { setLegacyUnlock() }
    }

    func loadProduct() async {
        #if DEBUG
        // A stubbed price is a ready price — otherwise the footer sits on the spinner forever
        // waiting for a product that this process can never load.
        if stubbedPrice != nil { productState = .ready; return }
        #endif
        if product != nil { productState = .ready; return }
        productState = .loading
        do {
            // An empty result is a failure, not a success: it means the product ID doesn't
            // exist in App Store Connect (or isn't approved yet), which is exactly the case
            // we must not paper over with a priceless buy button.
            guard let loaded = try await Product.products(for: [Self.fullCourseID]).first else {
                productState = .failed
                return
            }
            product = loaded
            productState = .ready
        } catch {
            // Offline or the App Store is unreachable. The paywall offers a retry, and the
            // user's existing entitlement (if any) is unaffected.
            productState = .failed
        }
    }

    /// Re-reads the entitlement from StoreKit. This is the only thing that flips `isUnlocked`.
    func refresh() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.fullCourseID, transaction.revocationDate == nil {
                owned = true
            }
        }
        setUnlocked(owned)
    }

    /// Buys the unlock. Returns true only when the user now owns it.
    @discardableResult
    func purchase() async -> Bool {
        guard !isWorking else { return false }
        if product == nil { await loadProduct() }
        guard let product else {
            errorMessage = "Couldn't reach the App Store. Check your connection and try again."
            return false
        }

        isWorking = true
        defer { isWorking = false }

        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    errorMessage = "That purchase couldn't be verified. You have not been charged."
                    return false
                }
                await transaction.finish()
                setUnlocked(true)
                return true

            case .pending:
                // Ask to Buy / SCA. Transaction.updates delivers it if and when it's approved.
                errorMessage = "Your purchase is pending approval. The course unlocks as soon as it goes through."
                return false

            case .userCancelled:
                return false

            @unknown default:
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Restores a previous purchase. Apple requires an explicit control for this.
    @discardableResult
    func restore() async -> Bool {
        guard !isWorking else { return false }
        isWorking = true
        defer { isWorking = false }

        do {
            try await AppStore.sync()
        } catch {
            // A cancelled sign-in sheet lands here too, so don't shout about it — just
            // fall through and check the entitlement we already have.
        }
        await refresh()

        if !isUnlocked {
            errorMessage = "No previous purchase found on this Apple ID."
        }
        return isUnlocked
    }

    /// One-time amnesty, run at launch. Someone who already completed lessons in what is now
    /// paid content used this app when the whole course was free — locking them out of work
    /// they'd already done would be a bait-and-switch, and they're precisely the users whose
    /// reviews we live on. Keep them whole, forever. New users can't trigger it: finishing
    /// the free module leaves zero completions outside it.
    func grandfatherIfLegacyUser(progress: ProgressStore) {
        guard !debugPinned, !legacyUnlock else { return }
        let usedPaidContent = Curriculum.course.allLessons.contains { lesson in
            !Curriculum.isFree(lessonID: lesson.id) && progress.isDone(lesson.id)
        }
        guard usedPaidContent else { return }
        setLegacyUnlock()
    }

    private func setLegacyUnlock() {
        legacyUnlock = true
        UserDefaults.standard.set(true, forKey: Self.legacyKey)
    }

    private func setUnlocked(_ value: Bool) {
        purchased = value
        UserDefaults.standard.set(value, forKey: Self.cacheKey)
    }
}
