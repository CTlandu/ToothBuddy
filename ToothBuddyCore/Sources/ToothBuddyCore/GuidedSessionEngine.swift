import Foundation

/// The prescribed brushing route + per-zone goal for a session (U2).
public struct SessionPlan: Equatable, Sendable {
    public let targetSeconds: Int
    public let zoneOrder: [CoarseZone]

    public init(targetSeconds: Int = 120, zoneOrder: [CoarseZone] = CoarseZone.allCases) {
        self.targetSeconds = targetSeconds
        self.zoneOrder = zoneOrder.isEmpty ? CoarseZone.allCases : zoneOrder
    }

    /// Seconds each zone must be brushed. At least 1.
    public var perZoneTarget: Int { max(1, targetSeconds / zoneOrder.count) }
}

/// A snapshot of how far a session has come, derived purely from the coverage map.
public struct SessionProgress: Equatable, Sendable {
    public let currentZone: CoarseZone?     // nil once every zone hit its target
    public let zoneRemainingSeconds: Int    // remaining for currentZone (0 when complete)
    public let zonesCompleted: Int
    public let totalZones: Int
    public let overall: Double              // 0…1, fraction of prescribed dwell achieved
    public let isComplete: Bool             // every zone reached its per-zone target
}

/// Pure, deterministic engine for the prescribed-route session.
///
/// `fallbackTimed` (guided-only / no camera): the route advances through `zoneOrder`; each tick
/// credits the current prescribed zone — coverage is *prescribed*. `camera`: each tick credits
/// the *detected* zone and the prompt steers toward the least-covered unfinished zone — coverage
/// is *measured*. Same coverage map feeds `BrushingRecord.metMinimum` either way; only
/// `cameraVerified` distinguishes the two.
public enum GuidedSessionEngine {

    /// The zone to prompt next, or nil when the route is complete.
    public static func currentZone(plan: SessionPlan,
                                   coverage: [CoarseZone: Int],
                                   mode: GuidanceMode) -> CoarseZone? {
        let perZone = plan.perZoneTarget
        let unfinished = plan.zoneOrder.filter { (coverage[$0] ?? 0) < perZone }
        guard !unfinished.isEmpty else { return nil }
        switch mode {
        case .fallbackTimed:
            return unfinished.first                 // strict prescribed order
        case .camera:
            // Least-covered unfinished; `min` keeps the first on ties ⇒ zoneOrder tiebreak.
            return unfinished.min { (coverage[$0] ?? 0) < (coverage[$1] ?? 0) }
        }
    }

    /// Credit `dt` seconds and return the new coverage map. Guided mode credits the current
    /// prescribed zone; camera mode credits the detected zone only while actively brushing.
    public static func tick(plan: SessionPlan,
                            coverage: [CoarseZone: Int],
                            mode: GuidanceMode,
                            detected: ZoneEstimate?,
                            dt: Int) -> [CoarseZone: Int] {
        guard dt > 0 else { return coverage }
        var cov = coverage
        switch mode {
        case .fallbackTimed:
            if let z = currentZone(plan: plan, coverage: cov, mode: mode) {
                cov[z, default: 0] += dt
            }
        case .camera:
            if let d = detected, d.isActivelyBrushing, let z = d.zone {
                cov[z, default: 0] += dt
            }
        }
        return cov
    }

    public static func progress(plan: SessionPlan,
                                coverage: [CoarseZone: Int],
                                mode: GuidanceMode) -> SessionProgress {
        let perZone = plan.perZoneTarget
        let total = plan.zoneOrder.count
        let completed = plan.zoneOrder.filter { (coverage[$0] ?? 0) >= perZone }.count
        let current = currentZone(plan: plan, coverage: coverage, mode: mode)
        let remaining = current.map { max(0, perZone - (coverage[$0] ?? 0)) } ?? 0
        let credited = plan.zoneOrder.reduce(0) { $0 + min(coverage[$1] ?? 0, perZone) }
        let overall = Double(credited) / Double(perZone * total)
        return SessionProgress(currentZone: current,
                               zoneRemainingSeconds: remaining,
                               zonesCompleted: completed,
                               totalZones: total,
                               overall: overall,
                               isComplete: completed == total)
    }
}

/// Decides the un-fakeable `cameraVerified` flag: the camera must have been authorized for the
/// session AND have detected brushing for at least `threshold` of the active time.
public enum CameraVerification {
    public static func decide(cameraAuthorized: Bool,
                              brushingDetectedSeconds: Int,
                              activeSeconds: Int,
                              threshold: Double = 0.5) -> Bool {
        guard cameraAuthorized, activeSeconds > 0 else { return false }
        return Double(brushingDetectedSeconds) / Double(activeSeconds) >= threshold
    }
}
