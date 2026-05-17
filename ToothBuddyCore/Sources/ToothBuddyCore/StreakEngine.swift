import Foundation

/// Streak configuration. Spec 01 §4.3 — DECIDED: Option A rolling grace, GRACE_PERIOD = 7.
public struct StreakConfig: Equatable, Sendable {
    public var slotBoundaryHour: Int
    public var gracePeriod: Int
    public var requirePerfectDay: Bool

    public init(slotBoundaryHour: Int = 12, gracePeriod: Int = 7, requirePerfectDay: Bool = false) {
        self.slotBoundaryHour = slotBoundaryHour
        self.gracePeriod = gracePeriod
        self.requirePerfectDay = requirePerfectDay
    }

    public static let `default` = StreakConfig()
}

/// Result of a streak evaluation. Spec 01 §6.
public struct StreakResult: Equatable, Sendable {
    public let currentStreak: Int
    public let longestStreak: Int
    /// start-of-day of every "frozen" (bridged) missed day inside the current streak — UI shows "🛡 saved".
    public let frozenDays: [Date]
    /// true when today has no qualifying session yet but the streak (through yesterday) is > 0.
    public let isTodayPending: Bool

    public init(currentStreak: Int, longestStreak: Int, frozenDays: [Date], isTodayPending: Bool) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.frozenDays = frozenDays
        self.isTodayPending = isTodayPending
    }

    public static let empty = StreakResult(currentStreak: 0, longestStreak: 0, frozenDays: [], isTodayPending: false)
}

/// The single source of truth for streak math. Pure & deterministic — the TDD target.
/// Implements Spec 01 §4.3 Option A exactly (operating on the sorted distinct qualifying-day
/// sequence so cost is O(distinct days), independent of calendar span).
public enum StreakEngine {

    public static func evaluate(records: [BrushingRecord],
                                now: Date,
                                config: StreakConfig,
                                calendar: Calendar) -> StreakResult {
        let today0 = calendar.startOfDay(for: now)

        // 1. Group records by day → which slots occurred. Ignore future-dated days (> today0).
        var slotsByDay: [Date: (m: Bool, e: Bool)] = [:]
        for r in records {
            let day = calendar.startOfDay(for: r.startDate)
            if day > today0 { continue }
            let slot = SessionSlot.slot(for: r.startDate, boundaryHour: config.slotBoundaryHour, calendar: calendar)
            var entry = slotsByDay[day] ?? (false, false)
            if slot == .morning { entry.m = true } else { entry.e = true }
            slotsByDay[day] = entry
        }

        // Qualifying days (active = ≥1 session, or perfect = both slots when requirePerfectDay).
        let qualDays: [Date] = slotsByDay
            .filter { config.requirePerfectDay ? ($0.value.m && $0.value.e) : ($0.value.m || $0.value.e) }
            .map { $0.key }
            .sorted()

        guard !qualDays.isEmpty else { return .empty }

        func dayDiff(_ a: Date, _ b: Date) -> Int {
            calendar.dateComponents([.day], from: a, to: b).day ?? 0
        }
        // Missed days strictly between two consecutive qualifying days.
        func missedBetween(_ a: Date, _ b: Date) -> Int { max(0, dayDiff(a, b) - 1) }

        // 2. Anchor: today if qualifying, else yesterday if qualifying, else no anchor.
        let qualSet = Set(qualDays)
        let yesterday0 = calendar.date(byAdding: .day, value: -1, to: today0) ?? today0
        let anchorDay: Date?
        let todayQualifies = qualSet.contains(today0)
        if todayQualifies {
            anchorDay = today0
        } else if qualSet.contains(yesterday0) {
            anchorDay = yesterday0
        } else {
            anchorDay = nil
        }
        let anchorIndex: Int? = anchorDay.flatMap { d in qualDays.firstIndex(of: d) }

        // 3. Single left→right pass over qualifying days. Hard-break on ≥2 consecutive missed
        //    days; within a segment shrink L while missed > floor(qual / gracePeriod).
        var best = 0
        var currentStreak = 0
        var frozenDays: [Date] = []
        var left = 0
        var missedInWindow = 0

        for i in qualDays.indices {
            if i > 0 {
                let mb = missedBetween(qualDays[i - 1], qualDays[i])
                if mb >= 2 {
                    left = i              // hard break: window cannot span ≥2 consecutive misses
                    missedInWindow = 0
                } else {
                    missedInWindow += mb  // mb is 0 or 1
                }
            }
            // Shrink from the left until the grace budget holds.
            while missedInWindow > (i - left + 1) / config.gracePeriod {
                let mbL = missedBetween(qualDays[left], qualDays[left + 1])
                missedInWindow -= mbL
                left += 1
            }
            let windowQual = i - left + 1
            if windowQual > best { best = windowQual }

            if let ai = anchorIndex, i == ai {
                currentStreak = windowQual
                frozenDays = []
                if left < i {
                    for x in left..<i where missedBetween(qualDays[x], qualDays[x + 1]) == 1 {
                        if let frozen = calendar.date(byAdding: .day, value: 1, to: qualDays[x]) {
                            frozenDays.append(calendar.startOfDay(for: frozen))
                        }
                    }
                }
            }
        }

        let isTodayPending = !todayQualifies && anchorDay == yesterday0 && currentStreak > 0
        return StreakResult(currentStreak: currentStreak,
                            longestStreak: max(best, currentStreak),
                            frozenDays: frozenDays,
                            isTodayPending: isTodayPending)
    }
}
