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
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(Duo.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Brushing — \(context.attributes.profileName)")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(Duo.ink)
                    Text(context.state.zoneHint)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Duo.muted)
                }
                Spacer()
                Text(timeText(context.state.secondsRemaining))
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(Duo.ink)
            }
            .padding(14)
            .activityBackgroundTint(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "mouth.fill")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(Duo.green)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timeText(context.state.secondsRemaining))
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(Duo.ink)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.zoneHint)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Duo.muted)
                }
            } compactLeading: {
                Image(systemName: "mouth.fill")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(Duo.green)
            } compactTrailing: {
                Text(timeText(context.state.secondsRemaining))
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(Duo.ink)
            } minimal: {
                Image(systemName: "mouth.fill")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(Duo.green)
            }
        }
    }

    private func timeText(_ s: Int) -> String {
        let s = max(0, s)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
#endif
