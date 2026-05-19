import Foundation

#if canImport(ActivityKit)
import ActivityKit

/// App-side Live Activity lifecycle (Spec 05 §6.5). Additive & crash-safe: every call is
/// availability-gated and a no-op if Live Activities are unsupported or disabled, so
/// brushing is unchanged. The countdown uses the same 2-minute model the app already
/// drives; the widget extension only renders it.
@MainActor
enum BrushingLiveActivity {
    private static var current: Any?

    static func start(profileName: String, totalSeconds: Int) {
        guard #available(iOS 16.1, *) else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        end()   // never stack activities
        let attrs = BrushingActivityAttributes(profileName: profileName)
        let state = BrushingActivityAttributes.ContentState(
            secondsRemaining: totalSeconds, zoneHint: "Let's brush!")
        do {
            current = try Activity.request(attributes: attrs,
                                           contentState: state,
                                           pushType: nil)
        } catch {
            current = nil   // permission/limit — silently skip, app unaffected
        }
    }

    static func update(secondsRemaining: Int, zoneHint: String) {
        guard #available(iOS 16.1, *),
              let activity = current as? Activity<BrushingActivityAttributes> else { return }
        Task {
            await activity.update(using: .init(
                secondsRemaining: max(0, secondsRemaining), zoneHint: zoneHint))
        }
    }

    static func end() {
        guard #available(iOS 16.1, *),
              let activity = current as? Activity<BrushingActivityAttributes> else {
            current = nil
            return
        }
        current = nil
        Task { await activity.end(dismissalPolicy: .immediate) }
    }

    /// Spec 05 §6.5 — if the app was killed mid-session a Live Activity can linger;
    /// dismiss any on launch so there is never a stuck timer.
    static func endStaleOnLaunch() {
        guard #available(iOS 16.1, *) else { return }
        for activity in Activity<BrushingActivityAttributes>.activities {
            Task { await activity.end(dismissalPolicy: .immediate) }
        }
        current = nil
    }
}
#else
@MainActor
enum BrushingLiveActivity {
    static func start(profileName: String, totalSeconds: Int) {}
    static func update(secondsRemaining: Int, zoneHint: String) {}
    static func end() {}
}
#endif
