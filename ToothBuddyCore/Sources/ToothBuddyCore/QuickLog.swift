import Foundation

/// Outcome of a one-tap / Siri "log brushing" request (Spec 05 §6.3).
public enum QuickLogDecision: Equatable, Sendable {
    case logged
    case alreadyLoggedThisSlot
    case noProfile
}

/// Pure idempotency rule for the App-Intents quick-log path (Spec 05 §6.3 / AC7).
/// The in-app brushing flow is unaffected — only the intent uses this so a second
/// "I brushed my teeth" in the same morning/evening slot can't double-log or inflate
/// the streak. Uses the project-wide DECIDED slot boundary (12, see `SessionSlot`).
public enum QuickLog {

    /// True if `profileID` already has a record today in the same slot as `now`.
    public static func isCurrentSlotLogged(records: [BrushingRecord],
                                           profileID: UUID,
                                           now: Date,
                                           calendar: Calendar) -> Bool {
        let today0 = calendar.startOfDay(for: now)
        let slotNow = SessionSlot.slot(for: now, boundaryHour: 12, calendar: calendar)
        for r in records where r.profileID == profileID
            && calendar.startOfDay(for: r.startDate) == today0 {
            if SessionSlot.slot(for: r.startDate, boundaryHour: 12,
                                calendar: calendar) == slotNow {
                return true
            }
        }
        return false
    }
}
