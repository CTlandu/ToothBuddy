import Foundation

/// The tiny, Codable summary the app writes to the App Group and the widget reads
/// (Spec 05 §6.4). The widget never touches Core Data — it only renders this.
///
/// U12 — quality is the hero (today's thorough count + last session's coverage/verification);
/// streak is demoted to a small badge.
public struct WidgetSnapshot: Equatable, Sendable, Codable {
    public let profileName: String
    public let currentStreak: Int
    public let amDone: Bool
    public let pmDone: Bool
    /// Evening slot still pending late in the day → a gentle "at risk" cue.
    public let atRisk: Bool
    /// Sessions today that met the minimum (every area + full time).
    public let todayThoroughCount: Int
    /// Areas covered in the most recent session (0…6); 0 when there is none.
    public let lastZonesMet: Int
    /// Whether the most recent session was camera-verified.
    public let lastVerified: Bool
    public let asOf: Date

    public init(profileName: String, currentStreak: Int, amDone: Bool, pmDone: Bool,
                atRisk: Bool, todayThoroughCount: Int = 0, lastZonesMet: Int = 0,
                lastVerified: Bool = false, asOf: Date) {
        self.profileName = profileName
        self.currentStreak = currentStreak
        self.amDone = amDone
        self.pmDone = pmDone
        self.atRisk = atRisk
        self.todayThoroughCount = todayThoroughCount
        self.lastZonesMet = lastZonesMet
        self.lastVerified = lastVerified
        self.asOf = asOf
    }

    private enum CodingKeys: String, CodingKey {
        case profileName, currentStreak, amDone, pmDone, atRisk
        case todayThoroughCount, lastZonesMet, lastVerified, asOf
    }

    // Backward-compatible: a snapshot written by a pre-U12 build (no quality keys) still
    // decodes, so the widget doesn't fall back to the placeholder right after an upgrade.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        profileName = try c.decode(String.self, forKey: .profileName)
        currentStreak = try c.decode(Int.self, forKey: .currentStreak)
        amDone = try c.decode(Bool.self, forKey: .amDone)
        pmDone = try c.decode(Bool.self, forKey: .pmDone)
        atRisk = try c.decode(Bool.self, forKey: .atRisk)
        todayThoroughCount = try c.decodeIfPresent(Int.self, forKey: .todayThoroughCount) ?? 0
        lastZonesMet = try c.decodeIfPresent(Int.self, forKey: .lastZonesMet) ?? 0
        lastVerified = try c.decodeIfPresent(Bool.self, forKey: .lastVerified) ?? false
        asOf = try c.decode(Date.self, forKey: .asOf)
    }

    /// Friendly placeholder when there is no data yet (Spec 05 §6.4 — never blank).
    public static let placeholder = WidgetSnapshot(
        profileName: "ToothBuddy", currentStreak: 0,
        amDone: false, pmDone: false, atRisk: false, asOf: .distantPast)
}

/// Pure, deterministic snapshot builder (Spec 05 §6.4 / AC4). Profile-isolated; reuses
/// `StreakEngine` so the widget streak always matches the app. Project slot boundary 12.
public enum WidgetSnapshotBuilder {

    /// Hour (local) at/after which an unfinished evening slot counts as "at risk".
    public static let atRiskHour = 20

    public static func build(records: [BrushingRecord],
                             profileID: UUID,
                             profileName: String,
                             asOf: Date,
                             calendar: Calendar) -> WidgetSnapshot {
        let scoped = ProfileScopedAggregator.records(for: profileID, in: records)
        let streak = StreakEngine.evaluate(records: scoped, now: asOf,
                                           config: .default, calendar: calendar)
        let today0 = calendar.startOfDay(for: asOf)
        var am = false, pm = false
        for r in scoped where calendar.startOfDay(for: r.startDate) == today0 {
            switch SessionSlot.slot(for: r.startDate, boundaryHour: 12, calendar: calendar) {
            case .morning: am = true
            case .evening: pm = true
            }
        }
        let hour = calendar.component(.hour, from: asOf)
        let atRisk = !pm && hour >= atRiskHour

        // U12 — quality signals.
        let todayThorough = scoped.filter {
            calendar.startOfDay(for: $0.startDate) == today0 && $0.metMinimum
        }.count
        let last = scoped.max { $0.startDate < $1.startDate }
        let perZone = (last?.targetSeconds ?? 120) / CoarseZone.allCases.count
        let lastZonesMet = last.map { r in
            CoarseZone.allCases.filter { (r.coverage[$0] ?? 0) >= perZone }.count
        } ?? 0
        let lastVerified = last?.cameraVerified ?? false

        return WidgetSnapshot(profileName: profileName,
                              currentStreak: streak.currentStreak,
                              amDone: am, pmDone: pm, atRisk: atRisk,
                              todayThoroughCount: todayThorough,
                              lastZonesMet: lastZonesMet,
                              lastVerified: lastVerified,
                              asOf: asOf)
    }
}
