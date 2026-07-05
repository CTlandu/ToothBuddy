import Foundation

/// The overnight loop that gives the two daily sessions distinct roles: the evening brush
/// sends Buddy off; the next morning he's back to *greet* you — the hook that pulls you to
/// brush. The tangible reward (a collectible) is earned by the brush itself (in the done
/// sheet), so the morning greeting is emotional only and doesn't violate P1 ("reward gates
/// on the ritual, never on app-open"): a greeting is not a reward.
public struct OvernightState: Equatable, Sendable {
    /// Buddy is "out overnight" — an evening brush happened and the morning greeting is pending.
    public let isSentOff: Bool
    /// The morning "Buddy's back!" greeting is ready to show now (on app-open, before brushing).
    public let revealAvailable: Bool

    public init(isSentOff: Bool, revealAvailable: Bool) {
        self.isSentOff = isSentOff
        self.revealAvailable = revealAvailable
    }

    public static let idle = OvernightState(isSentOff: false, revealAvailable: false)
}

/// Pure, deterministic overnight-cycle logic, on the device `calendar` (so timezone/late-night
/// edges are handled by day boundaries).
///
/// State machine:
///   evening qualifying brush                → sent-off (Buddy out for the night)
///   a LATER calendar day arrives, unshown   → greeting available (shows on app-open)
///   greeting shown (`lastReveal` recorded)  → idle until the next evening send-off
///
/// The greeting does NOT require a morning brush first — it's the pull *to* brush. After a
/// multi-day gap it still fires (a "welcome back" moment, Finch pattern), not stale/expired.
public enum OvernightCycle {

    public static func state(records: [BrushingRecord],
                             lastReveal: Date?,
                             now: Date,
                             calendar: Calendar,
                             config: StreakConfig = .default) -> OvernightState {
        // Latest day with an evening qualifying brush = the last send-off.
        var latestEvening: Date?
        for r in records where r.metMinimum {
            let day = calendar.startOfDay(for: r.startDate)
            guard day <= calendar.startOfDay(for: now) else { continue }   // ignore future
            guard SessionSlot.slot(for: r.startDate, boundaryHour: config.slotBoundaryHour,
                                   calendar: calendar) == .evening else { continue }
            if latestEvening == nil || day > latestEvening! { latestEvening = day }
        }

        guard let sendOff = latestEvening else { return .idle }   // never sent off

        let today0 = calendar.startOfDay(for: now)
        guard today0 > sendOff else {
            // Still the same day as the evening brush — Buddy is out for tonight.
            return OvernightState(isSentOff: true, revealAvailable: false)
        }

        // A new day has arrived: greet on app-open unless already greeted today.
        let greetedToday = lastReveal.map { calendar.startOfDay(for: $0) >= today0 } ?? false
        return OvernightState(isSentOff: !greetedToday, revealAvailable: !greetedToday)
    }
}
