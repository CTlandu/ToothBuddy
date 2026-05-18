import Foundation

/// The pre-P2 on-disk shape (`brushing_records.json`): `{id,startDate,endDate}` with **no
/// profileID**. Decoded ONLY by `MigrationTransform`; the live `BrushingRecord` keeps a
/// non-optional `profileID`. Spec 02 §7.2.
public struct LegacyBrushingRecord: Codable, Equatable, Sendable {
    public var id: UUID
    public var startDate: Date
    public var endDate: Date

    public init(id: UUID, startDate: Date, endDate: Date) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
    }
}

/// Pure, deterministic zero-loss migration of legacy records into profile-scoped records.
/// The "already migrated?" flag is persisted by the app layer; this only does the mapping.
/// Spec 02 §7.2 / AC1.
public enum MigrationTransform {

    /// Decode a legacy `brushing_records.json` payload. Throws on malformed data.
    public static func decodeLegacy(_ data: Data) throws -> [LegacyBrushingRecord] {
        try JSONDecoder().decode([LegacyBrushingRecord].self, from: data)
    }

    /// Assign every legacy record to the default profile, preserving id/start/end and order.
    /// Total count is invariant (no record lost or duplicated).
    public static func migrate(legacy: [LegacyBrushingRecord],
                               defaultProfileID: UUID) -> [BrushingRecord] {
        legacy.map {
            BrushingRecord(id: $0.id,
                           profileID: defaultProfileID,
                           startDate: $0.startDate,
                           endDate: $0.endDate)
        }
    }
}
