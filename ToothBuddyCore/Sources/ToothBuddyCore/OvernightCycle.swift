import Foundation

/// The overnight "morning reveal" loop that gives the two daily sessions distinct roles:
/// the evening brush sends Buddy off; the next day's brush brings him back with a surprise.
public struct OvernightState: Equatable, Sendable {
    /// Buddy is "out overnight" — an evening brush armed a reveal that hasn't been shown yet.
    public let isSentOff: Bool
    /// A morning reveal is ready to show now.
    public let revealAvailable: Bool

    public init(isSentOff: Bool, revealAvailable: Bool) {
        self.isSentOff = isSentOff
        self.revealAvailable = revealAvailable
    }

    public static let idle = OvernightState(isSentOff: false, revealAvailable: false)
}

/// Pure, deterministic overnight-cycle logic. Reveal gates on the same honest signal as the
/// rest of the loop (a *qualifying* `metMinimum` brush), never on app-open (Requirements P1),
/// and on the device `calendar` (so timezone/late-night edges are handled by day boundaries).
///
/// State machine:
///   evening qualifying brush            → sent-off (reveal pending)
///   a qualifying brush on a LATER day   → reveal available (still out until shown)
///   reveal shown (`lastReveal` recorded)→ idle
///
/// Deliberate v1 behavior: after a multi-day gap, the return brush *does* trigger the pending
/// reveal — a "welcome back" moment (Finch pattern), not an expired/stale reveal.
public enum OvernightCycle {

    public static func state(records: [BrushingRecord],
                             lastReveal: Date?,
                             now: Date,
                             calendar: Calendar,
                             config: StreakConfig = .default) -> OvernightState {
        // Distinct days that had a qualifying brush, and those with an evening qualifying brush.
        var qualDays: Set<Date> = []
        var eveningDays: Set<Date> = []
        for r in records where r.metMinimum {
            let day = calendar.startOfDay(for: r.startDate)
            guard day <= calendar.startOfDay(for: now) else { continue }   // ignore future
            qualDays.insert(day)
            if SessionSlot.slot(for: r.startDate, boundaryHour: config.slotBoundaryHour, calendar: calendar) == .evening {
                eveningDays.insert(day)
            }
        }

        guard let latestEvening = eveningDays.max() else { return .idle }   // never sent off

        // Earliest qualifying brush on a day strictly after the send-off day.
        let revealDay = qualDays.filter { $0 > latestEvening }.min()

        guard let rd = revealDay else {
            // Sent off, no new-day brush yet → Buddy is out, waiting.
            return OvernightState(isSentOff: true, revealAvailable: false)
        }

        // Reveal is available unless it has already been shown (consumed on/after that day).
        let consumed = lastReveal.map { calendar.startOfDay(for: $0) >= rd } ?? false
        return OvernightState(isSentOff: !consumed, revealAvailable: !consumed)
    }
}
