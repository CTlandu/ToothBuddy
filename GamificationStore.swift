import Foundation

/// Achievement badge for gamification.
struct Achievement: Identifiable, Equatable {
    let id: String
    let emoji: String
    let title: String
    let description: String
}

/// Gamification store: achievements, levels, badges. Computes from BrushingStore.
@MainActor
final class GamificationStore: ObservableObject {
    static let shared = GamificationStore()

    @Published private(set) var unlockedAchievementIds: Set<String> = []

    private let achievementKey = "ToothBuddy.unlockedAchievements"
    private let store = BrushingStore.shared

    private init() {
        loadUnlocked()
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

    var levelEmoji: String {
        switch level {
        case 5: return "👑"
        case 4: return "🌟"
        case 3: return "⭐"
        case 2: return "✨"
        case 1: return "🦷"
        default: return "🌱"
        }
    }

    static let allAchievements: [Achievement] = [
        Achievement(id: "first-brush", emoji: "🪥", title: "First Brush", description: "Complete your first brushing session"),
        Achievement(id: "five-sessions", emoji: "5️⃣", title: "Getting Started", description: "Complete 5 brushing sessions"),
        Achievement(id: "ten-sessions", emoji: "🔟", title: "On a Roll", description: "Complete 10 brushing sessions"),
        Achievement(id: "streak-3", emoji: "🔥", title: "3-Day Streak", description: "Brush 3 days in a row"),
        Achievement(id: "streak-7", emoji: "🏆", title: "Week Warrior", description: "Brush 7 days in a row"),
        Achievement(id: "two-min", emoji: "⏱️", title: "2-Minute Master", description: "Brush for 2 minutes in one session"),
        Achievement(id: "five-perfect", emoji: "⭐", title: "Perfect Five", description: "Get 3 stars in 5 sessions"),
        Achievement(id: "early-bird", emoji: "🌅", title: "Early Bird", description: "Brush before 8 AM"),
    ]

    var unlockedAchievements: [Achievement] {
        Self.allAchievements.filter { unlockedAchievementIds.contains($0.id) }
    }

    func checkAndUnlock(records: [BrushingRecord]) {
        var newlyUnlocked: [String] = []

        if records.count >= 1, !unlockedAchievementIds.contains("first-brush") {
            newlyUnlocked.append("first-brush")
        }
        if records.count >= 5, !unlockedAchievementIds.contains("five-sessions") {
            newlyUnlocked.append("five-sessions")
        }
        if records.count >= 10, !unlockedAchievementIds.contains("ten-sessions") {
            newlyUnlocked.append("ten-sessions")
        }

        let streak = store.consecutiveDaysCount
        if streak >= 3, !unlockedAchievementIds.contains("streak-3") {
            newlyUnlocked.append("streak-3")
        }
        if streak >= 7, !unlockedAchievementIds.contains("streak-7") {
            newlyUnlocked.append("streak-7")
        }

        let hasTwoMin = records.contains { $0.durationSeconds >= 120 }
        if hasTwoMin, !unlockedAchievementIds.contains("two-min") {
            newlyUnlocked.append("two-min")
        }

        let perfectCount = records.filter { $0.starCount >= 3 }.count
        if perfectCount >= 5, !unlockedAchievementIds.contains("five-perfect") {
            newlyUnlocked.append("five-perfect")
        }

        let calendar = Calendar.current
        let hasEarlyBird = records.contains { record in
            calendar.component(.hour, from: record.startDate) < 8
        }
        if hasEarlyBird, !unlockedAchievementIds.contains("early-bird") {
            newlyUnlocked.append("early-bird")
        }

        for id in newlyUnlocked {
            unlockedAchievementIds.insert(id)
        }
        if !newlyUnlocked.isEmpty {
            saveUnlocked()
        }
    }

    private func loadUnlocked() {
        guard let data = UserDefaults.standard.data(forKey: achievementKey),
              let ids = try? JSONDecoder().decode([String].self, from: data) else { return }
        unlockedAchievementIds = Set(ids)
    }

    private func saveUnlocked() {
        let ids = Array(unlockedAchievementIds)
        guard let data = try? JSONEncoder().encode(ids) else { return }
        UserDefaults.standard.set(data, forKey: achievementKey)
    }
}
