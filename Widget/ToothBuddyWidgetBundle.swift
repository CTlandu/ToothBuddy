import WidgetKit
import SwiftUI

/// The widget extension entry point (Spec 05 §6.4–§6.5). Bundles the Home Screen
/// streak widget and — on iOS 16.1+ — the brushing Live Activity.
@main
struct ToothBuddyWidgetBundle: WidgetBundle {
    var body: some Widget {
        StreakWidget()
        if #available(iOS 16.1, *) {
            BrushingLiveActivityWidget()
        }
    }
}
