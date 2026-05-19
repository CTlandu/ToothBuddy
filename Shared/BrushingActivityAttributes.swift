import Foundation

#if canImport(ActivityKit)
import ActivityKit

/// The Live Activity model (Spec 05 §6.5) — shared by the app (which starts/updates/ends
/// the activity) and the widget extension (which renders the Lock Screen / Dynamic
/// Island). Live Activities require iOS 16.1; the app deploys to 16.0 so every use is
/// availability-gated and brushing works unchanged when unsupported.
@available(iOS 16.1, *)
struct BrushingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var secondsRemaining: Int
        public var zoneHint: String
        public init(secondsRemaining: Int, zoneHint: String) {
            self.secondsRemaining = secondsRemaining
            self.zoneHint = zoneHint
        }
    }
    public var profileName: String
    public init(profileName: String) { self.profileName = profileName }
}
#endif
