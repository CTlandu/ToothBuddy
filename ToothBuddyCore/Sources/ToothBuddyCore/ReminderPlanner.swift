import Foundation

public struct TimeOfDay: Equatable, Sendable {
    public var hour: Int
    public var minute: Int
    public init(hour: Int, minute: Int) { self.hour = hour; self.minute = minute }
    var totalMinutes: Int { hour * 60 + minute }
}

/// Reminder configuration. Spec 01 §4.5–§4.7, OPEN-4 (confirmed defaults).
public struct ReminderConfig: Equatable, Sendable {
    public var slotBoundaryHour: Int
    public var defaultMorning: TimeOfDay
    public var defaultEvening: TimeOfDay
    public var streakRisk: TimeOfDay
    public var minGapMinutes: Int
    public var adaptWindow: Int
    public var minHistory: Int

    public init(slotBoundaryHour: Int = 12,
                defaultMorning: TimeOfDay = TimeOfDay(hour: 8, minute: 0),
                defaultEvening: TimeOfDay = TimeOfDay(hour: 20, minute: 30),
                streakRisk: TimeOfDay = TimeOfDay(hour: 20, minute: 30),
                minGapMinutes: Int = 60,
                adaptWindow: Int = 14,
                minHistory: Int = 3) {
        self.slotBoundaryHour = slotBoundaryHour
        self.defaultMorning = defaultMorning
        self.defaultEvening = defaultEvening
        self.streakRisk = streakRisk
        self.minGapMinutes = minGapMinutes
        self.adaptWindow = adaptWindow
        self.minHistory = minHistory
    }

    public static let `default` = ReminderConfig()
}

public enum ReminderKind: String, Sendable {
    case morningRoutine, eveningRoutine, streakAtRisk
}

public struct PlannedReminder: Equatable, Sendable {
    public let kind: ReminderKind
    public let fireDate: Date
    public init(kind: ReminderKind, fireDate: Date) { self.kind = kind; self.fireDate = fireDate }
}

public struct ReminderPlanInput: Sendable {
    public let records: [BrushingRecord]
    public let now: Date
    public let streak: StreakResult
    public let config: ReminderConfig
    public init(records: [BrushingRecord], now: Date, streak: StreakResult, config: ReminderConfig) {
        self.records = records; self.now = now; self.streak = streak; self.config = config
    }
}

/// Pure, deterministic notification planning. The TDD target; the app's
/// `NotificationScheduler` only consumes this output. Spec 01 §4.5–§4.6.
public enum ReminderPlanner {

    public static func plan(_ input: ReminderPlanInput, calendar: Calendar) -> [PlannedReminder] {
        let cfg = input.config
        let now = input.now
        let today0 = calendar.startOfDay(for: now)

        let todays = input.records.filter { calendar.startOfDay(for: $0.startDate) == today0 }
        func slot(_ r: BrushingRecord) -> SessionSlot {
            SessionSlot.slot(for: r.startDate, boundaryHour: cfg.slotBoundaryHour, calendar: calendar)
        }
        let morningLogged = todays.contains { slot($0) == .morning }
        let eveningLogged = todays.contains { slot($0) == .evening }
        let anySessionToday = !todays.isEmpty

        func fireDate(_ tod: TimeOfDay) -> Date? {
            var dc = calendar.dateComponents([.year, .month, .day], from: today0)
            dc.hour = tod.hour
            dc.minute = tod.minute
            dc.second = 0
            return calendar.date(from: dc)
        }

        // Adaptive time: median time-of-day of the last `adaptWindow` sessions in the slot,
        // or the default when there is too little history.
        func adaptiveTime(for target: SessionSlot, default def: TimeOfDay) -> TimeOfDay {
            let slotRecs = input.records
                .filter { slot($0) == target }
                .sorted { $0.startDate > $1.startDate }
                .prefix(cfg.adaptWindow)
            guard slotRecs.count >= cfg.minHistory else { return def }
            let mins = slotRecs.map { r -> Int in
                let c = calendar.dateComponents([.hour, .minute], from: r.startDate)
                return (c.hour ?? 0) * 60 + (c.minute ?? 0)
            }.sorted()
            let n = mins.count
            let median = n % 2 == 1 ? mins[n / 2] : (mins[n / 2 - 1] + mins[n / 2]) / 2
            return TimeOfDay(hour: median / 60, minute: median % 60)
        }

        var out: [PlannedReminder] = []

        if !morningLogged,
           let f = fireDate(adaptiveTime(for: .morning, default: cfg.defaultMorning)), f > now {
            out.append(PlannedReminder(kind: .morningRoutine, fireDate: f))
        }
        if !eveningLogged,
           let f = fireDate(adaptiveTime(for: .evening, default: cfg.defaultEvening)), f > now {
            out.append(PlannedReminder(kind: .eveningRoutine, fireDate: f))
        }
        if !anySessionToday, input.streak.currentStreak > 0,
           let f = fireDate(cfg.streakRisk), f > now {
            out.append(PlannedReminder(kind: .streakAtRisk, fireDate: f))
        }

        // Collision: keep the streak nudge, drop the evening routine when too close.
        if let evening = out.first(where: { $0.kind == .eveningRoutine }),
           let risk = out.first(where: { $0.kind == .streakAtRisk }),
           abs(evening.fireDate.timeIntervalSince(risk.fireDate)) < Double(cfg.minGapMinutes) * 60 {
            out.removeAll { $0.kind == .eveningRoutine }
        }

        return out.sorted { $0.fireDate < $1.fireDate }
    }
}
