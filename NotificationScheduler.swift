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
                    content.title = String(localized: "Time for a new brush head 🪥")
                    let name = r.profileName
                    content.body = String(localized: "\(name)'s toothbrush head is due for a swap.")
                case .dentist:
                    content.title = String(localized: "Dentist check-up due 🦷")
                    let name = r.profileName
                    content.body = String(localized: "It's time to book \(name)'s dental visit.")
                }
                content.sound = .default
                let id = "\(Self.carePrefix)\(r.kind.rawValue).\(r.profileID.uuidString)"
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
                try? await center.add(UNNotificationRequest(identifier: id,
                                                            content: content, trigger: trigger))
            }
        }
    }

    // Plan U8: notification title + body run through String(localized:) so the
    // system delivers the user's preferred language.
    // U12 (retention): copy is in Buddy's voice, gentle and never shaming (P4). The morning
    // routine doubles as the overnight-reveal teaser ("come see what Buddy found").
    private static func title(for kind: ReminderKind) -> String {
        switch kind {
        case .morningRoutine: return String(localized: "Buddy's back! 🦷")
        case .eveningRoutine: return String(localized: "Buddy's getting sleepy 🌙")
        case .streakAtRisk:   return String(localized: "Buddy misses you")
        }
    }

    private static func body(for kind: ReminderKind, streak: StreakResult) -> String {
        switch kind {
        case .morningRoutine:
            return String(localized: "Buddy came home overnight — brush to see what he found!")
        case .eveningRoutine:
            return String(localized: "A quick brush tucks Buddy in for the night.")
        case .streakAtRisk:
            let n = streak.currentStreak
            return String(localized: "Brush today so Buddy can keep your \(n)-day streak safe.")
        }
    }
}
