import Foundation

/// The tiny, Codable summary the app writes to the App Group and the widget reads
/// (Spec 05 §6.4). The widget never touches Core Data — it only renders this.
public struct WidgetSnapshot: Equatable, Sendable, Codable {
    public let profileName: String
    public let currentStreak: Int
    public let amDone: Bool
    public let pmDone: Bool
    /// Evening slot still pending late in the day → a gentle "at risk" cue.
    public let atRisk: Bool
    public let asOf: Date

    public init(profileName: String, currentStreak: Int, amDone: Bool,
                pmDone: Bool, atRisk: Bool, asOf: Date) {
        self.profileName = profileName
        self.currentStreak = currentStreak
        self.amDone = amDone
        self.pmDone = pmDone
        self.atRisk = atRisk
        self.asOf = asOf
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
        return WidgetSnapshot(profileName: profileName,
                              currentStreak: streak.currentStreak,
                              amDone: am, pmDone: pm, atRisk: atRisk, asOf: asOf)
    }
}
