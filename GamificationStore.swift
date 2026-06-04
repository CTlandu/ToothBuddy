import Foundation
import CoreData
import Combine
import ToothBuddyCore

/// Achievement badge for gamification.
struct Achievement: Identifiable, Equatable {
    let id: String
    let systemImage: String
    let title: String
    let description: String
}

/// Per-profile gamification (Spec 02 §6.3 / AC4). Unlocked achievements are stored in
/// Core Data as `CDAchievementUnlock` rows scoped to the active profile.
@MainActor
final class GamificationStore: ObservableObject {
    static let shared = GamificationStore()

    @Published private(set) var unlockedAchievementIds: Set<String> = []

    private let store: BrushingStore
    private let profiles: ProfileStore
    private let ctx: NSManagedObjectContext
    private var cancellables: Set<AnyCancellable> = []

    // Quality audit 2026-05-28 / Plan U4: `init` is `internal` (not `private`) so
    // unit tests can inject an isolated PersistenceController + ProfileStore +
    // BrushingStore triple. Production code still uses `GamificationStore.shared`.
    init(controller: PersistenceController = .shared,
         profiles: ProfileStore = .shared,
         brushing: BrushingStore = .shared) {
        ctx = controller.viewContext
        self.profiles = profiles
        self.store = brushing
        loadUnlocked()
        profiles.$activeProfileID
            .dropFirst()
            .sink { [weak self] _ in self?.loadUnlocked() }
            .store(in: &cancellables)
    }

    var level: Int {
        // U11 — levels track *thorough* (target-met) sessions, not raw count.
        let thorough = store.records.filter { $0.metMinimum }.count
        if thorough >= 50 { return 5 }
        if thorough >= 30 { return 4 }
        if thorough >= 15 { return 3 }
        if thorough >= 5 { return 2 }
        if thorough >= 1 { return 1 }
        return 0
    }

    var levelTitle: String {
        switch level {
        case 5: return "Tooth Champion"
        case 4: return "Super Brusher"
        case 3: return "Brushing Pro"
        case 2: return "Rising Star"
        case 1: return "Getting Started"
        default: return "Newcomer"
        }
    }

    /// Returns the SF Symbol name for the current level icon.
    var levelSystemImage: String {
        switch level {
        case 5: return "crown.fill"
        case 4: return "star.circle.fill"
        case 3: return "star.fill"
        case 2: return "sparkles"
        case 1: return "mouth.fill"
        default: return "leaf.fill"
        }
    }

    // Plan U8: Achievement.title runs through String(localized:) so each badge
    // shows in the active locale. Achievement.description is content-asset prose
    // and is deferred to a follow-up content-translation plan.
    static let allAchievements: [Achievement] = [
        Achievement(id: "first-brush",      systemImage: "drop.fill",             title: String(localized: "First Brush"),      description: "Complete your first brushing session"),
        Achievement(id: "two-min",          systemImage: "timer",                 title: String(localized: "Full Two Minutes"), description: "Brush for the full target time in one session"),
        Achievement(id: "first-thorough",   systemImage: "checkmark.seal.fill",   title: String(localized: "Thorough Brush"),   description: "Cover every area for long enough in one session"),
        Achievement(id: "verified",         systemImage: "checkmark.shield.fill", title: String(localized: "Camera-Verified"),  description: "Finish a session confirmed by the camera"),
        Achievement(id: "five-thorough",    systemImage: "5.circle.fill",         title: String(localized: "Five Thorough"),    description: "Finish 5 thorough sessions"),
        Achievement(id: "fifteen-thorough", systemImage: "star.fill",             title: String(localized: "Fifteen Thorough"), description: "Finish 15 thorough sessions"),
        Achievement(id: "streak-7",         systemImage: "flame.fill",            title: String(localized: "Week Warrior"),     description: "Brush 7 days in a row"),
        Achievement(id: "early-bird",       systemImage: "sunrise.fill",          title: String(localized: "Early Bird"),       description: "Brush before 8 AM"),
    ]

    var unlockedAchievements: [Achievement] {
        Self.allAchievements.filter { unlockedAchievementIds.contains($0.id) }
    }

    /// Human-readable progress, e.g. "7 / 10 sessions".
    func progressDescription(for achievement: Achievement, records: [BrushingRecord]) -> String {
        let thorough = records.filter { $0.metMinimum }.count
        switch achievement.id {
        case "first-brush":
            return "\(min(records.count, 1)) / 1 session"
        case "two-min":
            let done = records.contains { $0.activeSeconds >= $0.targetSeconds }
            return done ? "1 / 1 session" : "0 / 1 session"
        case "first-thorough":
            return "\(min(thorough, 1)) / 1 thorough brush"
        case "verified":
            let done = records.contains { $0.cameraVerified }
            return done ? "1 / 1 verified" : "0 / 1 verified"
        case "five-thorough":
            return "\(min(thorough, 5)) / 5 thorough brushes"
        case "fifteen-thorough":
            return "\(min(thorough, 15)) / 15 thorough brushes"
        case "streak-7":
            return "\(min(store.consecutiveDaysCount, 7)) / 7 days in a row"
        case "early-bird":
            let cal = Calendar.current
            let done = records.contains { cal.component(.hour, from: $0.startDate) < 8 }
            return done ? "1 / 1 morning brush" : "0 / 1 morning brush"
        default:
            return ""
        }
    }

    func checkAndUnlock(records: [BrushingRecord]) {
        var newlyUnlocked: [String] = []
        func consider(_ id: String, _ condition: Bool) {
            if condition, !unlockedAchievementIds.contains(id) { newlyUnlocked.append(id) }
        }

        let thorough = records.filter { $0.metMinimum }.count
        consider("first-brush", records.count >= 1)
        consider("two-min", records.contains { $0.activeSeconds >= $0.targetSeconds })
        consider("first-thorough", thorough >= 1)
        consider("verified", records.contains { $0.cameraVerified })
        consider("five-thorough", thorough >= 5)
        consider("fifteen-thorough", thorough >= 15)
        // Streak kept as a light consistency badge — no longer a hero metric (U11).
        consider("streak-7", store.consecutiveDaysCount >= 7)

        let cal = Calendar.current
        consider("early-bird", records.contains { cal.component(.hour, from: $0.startDate) < 8 })

        guard !newlyUnlocked.isEmpty, let pid = profiles.activeProfileID,
              let cdp = profiles.managedProfile(pid) else { return }
        for id in newlyUnlocked {
            unlockedAchievementIds.insert(id)
            let row = CDAchievementUnlock(context: ctx)
            row.achievementID = id
            row.unlockedAt = Date()
            row.profile = cdp
        }
        if ctx.hasChanges { try? ctx.save() }
    }

    /// Load the active profile's unlocked achievements from Core Data.
    private func loadUnlocked() {
        guard let pid = profiles.activeProfileID else { unlockedAchievementIds = []; return }
        let req = NSFetchRequest<CDAchievementUnlock>(entityName: "CDAchievementUnlock")
        req.predicate = NSPredicate(format: "profile.id == %@", pid as CVarArg)
        let rows = (try? ctx.fetch(req)) ?? []
        unlockedAchievementIds = Set(rows.compactMap { $0.achievementID })
    }
}
