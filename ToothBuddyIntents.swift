import AppIntents
import ToothBuddyCore

/// Spec 05 §6.2 — Siri / Shortcuts entry points. All operate on the **active profile**
/// only, never silently switch profiles, and degrade gracefully when none exists.
/// No entitlement, no extension target (App Intents are in-process, iOS 16+).

/// "I brushed my teeth" — logs a session for the active profile. Idempotent per slot
/// (Spec 05 §6.3 / AC7): a second call in the same AM/PM slot says "already logged".
struct LogBrushingIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Brushing"
    static let description = IntentDescription("Log a tooth-brushing session.")
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        switch BrushingStore.shared.quickLogForCurrentSlot() {
        case .noProfile:
            return .result(dialog: "Open ToothBuddy and pick a profile first.")
        case .alreadyLoggedThisSlot:
            return .result(dialog: "You already logged this one — nice work.")
        case .logged:
            let s = BrushingStore.shared.consecutiveDaysCount
            return .result(dialog: s > 0
                ? "Brushing logged. Your streak is \(s) day\(s == 1 ? "" : "s")."
                : "Brushing logged. Keep it up!")
        }
    }
}

/// "Start brushing" — opens the app to the Brush tab and begins a session.
struct StartBrushingIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Brushing"
    static let description = IntentDescription("Open ToothBuddy and start a 2-minute brush.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard ProfileStore.shared.activeProfileID != nil else {
            return .result(dialog: "Open ToothBuddy and pick a profile first.")
        }
        BrushingIntentBridge.shared.requestStart()
        return .result(dialog: "Let's brush!")
    }
}

/// "What's my brushing streak" — read-only current streak for the active profile.
struct BrushingStreakIntent: AppIntent {
    static let title: LocalizedStringResource = "Brushing Streak"
    static let description = IntentDescription("Hear your current brushing streak.")
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard ProfileStore.shared.activeProfileID != nil else {
            return .result(dialog: "Open ToothBuddy and pick a profile first.")
        }
        BrushingStore.shared.reload()
        let s = BrushingStore.shared.consecutiveDaysCount
        return .result(dialog: s == 0
            ? "No streak yet — brush today to start one!"
            : "Your brushing streak is \(s) day\(s == 1 ? "" : "s"). Keep going!")
    }
}

/// Surfaces the phrases to Siri & the Shortcuts app (Spec 05 §6.3).
struct ToothBuddyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: LogBrushingIntent(),
                    phrases: ["I brushed my teeth in \(.applicationName)",
                              "Log brushing in \(.applicationName)"],
                    shortTitle: "Log Brushing",
                    systemImageName: "checkmark.circle.fill")
        AppShortcut(intent: StartBrushingIntent(),
                    phrases: ["Start brushing in \(.applicationName)",
                              "Start a brush in \(.applicationName)"],
                    shortTitle: "Start Brushing",
                    systemImageName: "play.circle.fill")
        AppShortcut(intent: BrushingStreakIntent(),
                    phrases: ["What's my brushing streak in \(.applicationName)",
                              "Brushing streak in \(.applicationName)"],
                    shortTitle: "Brushing Streak",
                    systemImageName: "flame.fill")
    }
}
