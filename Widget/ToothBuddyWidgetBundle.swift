import WidgetKit
import SwiftUI

/// The widget extension entry point (Spec 05 §6.4–§6.5). Bundles the Home Screen
/// streak widget and the brushing Live Activity.
/// (iOS 16.1 guard removed at deployment-target bump to 17.0, Plan U5.)
@main
struct ToothBuddyWidgetBundle: WidgetBundle {
    var body: some Widget {
        StreakWidget()
        BrushingLiveActivityWidget()
    }
}
