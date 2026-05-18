import Foundation

/// One calendar day in a report's grid.
public struct DayCell: Equatable, Sendable {
    public let date: Date          // start of day
    public let active: Bool        // ≥1 session
    public let perfect: Bool       // morning + evening
    public init(date: Date, active: Bool, perfect: Bool) {
        self.date = date; self.active = active; self.perfect = perfect
    }
}

/// Deterministic dentist-report data for one profile (Spec 02 §6.7 / AC11). Pure — PDF
/// rendering is an app-layer concern (smoke-only).
public struct ReportData: Equatable, Sendable {
    public let profileID: UUID
    public let profileName: String
    public let start: Date          // start of day, inclusive
    public let end: Date            // start of day, inclusive
    public let totalSessions: Int   // sessions within [start, end]
    public let activeDays: Int
    public let totalDays: Int
    public let completionPercent: Int   // round(activeDays / totalDays * 100), 0 if no days
    public let currentStreak: Int       // overall, as of `now`
    public let longestStreak: Int
    public let days: [DayCell]          // one per calendar day in [start, end]

    public init(profileID: UUID, profileName: String, start: Date, end: Date,
                totalSessions: Int, activeDays: Int, totalDays: Int,
                completionPercent: Int, currentStreak: Int, longestStreak: Int,
                days: [DayCell]) {
        self.profileID = profileID; self.profileName = profileName
        self.start = start; self.end = end
        self.totalSessions = totalSessions; self.activeDays = activeDays
        self.totalDays = totalDays; self.completionPercent = completionPercent
        self.currentStreak = currentStreak; self.longestStreak = longestStreak
        self.days = days
    }
}

public enum ReportBuilder {

    public static func build(profileID: UUID,
                             profileName: String,
                             in allRecords: [BrushingRecord],
                             start: Date,
                             end: Date,
                             now: Date,
                             config: StreakConfig,
                             calendar: Calendar) -> ReportData {
        let records = ProfileScopedAggregator.records(for: profileID, in: allRecords)

        // Normalise the range (tolerate reversed start/end).
        let a = calendar.startOfDay(for: min(start, end))
        let b = calendar.startOfDay(for: max(start, end))

        // Per-day slot presence within range.
        var slotsByDay: [Date: (m: Bool, e: Bool)] = [:]
        var inRangeSessions = 0
        for r in records {
            let d = calendar.startOfDay(for: r.startDate)
            guard d >= a, d <= b else { continue }
            inRangeSessions += 1
            let slot = SessionSlot.slot(for: r.startDate,
                                        boundaryHour: config.slotBoundaryHour,
                                        calendar: calendar)
            var e = slotsByDay[d] ?? (false, false)
            if slot == .morning { e.m = true } else { e.e = true }
            slotsByDay[d] = e
        }

        var days: [DayCell] = []
        var cursor = a
        while cursor <= b {
            let s = slotsByDay[cursor]
            days.append(DayCell(date: cursor,
                                active: s != nil,
                                perfect: (s?.m ?? false) && (s?.e ?? false)))
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? b.addingTimeInterval(86_400)
            if cursor == a { break } // safety against pathological calendars
        }

        let totalDays = days.count
        let activeDays = days.filter(\.active).count
        let pct = totalDays > 0
            ? Int((Double(activeDays) / Double(totalDays) * 100).rounded())
            : 0

        let streak = StreakEngine.evaluate(records: records, now: now,
                                           config: config, calendar: calendar)

        return ReportData(profileID: profileID, profileName: profileName,
                          start: a, end: b,
                          totalSessions: inRangeSessions,
                          activeDays: activeDays, totalDays: totalDays,
                          completionPercent: pct,
                          currentStreak: streak.currentStreak,
                          longestStreak: streak.longestStreak,
                          days: days)
    }
}
