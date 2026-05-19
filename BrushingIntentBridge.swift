import Foundation
import Combine

/// Bridges `StartBrushingIntent` (Spec 05 §6.3) into the running UI: the intent flips
/// `startRequested`; `ContentView` switches to the Brush tab and `BrushView` begins a
/// session, then clears the flag. A no-op if the app can't foreground — nothing crashes,
/// the request is simply consumed on next appearance.
@MainActor
final class BrushingIntentBridge: ObservableObject {
    static let shared = BrushingIntentBridge()
    @Published var startRequested = false

    func requestStart() { startRequested = true }
    func consume() { startRequested = false }
}
