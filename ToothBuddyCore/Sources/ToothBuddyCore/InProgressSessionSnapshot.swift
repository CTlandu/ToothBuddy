import Foundation

/// Phase 1.5 / U3 (Open Questions D-2) — a crash-safety snapshot of a brushing session
/// that is in progress when the app is backgrounded.
///
/// A 2-minute session can be interrupted (a call, leaving the app) and then the app killed
/// by the OS before the user returns. Without this, that near-complete brush vanishes — the
/// today goal silently shows no progress, which directly undercuts the product's "never lose
/// a record" promise. Because `activeSeconds` here is SessionClock's already-paused-aware
/// value, committing it on the next launch is honest (never inflated), not a guess.
///
/// Written by `BrushView` on `scenePhase == .background`, cleared on resume / normal finish,
/// and committed by `BrushingStore` at next launch if it survived (i.e. the app was killed).
public struct InProgressSessionSnapshot: Codable, Sendable, Equatable {
    /// UserDefaults key shared by the writer (BrushView) and the recoverer (BrushingStore).
    public static let userDefaultsKey = "ToothBuddy.inProgressSession.v1"

    public var startDate: Date
    public var activeSeconds: Int
    public var targetSeconds: Int
    public var coverage: [CoarseZone: Int]
    public var cameraVerified: Bool
    public var guidanceMode: GuidanceMode

    public init(startDate: Date, activeSeconds: Int, targetSeconds: Int,
                coverage: [CoarseZone: Int], cameraVerified: Bool, guidanceMode: GuidanceMode) {
        self.startDate = startDate
        self.activeSeconds = activeSeconds
        self.targetSeconds = targetSeconds
        self.coverage = coverage
        self.cameraVerified = cameraVerified
        self.guidanceMode = guidanceMode
    }

    /// The honest end timestamp for the recovered record: start + active (non-inflated).
    public var recoveredEndDate: Date {
        startDate.addingTimeInterval(TimeInterval(max(0, activeSeconds)))
    }
}
