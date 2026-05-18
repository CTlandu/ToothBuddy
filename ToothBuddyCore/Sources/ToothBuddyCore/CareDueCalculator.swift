import Foundation

/// Per-profile recurring care (Spec 02 §6.6).
public enum CareKind: String, Codable, CaseIterable, Sendable {
    case brushHead   // default every 90 days
    case dentist     // default every 180 days

    public var defaultIntervalDays: Int {
        switch self {
        case .brushHead: return 90
        case .dentist:   return 180
        }
    }
}

public struct CareStatus: Equatable, Sendable {
    public let isDue: Bool
    /// `anchor + intervalDays` (day-granular); nil when no baseline has been recorded.
    public let dueDate: Date?
    /// Whole days until due; negative = overdue; nil when no baseline.
    public let daysRemaining: Int?

    public init(isDue: Bool, dueDate: Date?, daysRemaining: Int?) {
        self.isDue = isDue; self.dueDate = dueDate; self.daysRemaining = daysRemaining
    }

    public static let noBaseline = CareStatus(isDue: false, dueDate: nil, daysRemaining: nil)
}

/// Pure, deterministic due-date math. Spec 02 §6.6 / AC10. With no `anchor` (the user has
/// never recorded a replacement/visit) nothing is due — we don't nag without a baseline.
public enum CareDueCalculator {

    public static func dueDate(anchor: Date?, intervalDays: Int,
                               calendar: Calendar) -> Date? {
        guard let anchor else { return nil }
        return calendar.date(byAdding: .day, value: intervalDays,
                             to: calendar.startOfDay(for: anchor))
    }

    public static func status(anchor: Date?, intervalDays: Int,
                              now: Date, calendar: Calendar) -> CareStatus {
        guard let due = dueDate(anchor: anchor, intervalDays: intervalDays,
                                calendar: calendar) else { return .noBaseline }
        let today0 = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: today0,
                                           to: calendar.startOfDay(for: due)).day ?? 0
        return CareStatus(isDue: today0 >= calendar.startOfDay(for: due),
                          dueDate: due, daysRemaining: days)
    }
}

// MARK: - Pure reminder planning (the app's scheduler only performs the side effects)

public struct ProfileCareInput: Equatable, Sendable {
    public let profileID: UUID
    public let profileName: String
    public let brushHeadAnchor: Date?
    public let brushHeadIntervalDays: Int
    public let dentistAnchor: Date?
    public let dentistIntervalDays: Int

    public init(profileID: UUID, profileName: String,
                brushHeadAnchor: Date?, brushHeadIntervalDays: Int,
                dentistAnchor: Date?, dentistIntervalDays: Int) {
        self.profileID = profileID; self.profileName = profileName
        self.brushHeadAnchor = brushHeadAnchor
        self.brushHeadIntervalDays = brushHeadIntervalDays
        self.dentistAnchor = dentistAnchor
        self.dentistIntervalDays = dentistIntervalDays
    }
}

public struct PlannedCareReminder: Equatable, Sendable {
    public let profileID: UUID
    public let profileName: String
    public let kind: CareKind
    public let fireDate: Date
}

public enum CareReminderPlanner {
    /// One reminder per profile per kind, fired at the due date — but only if the due date
    /// is still in the future (overdue is surfaced visually on the dashboard, never as a
    /// late nag; consistent with Spec 01 ReminderPlanner edge 9).
    public static func plan(_ inputs: [ProfileCareInput],
                            now: Date, calendar: Calendar) -> [PlannedCareReminder] {
        var out: [PlannedCareReminder] = []
        for i in inputs {
            func add(_ kind: CareKind, _ anchor: Date?, _ interval: Int) {
                guard let due = CareDueCalculator.dueDate(anchor: anchor,
                                                          intervalDays: interval,
                                                          calendar: calendar),
                      due > now else { return }
                out.append(PlannedCareReminder(profileID: i.profileID,
                                               profileName: i.profileName,
                                               kind: kind, fireDate: due))
            }
            add(.brushHead, i.brushHeadAnchor, i.brushHeadIntervalDays)
            add(.dentist, i.dentistAnchor, i.dentistIntervalDays)
        }
        return out.sorted { $0.fireDate < $1.fireDate }
    }
}
