import Foundation
import WidgetKit
import ToothBuddyCore

/// App-side: rebuilds the `WidgetSnapshot` for the active profile and pushes it to the
/// App Group, then asks WidgetKit to refresh (Spec 05 §6.4). Called after any change
/// that can move the streak/slots: session logged, profile switched, scene background.
@MainActor
enum WidgetBridge {
    static func refresh() {
        let profiles = ProfileStore.shared
        guard let p = profiles.activeProfile else {
            AppGroup.write(.placeholder)
            WidgetCenter.shared.reloadAllTimelines()
            return
        }
        let snap = WidgetSnapshotBuilder.build(
            records: BrushingStore.shared.records,
            profileID: p.id, profileName: p.name,
            asOf: Date(), calendar: .current)
        AppGroup.write(snap)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
