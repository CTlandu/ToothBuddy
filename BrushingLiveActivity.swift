import Foundation

#if canImport(ActivityKit)
import ActivityKit

/// App-side Live Activity lifecycle (Spec 05 §6.5). Additive & crash-safe: every call
/// no-ops if Live Activities are disabled, so brushing is unchanged. The countdown uses
/// the same 2-minute model the app already drives; the widget extension only renders it.
/// (iOS 16.1 availability guards removed at deployment-target bump to 17.0, Plan U5.)
@MainActor
enum BrushingLiveActivity {
    private static var current: Activity<BrushingActivityAttributes>?

    static func start(profileName: String, totalSeconds: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        end()   // never stack activities
        let attrs = BrushingActivityAttributes(profileName: profileName)
        let state = BrushingActivityAttributes.ContentState(
            secondsRemaining: totalSeconds, zoneHint: "Let's brush!")
        let content = ActivityContent(state: state, staleDate: nil)
        do {
            current = try Activity.request(attributes: attrs,
                                           content: content,
                                           pushType: nil)
        } catch {
            current = nil   // permission/limit — silently skip, app unaffected
        }
    }

    static func update(secondsRemaining: Int, zoneHint: String,
                       zonesCompleted: Int, totalZones: Int) {
        guard let activity = current else { return }
        let state = BrushingActivityAttributes.ContentState(
            secondsRemaining: max(0, secondsRemaining), zoneHint: zoneHint,
            zonesCompleted: zonesCompleted, totalZones: totalZones)
        let content = ActivityContent(state: state, staleDate: nil)
        Task { await activity.update(content) }
    }

    static func end() {
        guard let activity = current else {
            current = nil
            return
        }
        current = nil
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }

    /// Spec 05 §6.5 — if the app was killed mid-session a Live Activity can linger;
    /// dismiss any on launch so there is never a stuck timer.
    static func endStaleOnLaunch() {
        for activity in Activity<BrushingActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
        current = nil
    }
}
#else
@MainActor
enum BrushingLiveActivity {
    static func start(profileName: String, totalSeconds: Int) {}
    static func update(secondsRemaining: Int, zoneHint: String,
                       zonesCompleted: Int, totalZones: Int) {}
    static func end() {}
}
#endif
