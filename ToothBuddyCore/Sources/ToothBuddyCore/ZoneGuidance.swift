import Foundation

/// Coarse, engagement-grade brushing zone (Spec 04). Maps 1:1 to the app's `BrushingZone`.
/// Deliberately coarse — never per-tooth/clinical.
public enum CoarseZone: String, CaseIterable, Codable, Sendable, Equatable {
    case upperLeft, upperRight, lowerLeft, lowerRight, frontTop, frontBottom
}

/// Normalized image point. Convention: x 0=left…1=right, y 0=top…1=bottom.
/// The app's Vision adapter converts camera coordinates into this convention.
public struct UnitPoint2D: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
    func distance(to p: UnitPoint2D) -> Double { (Foundation.hypot(x - p.x, y - p.y)) }
}

public struct FaceSignal: Equatable, Sendable {
    public var isPresent: Bool
    public var mouthCenter: UnitPoint2D?
    public var faceYaw: Double?         // reserved; not used by v1 mapping
    public init(isPresent: Bool, mouthCenter: UnitPoint2D? = nil, faceYaw: Double? = nil) {
        self.isPresent = isPresent; self.mouthCenter = mouthCenter; self.faceYaw = faceYaw
    }
}

public struct HandSignal: Equatable, Sendable {
    public var isPresent: Bool
    public var position: UnitPoint2D?
    public var motionEnergy: Double     // 0…1 smoothed movement magnitude
    public init(isPresent: Bool, position: UnitPoint2D? = nil, motionEnergy: Double = 0) {
        self.isPresent = isPresent; self.position = position; self.motionEnergy = motionEnergy
    }
}

public struct ZoneSample: Equatable, Sendable {
    public var face: FaceSignal
    public var hand: HandSignal
    public var atSeconds: Double
    public init(face: FaceSignal, hand: HandSignal, atSeconds: Double) {
        self.face = face; self.hand = hand; self.atSeconds = atSeconds
    }
}

public struct ZoneGuidanceConfig: Equatable, Sendable {
    public var motionThreshold: Double = 0.15
    public var nearRadius: Double = 0.35
    public var deadband: Double = 0.08
    public var frontXBand: Double = 0.12
    public var announceDebounce: Double = 3.0
    public var zoneInterval: Double = 15.0
    public var fallbackGrace: Double = 4.0
    public init() {}
    public static let `default` = ZoneGuidanceConfig()
}

public struct ZoneEstimate: Equatable, Sendable {
    public let zone: CoarseZone?
    public let isActivelyBrushing: Bool
    public init(zone: CoarseZone?, isActivelyBrushing: Bool) {
        self.zone = zone; self.isActivelyBrushing = isActivelyBrushing
    }
}

/// Pure: a window of samples → coarse zone + whether actively brushing. No hidden state.
public enum BrushingZoneEstimator {
    public static func estimate(window: [ZoneSample],
                                config: ZoneGuidanceConfig = .default) -> ZoneEstimate {
        guard let latest = window.last,
              latest.face.isPresent, latest.hand.isPresent,
              let m = latest.face.mouthCenter,
              let h = latest.hand.position else {
            return ZoneEstimate(zone: nil, isActivelyBrushing: false)
        }
        let handSamples = window.filter { $0.hand.isPresent }
        let avgMotion = handSamples.isEmpty ? 0
            : handSamples.map(\.hand.motionEnergy).reduce(0, +) / Double(handSamples.count)
        let near = h.distance(to: m) <= config.nearRadius
        guard near, avgMotion >= config.motionThreshold else {
            return ZoneEstimate(zone: nil, isActivelyBrushing: false)
        }

        let dx = h.x - m.x
        let dy = h.y - m.y
        let isUpper = dy < -config.deadband ? true : (dy > config.deadband ? false : dy <= 0)

        let zone: CoarseZone
        if abs(dx) <= config.frontXBand {
            zone = isUpper ? .frontTop : .frontBottom
        } else if dx < 0 {
            zone = isUpper ? .upperLeft : .lowerLeft
        } else {
            zone = isUpper ? .upperRight : .lowerRight
        }
        return ZoneEstimate(zone: zone, isActivelyBrushing: true)
    }
}

/// Pure value type accumulating dwell time per zone.
public struct ZoneCoverageTracker: Equatable, Sendable {
    private var dwell: [CoarseZone: Double] = [:]
    public init() {}

    public mutating func record(_ zone: CoarseZone, dt: Double) {
        dwell[zone, default: 0] += max(0, dt)
    }
    public func coverage(for zone: CoarseZone) -> Double { dwell[zone, default: 0] }
    public func isWellCovered(_ zone: CoarseZone, threshold: Double) -> Bool {
        coverage(for: zone) >= threshold
    }
    /// Least-covered zone; deterministic tiebreak by `CoarseZone.allCases` order.
    public func leastCovered() -> CoarseZone {
        CoarseZone.allCases.min { coverage(for: $0) < coverage(for: $1) } ?? .upperLeft
    }
}

public enum GuidanceMode: String, Codable, Sendable { case camera, fallbackTimed }

public struct GuidanceState: Equatable, Sendable {
    public var lastAnnouncedZone: CoarseZone?
    public var lastAnnounceAt: Double
    public init(lastAnnouncedZone: CoarseZone? = nil, lastAnnounceAt: Double = -.infinity) {
        self.lastAnnouncedZone = lastAnnouncedZone; self.lastAnnounceAt = lastAnnounceAt
    }
}

public struct GuidanceOutput: Equatable, Sendable {
    public let promptZone: CoarseZone
    public let shouldAnnounce: Bool
    public let newState: GuidanceState
}

/// Pure guidance decision. `camera` steers toward the least-covered zone (debounced);
/// `fallbackTimed` reproduces the legacy blind cadence deterministically.
public enum GuidanceDecider {
    public static func decide(mode: GuidanceMode,
                              estimate: ZoneEstimate?,
                              coverage: ZoneCoverageTracker,
                              targetOrder: [CoarseZone] = CoarseZone.allCases,
                              elapsed: Double,
                              state: GuidanceState,
                              config: ZoneGuidanceConfig = .default) -> GuidanceOutput {
        let order = targetOrder.isEmpty ? CoarseZone.allCases : targetOrder
        let prompt: CoarseZone
        switch mode {
        case .fallbackTimed:
            let idx = Int(max(0, elapsed) / config.zoneInterval) % order.count
            prompt = order[idx]
        case .camera:
            if let e = estimate, e.isActivelyBrushing {
                prompt = coverage.leastCovered()
            } else {
                prompt = state.lastAnnouncedZone ?? order[0]
            }
        }
        let changed = prompt != state.lastAnnouncedZone
        let debounced = (elapsed - state.lastAnnounceAt) >= config.announceDebounce
        let shouldAnnounce = changed && (mode == .fallbackTimed ? true : debounced)
        let newState = shouldAnnounce
            ? GuidanceState(lastAnnouncedZone: prompt, lastAnnounceAt: elapsed)
            : state
        return GuidanceOutput(promptZone: prompt,
                              shouldAnnounce: shouldAnnounce,
                              newState: newState)
    }
}
