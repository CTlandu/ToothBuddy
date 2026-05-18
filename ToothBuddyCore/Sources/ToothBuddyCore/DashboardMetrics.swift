import Foundation

/// One profile's row on the Group dashboard (Spec 02 §6.5 / AC8). Pure value type.
public struct DashboardMetric: Equatable, Sendable {
    public let profileID: UUID
    public let didMorningToday: Bool
    public let didEveningToday: Bool
    public let currentStreak: Int
    public let longestStreak: Int
    /// Distinct active days within the last 7 calendar days (incl. today), 0...7.
    public let last7DaysActive: Int
    /// Active days per 7-day block for the last 4 blocks, oldest→newest, each 0...7.
    /// `weeklyTrend.last == last7DaysActive`.
    public let weeklyTrend: [Int]
    public let missedYesterday: Bool

    public init(profileID: UUID, didMorningToday: Bool, didEveningToday: Bool,
                currentStreak: Int, longestStreak: Int, last7DaysActive: Int,
                weeklyTrend: [Int], missedYesterday: Bool) {
        self.profileID = profileID
        self.didMorningToday = didMorningToday
        self.didEveningToday = didEveningToday
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.last7DaysActive = last7DaysActive
        self.weeklyTrend = weeklyTrend
        self.missedYesterday = missedYesterday
    }
}

/// Pure, deterministic dashboard computation. Reuses `StreakEngine` so streak/longest
/// always match the rest of the app. Spec 02 §6.5.
public enum DashboardMetrics {

    public static func compute(profileID: UUID,
                               in allRecords: [BrushingRecord],
                               now: Date,
                               config: StreakConfig,
                               calendar: Calendar) -> DashboardMetric {
        let records = ProfileScopedAggregator.records(for: profileID, in: allRecords)
        let streak = StreakEngine.evaluate(records: records, now: now,
                                           config: config, calendar: calendar)

        let today0 = calendar.startOfDay(for: now)
        func day(_ offset: Int) -> Date {
            calendar.date(byAdding: .day, value: offset, to: today0) ?? today0
        }

        // Slots present today.
        var didMorning = false, didEvening = false
        for r in records where calendar.startOfDay(for: r.startDate) == today0 {
            switch SessionSlot.slot(for: r.startDate,
                                    boundaryHour: config.slotBoundaryHour,
                                    calendar: calendar) {
            case .morning: didMorning = true
            case .evening: didEvening = true
            }
        }

        // Set of active days (≤ today).
        let activeDays: Set<Date> = Set(records.compactMap { r -> Date? in
            let d = calendar.startOfDay(for: r.startDate)
            return d <= today0 ? d : nil
        })

        func activeCount(inBlockEndingDaysAgo endOffset: Int) -> Int {
            // 7-day block: [day(endOffset-6) ... day(endOffset)] inclusive.
            (0..<7).reduce(0) { acc, i in
                acc + (activeDays.contains(day(endOffset - i)) ? 1 : 0)
            }
        }

        // Trend: oldest→newest; block k ends `7*k` days ago. last == last 7 days.
        let trend = (0..<4).reversed().map { k in activeCount(inBlockEndingDaysAgo: -7 * k) }
        let last7 = trend.last ?? 0
        let missedYesterday = !activeDays.contains(day(-1))

        return DashboardMetric(profileID: profileID,
                               didMorningToday: didMorning,
                               didEveningToday: didEvening,
                               currentStreak: streak.currentStreak,
                               longestStreak: streak.longestStreak,
                               last7DaysActive: last7,
                               weeklyTrend: trend,
                               missedYesterday: missedYesterday)
    }
}
