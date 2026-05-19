import WidgetKit
import SwiftUI

#if canImport(ActivityKit)
import ActivityKit

/// Lock Screen + Dynamic Island rendering of the brushing Live Activity (Spec 05 §6.5).
/// The app owns the lifecycle/state; this only draws. iOS 16.1+.
@available(iOS 16.1, *)
struct BrushingLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BrushingActivityAttributes.self) { context in
            // Lock Screen / banner.
            HStack(spacing: 14) {
                Image(systemName: "mouth.fill")
                    .font(.title2).foregroundColor(.cyan)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Brushing — \(context.attributes.profileName)")
                        .font(.headline)
                    Text(context.state.zoneHint)
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Text(timeText(context.state.secondsRemaining))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.25))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "mouth.fill").foregroundColor(.cyan)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timeText(context.state.secondsRemaining))
                        .font(.system(.title3, design: .rounded))
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.zoneHint).font(.caption)
                }
            } compactLeading: {
                Image(systemName: "mouth.fill").foregroundColor(.cyan)
            } compactTrailing: {
                Text(timeText(context.state.secondsRemaining))
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "mouth.fill").foregroundColor(.cyan)
            }
        }
    }

    private func timeText(_ s: Int) -> String {
        let s = max(0, s)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
#endif
