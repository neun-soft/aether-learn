import Foundation
#if os(iOS)
import UIKit
#endif

// Feedback written on the module-complete screen used to stop at UserDefaults, which meant every
// note anyone ever wrote was stranded on their phone and unreadable by us. This uploads it.
//
// The device copy is not a fallback, it is the queue: a note is written to disk first and only
// removed once the server has taken it. Someone who types their honest opinion on a train and
// closes the app still gets heard the next time they open it on wifi.

/// One queued note. Codable so the queue survives relaunch as-is, including the id — retries
/// reuse it so a note that was delivered but whose response we lost is not stored twice.
struct FeedbackNote: Codable, Identifiable {
    let id: String
    let module: String
    let text: String
    let ts: Double

    init(module: String, text: String, ts: Double, id: String = UUID().uuidString) {
        self.id = id; self.module = module; self.text = text; self.ts = ts
    }
}

enum FeedbackService {
    /// Overridable from Info.plist (`AetherFeedbackEndpoint`) so a build can be pointed at a
    /// staging collector without a code change.
    static var endpoint: URL? {
        let s = Bundle.main.object(forInfoDictionaryKey: "AetherFeedbackEndpoint") as? String
        return URL(string: (s?.isEmpty == false ? s! : "https://aether.neunsoft.com/api/feedback"))
    }

    /// A random id created once per install. Not tied to anything about the person — it exists
    /// only so several notes from the same phone can be read as one conversation.
    static var installID: String {
        let key = "aetherlearn.installID.v1"
        if let existing = UserDefaults.standard.string(forKey: key) { return existing }
        let fresh = UUID().uuidString
        UserDefaults.standard.set(fresh, forKey: key)
        return fresh
    }

    private static var appVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(v) (\(b))"
    }

    private static var platform: String {
        #if os(iOS)
        return "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        #else
        return "macOS"
        #endif
    }

    /// POST one note. `done(true)` means the server has it and the queue may drop it.
    ///
    /// A 4xx other than 408/429 also counts as delivered: the server has decided it does not
    /// want this note, and retrying a request it has already rejected forever would mean the
    /// queue never drains.
    static func send(_ note: FeedbackNote, done: @escaping (Bool) -> Void) {
        guard let endpoint else { done(false); return }
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 20
        let body: [String: Any] = [
            "id": note.id,
            "install": installID,
            "module": note.module,
            "text": note.text,
            "ts": note.ts,
            "app": appVersion,
            "platform": platform,
            "locale": Locale.current.identifier,
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: req) { _, response, error in
            guard error == nil, let http = response as? HTTPURLResponse else { done(false); return }
            let code = http.statusCode
            let permanentlyRejected = (400..<500).contains(code) && code != 408 && code != 429
            done((200..<300).contains(code) || permanentlyRejected)
        }.resume()
    }
}
