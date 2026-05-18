import Foundation

/// Per-profile views over a flat record list. Profiles are isolated by `profileID`
/// (Spec 02 §6.3 / AC2–AC3): filter first, then reuse the unchanged Spec 01 engines.
public enum ProfileScopedAggregator {

    public static func records(for profileID: UUID,
                               in all: [BrushingRecord]) -> [BrushingRecord] {
        all.filter { $0.profileID == profileID }
    }

    public static func streak(for profileID: UUID,
                              in all: [BrushingRecord],
                              now: Date,
                              config: StreakConfig,
                              calendar: Calendar) -> StreakResult {
        StreakEngine.evaluate(records: records(for: profileID, in: all),
                              now: now, config: config, calendar: calendar)
    }
}
