import Foundation

/// One day on the adult "habit curve" (Spec 05 §6.2). `completed01` is the day's raw
/// completion (0 = no session, 0.5 = one slot, 1.0 = both slots); `adherence` is the
/// smoothed rolling mean used for the calm trend line.
public struct HabitCurvePoint: Equatable, Sendable {
    public let date: Date
    public let completed01: Double
    public let adherence: Double

    public init(date: Date, completed01: Double, adherence: Double) {
        self.date = date
        self.completed01 = completed01
        self.adherence = adherence
    }
}

/// Pure, deterministic adult consistency curve (Spec 05 §6.2 / AC2–AC3). Profile-isolated
/// (reuses `ProfileScopedAggregator`); no storage; the adult UI renders it, the kid UI
/// never shows it. Uses the project-wide DECIDED slot boundary (12, see `SessionSlot`).
public enum HabitCurve {

    /// Smoothing window for `adherence` (days). Partial at the series start by design.
    public static let smoothingWindow = 7

    /// `days` points, oldest→newest, ending on `asOf`'s day. Empty if `days <= 0`.
    public static func points(records: [BrushingRecord],
                              profileID: UUID,
                              asOf: Date,
                              days: Int,
                              calendar: Calendar) -> [HabitCurvePoint] {
        guard days > 0 else { return [] }
        let scoped = ProfileScopedAggregator.records(for: profileID, in: records)
        let today0 = calendar.startOfDay(for: asOf)

        // Slots present per day (only days in our window matter).
        var morning: Set<Date> = []
        var evening: Set<Date> = []
        for r in scoped {
            let d = calendar.startOfDay(for: r.startDate)
            switch SessionSlot.slot(for: r.startDate, boundaryHour: 12, calendar: calendar) {
            case .morning: morning.insert(d)
            case .evening: evening.insert(d)
            }
        }

        // Raw completion oldest→newest.
        var raw: [(date: Date, value: Double)] = []
        for offset in stride(from: -(days - 1), through: 0, by: 1) {
            let day = calendar.date(byAdding: .day, value: offset, to: today0) ?? today0
            let v = (morning.contains(day) ? 0.5 : 0) + (evening.contains(day) ? 0.5 : 0)
            raw.append((day, v))
        }

        // Smoothed adherence: clamped trailing mean over `smoothingWindow` (partial at start).
        return raw.enumerated().map { i, point in
            let lo = max(0, i - smoothingWindow + 1)
            let window = raw[lo...i]
            let mean = window.reduce(0.0) { $0 + $1.value } / Double(window.count)
            return HabitCurvePoint(date: point.date,
                                   completed01: point.value,
                                   adherence: min(1.0, max(0.0, mean)))
        }
    }
}
