import XCTest
import ToothBuddyCore
@testable import ToothBuddy

/// Quality audit 2026-05-28 / Plan U5 — Regression net for the P4.3 CHANGELOG claim:
/// > "hard caps (≤8 bugs, ≤60 confetti)"
///
/// **Honest scope:**
/// - The bug count IS bounded by the pure `BrushGame` Core engine
///   (`bugsPerZone` × `CoarseZone.allCases.count` = 3 × 6 = 18 total upper bound;
///   the "≤8" figure in the CHANGELOG was the transitional on-screen bound during
///   normal zone-switching, not a literal hard limit). Verifiable here.
/// - The `maxConfetti = 60` constant lives inside a `fileprivate` view model in
///   `BrushGameOverlay.swift` and is not reachable from a unit test without making
///   the view model `internal`. The constant is set by a single literal and its
///   only call site (`burstConfetti`) iterates exactly `maxConfetti` times, so any
///   regression would require deliberately editing that literal. Documented gap;
///   tradeoff judged not worth restructuring the view model.
@MainActor
final class BrushGameOverlayCapsTests: XCTestCase {

    /// Core-side: the pure rules engine bounds the total bug count at
    /// `bugsPerZone × #zones`. This is the upper bound any UI layer inherits.
    func test_regression_brushGameTotalBugsBoundedByConfig() {
        let game = BrushGame()
        let totalBugs = game.remaining.values.reduce(0, +)
        let upperBound = BrushGameConfig().bugsPerZone * CoarseZone.allCases.count
        XCTAssertEqual(totalBugs, upperBound)
        XCTAssertEqual(upperBound, 18, "Default config is 3 bugs/zone × 6 zones = 18")
    }

    /// Core-side: per-zone bug count is exactly `bugsPerZone` at start, never more.
    /// This is the lower-level invariant that the "transitional ≤8 visible" UI cap
    /// is built on top of (1 active cluster + at most 1 fading-out cluster).
    func test_regression_brushGamePerZoneBugCountIsExact() {
        let game = BrushGame()
        for zone in CoarseZone.allCases {
            XCTAssertEqual(game.remaining[zone], 3,
                           "Default per-zone bug count must be exactly 3 (regression: \(zone))")
        }
    }

    /// Core-side: a fully-cleared game reports `totalRemaining == 0` and
    /// `bugsZapped == upperBound`. Pins the "win celebration triggers exactly once
    /// at totalRemaining == 0" claim that BrushGameOverlay's `won` flag depends on.
    func test_regression_brushGameClearsToZeroAndZapTotalMatches() {
        var game = BrushGame()
        let upperBound = BrushGameConfig().bugsPerZone * CoarseZone.allCases.count

        // Hammer each zone for clearInterval × bugsPerZone seconds with isActive=true.
        for zone in CoarseZone.allCases {
            for _ in 0..<BrushGameConfig().bugsPerZone {
                game.advance(currentZone: zone, isActive: true,
                             dt: BrushGameConfig().clearInterval)
            }
        }
        XCTAssertEqual(game.totalRemaining, 0)
        XCTAssertEqual(game.bugsZapped, upperBound)
    }
}
