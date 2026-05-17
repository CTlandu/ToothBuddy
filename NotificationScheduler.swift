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
