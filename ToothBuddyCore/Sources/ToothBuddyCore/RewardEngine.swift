import Foundation

/// How big a celebration a completed session earns. Proportional to the effort the
/// user can honestly be credited for — duration and goal-completion, never quality.
public enum CelebrationTier: String, Equatable, Sendable {
    case belowMinimum    // did not meet the goal — gentle, no token
    case metMinimum      // met the goal on a short (< 2 min) target
    case fullTwoMinutes  // met the goal at ≥ 2 minutes — the normal "good brush"
    case personalRecord  // a new longest brush vs prior history
}

/// The outcome of scoring one finished session against the retention loop.
public struct RewardOutcome: Equatable, Sendable {
    /// True when the session earns a brush token (the currency the streak / collection
    /// hang on). Minted ONLY on `BrushingRecord.metMinimum` — never on quality/`cameraVerified`.
    public let mintsToken: Bool
    public let tier: CelebrationTier

    public init(mintsToken: Bool, tier: CelebrationTier) {
        self.mintsToken = mintsToken
        self.tier = tier
    }
}

/// Decides whether a completed session earns a brush token and how big its celebration is.
///
/// The single honest gate (Requirements P1): a token mints only when the session met its
/// goal (`metMinimum` — every zone reached its per-zone target AND active time ≥ target).
/// It deliberately ignores `cameraVerified` and any notion of brushing "quality", which the
/// product cannot measure. Pure & deterministic — the TDD target.
public enum RewardEngine {

    public static func evaluate(record: BrushingRecord,
                                priorRecords: [BrushingRecord]) -> RewardOutcome {
        guard record.metMinimum else {
            return RewardOutcome(mintsToken: false, tier: .belowMinimum)
        }
        // A personal record needs prior history to beat — the first good brush is not a "record".
        let priorBest = priorRecords.map(\.durationSeconds).max()
        if let best = priorBest, record.durationSeconds > best {
            return RewardOutcome(mintsToken: true, tier: .personalRecord)
        }
        if record.durationSeconds >= 120 {
            return RewardOutcome(mintsToken: true, tier: .fullTwoMinutes)
        }
        return RewardOutcome(mintsToken: true, tier: .metMinimum)
    }
}
