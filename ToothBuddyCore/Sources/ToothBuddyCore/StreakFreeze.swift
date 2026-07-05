import Foundation

/// The explicit "sick-day" freeze economy layered over `StreakEngine`.
///
/// `StreakEngine` already bridges single missed days via rolling grace and reports them as
/// `frozenDays`. This makes that implicit forgiveness an **explicit, earned, capped resource**
/// the UI can show ("🛡 Buddy held your spot"), without changing the underlying streak math
/// (so the existing StreakEngine tests stay green). Pure & deterministic.
///
/// Re-promotes the streak to a hero metric — intentionally reverses the U11 demotion to a
/// light badge (see plan KTD3).
public struct FreezeState: Equatable, Sendable {
    /// Freezes available in hand (0…cap).
    public let balance: Int
    /// Lifetime freezes earned (one per `earnEveryDays` of longest streak reached).
    public let earnedTotal: Int
    /// Missed days in the current streak that a freeze bridged.
    public let savedDays: [Date]

    public init(balance: Int, earnedTotal: Int, savedDays: [Date]) {
        self.balance = balance
        self.earnedTotal = earnedTotal
        self.savedDays = savedDays
    }

    public static let empty = FreezeState(balance: 0, earnedTotal: 0, savedDays: [])
}

public enum StreakFreeze {

    /// Derive the freeze economy from history. One freeze is earned per `earnEveryDays` of the
    /// longest streak reached (a milestone reward); freezes spent = missed days the current
    /// streak bridged (`StreakEngine.frozenDays`); `balance` is what's left, capped at `cap`.
    public static func evaluate(records: [BrushingRecord],
                                now: Date,
                                config: StreakConfig,
                                calendar: Calendar,
                                earnEveryDays: Int = 7,
                                cap: Int = 2) -> FreezeState {
        let streak = StreakEngine.evaluate(records: records, now: now, config: config, calendar: calendar)
        let earnedTotal = max(0, streak.longestStreak / max(1, earnEveryDays))
        let spent = streak.frozenDays.count
        let balance = max(0, min(cap, earnedTotal - spent))
        return FreezeState(balance: balance, earnedTotal: earnedTotal, savedDays: streak.frozenDays)
    }
}
