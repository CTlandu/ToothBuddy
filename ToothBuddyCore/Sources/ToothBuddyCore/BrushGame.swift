import Foundation

/// "Sugar Bugs" game rules (Spec 04.3 §7). Pure & deterministic — the visual layer only
/// renders this state, never decides logic.
public struct BrushGameConfig: Equatable, Sendable {
    public var bugsPerZone: Int
    public var clearInterval: Double      // seconds of *active* brushing to clear 1 bug
    public var pointsPerBug: Int

    public init(bugsPerZone: Int = 3, clearInterval: Double = 0.7, pointsPerBug: Int = 10) {
        self.bugsPerZone = bugsPerZone
        self.clearInterval = clearInterval
        self.pointsPerBug = pointsPerBug
    }
    public static let `default` = BrushGameConfig()
}

public struct BrushGame: Equatable, Sendable {
    public private(set) var remaining: [CoarseZone: Int]
    public private(set) var score: Int

    private let config: BrushGameConfig
    private var accumulator: Double          // active seconds banked toward the next clear
    private var lastZone: CoarseZone?        // accumulator is per-zone; resets on change

    public init(config: BrushGameConfig = .default) {
        self.config = config
        self.score = 0
        self.accumulator = 0
        self.lastZone = nil
        var r: [CoarseZone: Int] = [:]
        for z in CoarseZone.allCases { r[z] = max(0, config.bugsPerZone) }
        self.remaining = r
    }

    /// Advance the game by `dt` seconds. Clears bugs only in `currentZone`, only while
    /// `isActive`, at one bug per `clearInterval` of active time. The fractional
    /// accumulator carries across ticks within the same zone and resets when the zone
    /// changes or becomes nil. No-ops safely on bad input; counts never go negative.
    public mutating func advance(currentZone: CoarseZone?, isActive: Bool, dt: Double) {
        guard let zone = currentZone else {
            accumulator = 0
            lastZone = nil
            return
        }
        if zone != lastZone {
            accumulator = 0
            lastZone = zone
        }
        guard isActive, dt > 0, (remaining[zone] ?? 0) > 0,
              config.clearInterval > 0 else { return }

        accumulator += dt
        while accumulator >= config.clearInterval, (remaining[zone] ?? 0) > 0 {
            accumulator -= config.clearInterval
            remaining[zone] = (remaining[zone] ?? 0) - 1
            score += config.pointsPerBug
        }
        if (remaining[zone] ?? 0) == 0 { accumulator = 0 }   // nothing left to bank
    }

    public var totalRemaining: Int { remaining.values.reduce(0, +) }

    public var bugsZapped: Int {
        CoarseZone.allCases.count * max(0, config.bugsPerZone) - totalRemaining
    }

    public func zonesCleared() -> Int {
        CoarseZone.allCases.reduce(0) { $0 + ((remaining[$1] ?? 0) == 0 ? 1 : 0) }
    }

    public func stars() -> Int {
        let c = zonesCleared()
        if c >= 6 { return 3 }
        if c >= 4 { return 2 }
        if c >= 1 { return 1 }
        return 0
    }
}
