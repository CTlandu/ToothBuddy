import Foundation

/// A single brushing session: start time and end time.
/// Pure value type — lives in ToothBuddyCore so it is unit-testable from the CLI.
public struct BrushingRecord: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    /// Owning profile (Spec 02). Non-optional — legacy records without it are decoded via
    /// `LegacyBrushingRecord` and assigned a profile by `MigrationTransform`.
    public var profileID: UUID
    public var startDate: Date
    public var endDate: Date

    /// Duration in whole seconds. Clamped at 0 (never negative, even if endDate < startDate).
    public var durationSeconds: Int {
        max(0, Int(endDate.timeIntervalSince(startDate)))
    }

    /// Stars 1–3 from duration: ≥2 min → 3, ≥1 min → 2, >0 → 1, else 0.
    public var starCount: Int {
        if durationSeconds >= 120 { return 3 }
        if durationSeconds >= 60 { return 2 }
        if durationSeconds > 0 { return 1 }
        return 0
    }

    public init(id: UUID = UUID(), profileID: UUID, startDate: Date, endDate: Date) {
        self.id = id
        self.profileID = profileID
        self.startDate = startDate
        self.endDate = endDate
    }
}
