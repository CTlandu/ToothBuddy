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
        let total = store.records.count
        if total >= 50 { return 5 }
        if total >= 30 { return 4 }
        if total >= 15 { return 3 }
        if total >= 5 { return 2 }
        if total >= 1 { return 1 }
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

    static let allAchievements: [Achievement] = [
        Achievement(id: "first-brush",    systemImage: "drop.fill",      title: "First Brush",     description: "Complete your first brushing session"),
        Achievement(id: "five-sessions",  systemImage: "5.circle.fill",  title: "Getting Started", description: "Complete 5 brushing sessions"),
        Achievement(id: "ten-sessions",   systemImage: "10.circle.fill", title: "On a Roll",       description: "Complete 10 brushing sessions"),
        Achievement(id: "streak-3",       systemImage: "flame.fill",     title: "3-Day Streak",    description: "Brush 3 days in a row"),
        Achievement(id: "streak-7",       systemImage: "trophy.fill",    title: "Week Warrior",    description: "Brush 7 days in a row"),
        Achievement(id: "two-min",        systemImage: "timer",          title: "2-Minute Master", description: "Brush for 2 minutes in one session"),
        Achievement(id: "five-perfect",   systemImage: "star.fill",      title: "Perfect Five",    description: "Get 3 stars in 5 sessions"),
        Achievement(id: "early-bird",     systemImage: "sunrise.fill",   title: "Early Bird",      description: "Brush before 8 AM"),
    ]

    var unlockedAchievements: [Achievement] {
        Self.allAchievements.filter { unlockedAchievementIds.contains($0.id) }
    }

    /// Human-readable progress, e.g. "7 / 10 sessions".
    func progressDescription(for achievement: Achievement, records: [BrushingRecord]) -> String {
        let streak = store.consecutiveDaysCount
        switch achievement.id {
        case "first-brush":
            return "\(min(records.count, 1)) / 1 session"
        case "five-sessions":
            return "\(min(records.count, 5)) / 5 sessions"
        case "ten-sessions":
            return "\(min(records.count, 10)) / 10 sessions"
        case "streak-3":
            return "\(min(streak, 3)) / 3 days in a row"
        case "streak-7":
            return "\(min(streak, 7)) / 7 days in a row"
        case "two-min":
            let done = records.contains { $0.durationSeconds >= 120 }
            return done ? "1 / 1 session" : "0 / 1 session"
        case "five-perfect":
            let count = records.filter { $0.starCount >= 3 }.count
            return "\(min(count, 5)) / 5 perfect sessions"
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

        consider("first-brush",   records.count >= 1)
        consider("five-sessions", records.count >= 5)
        consider("ten-sessions",  records.count >= 10)

        let streak = store.consecutiveDaysCount
        consider("streak-3", streak >= 3)
        consider("streak-7", streak >= 7)

        consider("two-min", records.contains { $0.durationSeconds >= 120 })
        consider("five-perfect", records.filter { $0.starCount >= 3 }.count >= 5)

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
