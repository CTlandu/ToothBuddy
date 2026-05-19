import Foundation
import ToothBuddyCore

/// The single source of the App Group id + the `WidgetSnapshot` read/write path
/// (Spec 05 §6.4). Compiled into BOTH the app and the widget extension. The widget
/// only ever reads this — it never touches Core Data.
enum AppGroup {
    static let id = "group.com.ctlandu.ToothBuddy"
    private static let snapshotKey = "ToothBuddy.widgetSnapshot.v1"

    private static var defaults: UserDefaults? { UserDefaults(suiteName: id) }

    static func write(_ snapshot: WidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: snapshotKey)
    }

    /// Never throws / never blank — a friendly placeholder if there is no data.
    static func readSnapshot() -> WidgetSnapshot {
        guard let data = defaults?.data(forKey: snapshotKey),
              let s = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return .placeholder }
        return s
    }
}
