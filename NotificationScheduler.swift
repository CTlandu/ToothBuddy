import Foundation
import UserNotifications
import ToothBuddyCore

/// App-layer wrapper around UNUserNotificationCenter. All scheduling *math* lives in
/// the pure, unit-tested `ReminderPlanner`; this only performs the system side effects.
/// Spec 01 §4.5–§4.7.
@MainActor
final class NotificationScheduler {
    static let shared = NotificationScheduler()
    private init() {}

    private let center = UNUserNotificationCenter.current()
    private static let ids: [ReminderKind: String] = [
        .morningRoutine: "tb.reminder.morningRoutine",
        .eveningRoutine: "tb.reminder.eveningRoutine",
        .streakAtRisk:   "tb.reminder.streakAtRisk"
    ]

    /// Request permission once, contextually (after the first completed session).
    /// No-ops if the user has already decided. Never re-prompts programmatically.
    func requestAuthorizationIfNeeded() {
        Task {
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .notDetermined else { return }
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }
    }

    /// Clear and re-create today's reminders from the pure planner. Safe to call often
    /// (on scenePhase active and after every logged session).
    func reschedule(records: [BrushingRecord], streak: StreakResult) {
        Task {
            center.removePendingNotificationRequests(withIdentifiers: Array(Self.ids.values))
            let settings = await center.notificationSettings()
            let status = settings.authorizationStatus
            guard status == .authorized || status == .provisional else { return }

            let plan = ReminderPlanner.plan(
                ReminderPlanInput(records: records, now: Date(), streak: streak, config: .default),
                calendar: .current)

            for reminder in plan {
                guard let id = Self.ids[reminder.kind] else { continue }
                let interval = reminder.fireDate.timeIntervalSinceNow
                guard interval > 0 else { continue }   // never fire immediately (Spec edge 9)

                let content = UNMutableNotificationContent()
                content.title = Self.title(for: reminder.kind)
                content.body = Self.body(for: reminder.kind, streak: streak)
                content.sound = .default

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                try? await center.add(request)
            }
        }
    }

    private static let carePrefix = "tb.care."

    /// Per-profile brush-head / dentist reminders (Spec 02 §6.6). Overdue items are NOT
    /// re-nagged here (the planner only emits future due dates); the dashboard shows them.
    func rescheduleCare(inputs: [ProfileCareInput]) {
        Task {
            let pending = await center.pendingNotificationRequests()
            let stale = pending.map(\.identifier).filter { $0.hasPrefix(Self.carePrefix) }
            center.removePendingNotificationRequests(withIdentifiers: stale)

            let settings = await center.notificationSettings()
            let status = settings.authorizationStatus
            guard status == .authorized || status == .provisional else { return }

            let plan = CareReminderPlanner.plan(inputs, now: Date(), calendar: .current)
            for r in plan {
                let interval = r.fireDate.timeIntervalSinceNow
                guard interval > 0 else { continue }
                let content = UNMutableNotificationContent()
                switch r.kind {
                case .brushHead:
                    content.title = "Time for a new brush head 🪥"
                    content.body = "\(r.profileName)'s toothbrush head is due for a swap."
                case .dentist:
                    content.title = "Dentist check-up due 🦷"
                    content.body = "It's time to book \(r.profileName)'s dental visit."
                }
                content.sound = .default
                let id = "\(Self.carePrefix)\(r.kind.rawValue).\(r.profileID.uuidString)"
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
                try? await center.add(UNNotificationRequest(identifier: id,
                                                            content: content, trigger: trigger))
            }
        }
    }

    private static func title(for kind: ReminderKind) -> String {
        switch kind {
        case .morningRoutine: return "Good morning! ☀️"
        case .eveningRoutine: return "Evening brush 🌙"
        case .streakAtRisk:   return "Keep your streak alive!"
        }
    }

    private static func body(for kind: ReminderKind, streak: StreakResult) -> String {
        switch kind {
        case .morningRoutine:
            return "Time for a 2-minute brush to start the day."
        case .eveningRoutine:
            return "A quick brush before bed keeps your streak going."
        case .streakAtRisk:
            return "You haven't brushed today — brush now to protect your \(streak.currentStreak)-day streak."
        }
    }
}
