import Foundation
import ToothBuddyCore

/// Per-device ring of recently shown content ids so the selector doesn't repeat
/// (Spec 03 §6). Not synced, not per-profile — purely a local "don't say the same
/// thing twice" memory.
@MainActor
final class ContentHistoryStore {
    static let shared = ContentHistoryStore()

    private let key = "ToothBuddy.contentHistory"
    private let maxCount = 8

    /// Current tone (per-device, Spec 03 §5.5). Default playful.
    var tone: ContentTone {
        UserDefaults.standard.string(forKey: "ToothBuddy.contentTone") == "essentials"
            ? .essentials : .playful
    }
    func setTone(_ t: ContentTone) {
        UserDefaults.standard.set(t == .essentials ? "essentials" : "playful",
                                  forKey: "ToothBuddy.contentTone")
    }

    /// True once the user has explicitly chosen a tone (the P3 toggle was touched).
    var toneExplicitlySet: Bool {
        UserDefaults.standard.object(forKey: "ToothBuddy.contentTone") != nil
    }

    /// Spec 05 §6.1 — an explicit user tone always wins; otherwise an `adult` profile
    /// defaults to `.essentials` and a `kid` profile to `.playful`.
    func effectiveTone(forAdult isAdult: Bool) -> ContentTone {
        if toneExplicitlySet { return tone }
        return isAdult ? .essentials : .playful
    }

    func recent() -> [UUID] {
        (UserDefaults.standard.array(forKey: key) as? [String] ?? [])
            .compactMap(UUID.init(uuidString:))
    }

    func record(_ id: UUID) {
        var ids = UserDefaults.standard.array(forKey: key) as? [String] ?? []
        ids.removeAll { $0 == id.uuidString }
        ids.append(id.uuidString)
        if ids.count > maxCount { ids.removeFirst(ids.count - maxCount) }
        UserDefaults.standard.set(ids, forKey: key)
    }
}
