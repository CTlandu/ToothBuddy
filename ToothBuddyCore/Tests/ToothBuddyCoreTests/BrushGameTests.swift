import XCTest
@testable import ToothBuddyCore

/// Spec 04.3 §7/§11 — pure game rules.
final class BrushGameTests: XCTestCase {

    func testSeeds() {
        let g = BrushGame()
        XCTAssertEqual(g.totalRemaining, 18)                 // 3 × 6 zones
        for z in CoarseZone.allCases { XCTAssertEqual(g.remaining[z], 3) }
        XCTAssertEqual(g.score, 0)
        XCTAssertEqual(g.bugsZapped, 0)
        XCTAssertEqual(g.zonesCleared(), 0)
        XCTAssertEqual(g.stars(), 0)
    }

    func testAccumulatorCarriesAndClearsByInterval() {
        var g = BrushGame(config: BrushGameConfig(bugsPerZone: 3,
                                                  clearInterval: 1.0, pointsPerBug: 10))
        g.advance(currentZone: .upperLeft, isActive: true, dt: 0.5)
        XCTAssertEqual(g.remaining[.upperLeft], 3)            // 0.5 < 1.0 → none yet
        g.advance(currentZone: .upperLeft, isActive: true, dt: 0.6)
        XCTAssertEqual(g.remaining[.upperLeft], 2)            // acc 1.1 → 1 cleared
        XCTAssertEqual(g.score, 10)
        g.advance(currentZone: .upperLeft, isActive: true, dt: 2.0)
        XCTAssertEqual(g.remaining[.upperLeft], 0)            // capped at remaining
        XCTAssertEqual(g.score, 30)
        XCTAssertEqual(g.totalRemaining, 15)
        XCTAssertEqual(g.bugsZapped, 3)
    }

    func testNoOpWhenInactiveOrNilZone() {
        var g = BrushGame()
        g.advance(currentZone: .upperLeft, isActive: false, dt: 5)
        g.advance(currentZone: nil, isActive: true, dt: 5)
        XCTAssertEqual(g.totalRemaining, 18)
        XCTAssertEqual(g.score, 0)
    }

    func testZoneChangeResetsAccumulator() {
        var g = BrushGame(config: BrushGameConfig(bugsPerZone: 3,
                                                  clearInterval: 1.0, pointsPerBug: 10))
        g.advance(currentZone: .upperLeft, isActive: true, dt: 0.9)   // banked, no clear
        g.advance(currentZone: .upperRight, isActive: true, dt: 0.2)  // zone change → reset
        XCTAssertEqual(g.remaining[.upperLeft], 3)
        XCTAssertEqual(g.remaining[.upperRight], 3)
        XCTAssertEqual(g.score, 0)
    }

    func testNeverNegativeAndCappedPerZone() {
        var g = BrushGame(config: BrushGameConfig(bugsPerZone: 2,
                                                  clearInterval: 0.1, pointsPerBug: 5))
        g.advance(currentZone: .lowerLeft, isActive: true, dt: 100)
        XCTAssertEqual(g.remaining[.lowerLeft], 0)
        XCTAssertEqual(g.score, 10)                          // exactly 2 × 5, not more
        XCTAssertEqual(g.totalRemaining, 10)                 // init 2×6=12, −2 cleared
    }

    func testZonesClearedAndStarThresholds() {
        func gameClearing(_ n: Int) -> BrushGame {
            var g = BrushGame(config: BrushGameConfig(bugsPerZone: 1,
                                                      clearInterval: 0.1, pointsPerBug: 1))
            for z in CoarseZone.allCases.prefix(n) {
                g.advance(currentZone: z, isActive: true, dt: 1.0)
            }
            return g
        }
        XCTAssertEqual(gameClearing(0).stars(), 0)
        XCTAssertEqual(gameClearing(1).zonesCleared(), 1)
        XCTAssertEqual(gameClearing(1).stars(), 1)
        XCTAssertEqual(gameClearing(4).stars(), 2)
        XCTAssertEqual(gameClearing(6).zonesCleared(), 6)
        XCTAssertEqual(gameClearing(6).stars(), 3)
    }

    func testDeterministic() {
        func run() -> BrushGame {
            var g = BrushGame()
            g.advance(currentZone: .frontTop, isActive: true, dt: 0.7)
            g.advance(currentZone: .frontTop, isActive: true, dt: 0.7)
            g.advance(currentZone: .lowerRight, isActive: true, dt: 1.4)
            return g
        }
        XCTAssertEqual(run(), run())
    }
}
