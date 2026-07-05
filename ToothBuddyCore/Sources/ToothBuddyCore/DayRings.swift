import Foundation

/// Today's two brushing rings (morning / evening), the home surface's hero.
public struct DayRingState: Equatable, Sendable {
    public let amClosed: Bool
    public let pmClosed: Bool
    /// Both rings closed — the "perfect day".
    public var isPerfectDay: Bool { amClosed && pmClosed }

    public init(amClosed: Bool, pmClosed: Bool) {
        self.amClosed = amClosed
        self.pmClosed = pmClosed
    }
}

/// Rolling 7-day, 14-slot completion (2 rings × 7 days).
public struct WeekProgress: Equatable, Sendable {
    public let closed: Int
    public let total: Int

    public init(closed: Int, total: Int) {
        self.closed = closed
        self.total = total
    }
}

/// The two-ring/day model for the home screen. Pure & deterministic.
///
/// A slot ring closes when a *qualifying* session (one that mints a token — i.e.
/// `metMinimum`, the same honest gate as `RewardEngine`) lands in that slot. Below-goal
/// brushes don't close a ring; quality / `cameraVerified` never matter (Requirements P1).
public enum DayRings {

    public static func today(records: [BrushingRecord],
                             now: Date,
                             calendar: Calendar,
                             config: StreakConfig = .default) -> DayRingState {
        let today0 = calendar.startOfDay(for: now)
        var am = false, pm = false
        for r in records where r.metMinimum {
            guard calendar.startOfDay(for: r.startDate) == today0 else { continue }
            switch SessionSlot.slot(for: r.startDate, boundaryHour: config.slotBoundaryHour, calendar: calendar) {
            case .morning: am = true
            case .evening: pm = true
            }
        }
        return DayRingState(amClosed: am, pmClosed: pm)
    }

    public static func weekProgress(records: [BrushingRecord],
                                    now: Date,
                                    calendar: Calendar,
                                    config: StreakConfig = .default) -> WeekProgress {
        let today0 = calendar.startOfDay(for: now)
        let total = 14
        guard let weekStart = calendar.date(byAdding: .day, value: -6, to: today0) else {
            return WeekProgress(closed: 0, total: total)
        }
        // Distinct (day, slot) pairs closed within the trailing 7 days.
        var closed: Set<DaySlot> = []
        for r in records where r.metMinimum {
            let day = calendar.startOfDay(for: r.startDate)
            guard day >= weekStart, day <= today0 else { continue }
            let slot = SessionSlot.slot(for: r.startDate, boundaryHour: config.slotBoundaryHour, calendar: calendar)
            closed.insert(DaySlot(day: day, slot: slot))
        }
        return WeekProgress(closed: closed.count, total: total)
    }

    private struct DaySlot: Hashable {
        let day: Date
        let slot: SessionSlot
    }
}
