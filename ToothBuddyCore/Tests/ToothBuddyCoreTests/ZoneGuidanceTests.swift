import XCTest
@testable import ToothBuddyCore

/// Spec 04 §8 / AC1–AC7. Synthetic samples; no Vision.
final class ZoneGuidanceTests: XCTestCase {
    private let cfg = ZoneGuidanceConfig.default
    private let mouth = UnitPoint2D(x: 0.5, y: 0.5)

    private func sample(handX: Double, handY: Double, motion: Double = 0.5,
                        face: Bool = true, hand: Bool = true, t: Double = 0) -> ZoneSample {
        ZoneSample(
            face: FaceSignal(isPresent: face, mouthCenter: face ? mouth : nil),
            hand: HandSignal(isPresent: hand,
                             position: hand ? UnitPoint2D(x: handX, y: handY) : nil,
                             motionEnergy: motion),
            atSeconds: t)
    }

    // AC1 — all six zones from representative hand positions near the mouth.
    func testZoneMappingAllSix() {
        func zone(_ x: Double, _ y: Double) -> CoarseZone? {
            BrushingZoneEstimator.estimate(window: [sample(handX: x, handY: y)],
                                           config: cfg).zone
        }
        XCTAssertEqual(zone(0.30, 0.35), .upperLeft)
        XCTAssertEqual(zone(0.70, 0.35), .upperRight)
        XCTAssertEqual(zone(0.30, 0.65), .lowerLeft)
        XCTAssertEqual(zone(0.70, 0.65), .lowerRight)
        XCTAssertEqual(zone(0.52, 0.35), .frontTop)
        XCTAssertEqual(zone(0.52, 0.66), .frontBottom)
    }

    // AC2 — not actively brushing.
    func testNotBrushingConditions() {
        let faceGone = BrushingZoneEstimator.estimate(
            window: [sample(handX: 0.3, handY: 0.35, face: false)], config: cfg)
        XCTAssertFalse(faceGone.isActivelyBrushing)
        XCTAssertNil(faceGone.zone)

        let handGone = BrushingZoneEstimator.estimate(
            window: [sample(handX: 0.3, handY: 0.35, hand: false)], config: cfg)
        XCTAssertFalse(handGone.isActivelyBrushing)

        let lowMotion = BrushingZoneEstimator.estimate(
            window: [sample(handX: 0.3, handY: 0.35, motion: 0.05)], config: cfg)
        XCTAssertFalse(lowMotion.isActivelyBrushing)

        let farHand = BrushingZoneEstimator.estimate(
            window: [sample(handX: 0.95, handY: 0.95)], config: cfg)  // > nearRadius
        XCTAssertFalse(farHand.isActivelyBrushing)
    }

    // AC6 — partial/missing signals → nil, no crash.
    func testPartialSignalsSafe() {
        let noMouth = ZoneSample(face: FaceSignal(isPresent: true, mouthCenter: nil),
                                 hand: HandSignal(isPresent: true,
                                                  position: UnitPoint2D(x: 0.3, y: 0.3),
                                                  motionEnergy: 0.5),
                                 atSeconds: 0)
        XCTAssertEqual(BrushingZoneEstimator.estimate(window: [noMouth], config: cfg),
                       ZoneEstimate(zone: nil, isActivelyBrushing: false))
        XCTAssertEqual(BrushingZoneEstimator.estimate(window: [], config: cfg),
                       ZoneEstimate(zone: nil, isActivelyBrushing: false))
    }

    // AC3 — coverage tracker.
    func testCoverageTracker() {
        var c = ZoneCoverageTracker()
        c.record(.upperLeft, dt: 5)
        c.record(.upperLeft, dt: 3)
        c.record(.lowerRight, dt: 1)
        XCTAssertEqual(c.coverage(for: .upperLeft), 8)
        XCTAssertTrue(c.isWellCovered(.upperLeft, threshold: 8))
        XCTAssertFalse(c.isWellCovered(.lowerRight, threshold: 2))
        XCTAssertEqual(c.leastCovered(), .upperRight)   // 0, first such in allCases order
    }

    // AC5 — fallback timed cadence is deterministic.
    func testFallbackTimedCadence() {
        func prompt(_ elapsed: Double) -> CoarseZone {
            GuidanceDecider.decide(mode: .fallbackTimed, estimate: nil,
                                   coverage: ZoneCoverageTracker(), elapsed: elapsed,
                                   state: GuidanceState(), config: cfg).promptZone
        }
        XCTAssertEqual(prompt(0), CoarseZone.allCases[0])
        XCTAssertEqual(prompt(15), CoarseZone.allCases[1])
        XCTAssertEqual(prompt(30), CoarseZone.allCases[2])
        XCTAssertEqual(prompt(90), CoarseZone.allCases[0])   // wraps (6 zones × 15s)
    }

    // AC4 — camera mode steers to least-covered + debounces announcements.
    func testCameraModeSteersAndDebounces() {
        var cov = ZoneCoverageTracker()
        for z in CoarseZone.allCases where z != .lowerRight { cov.record(z, dt: 10) }
        let est = ZoneEstimate(zone: .upperLeft, isActivelyBrushing: true)

        let d1 = GuidanceDecider.decide(mode: .camera, estimate: est, coverage: cov,
                                        elapsed: 10, state: GuidanceState(), config: cfg)
        XCTAssertEqual(d1.promptZone, .lowerRight)          // least covered
        XCTAssertTrue(d1.shouldAnnounce)

        // Now upperLeft becomes least; within debounce window → no new announcement.
        var cov2 = ZoneCoverageTracker()
        for z in CoarseZone.allCases where z != .upperLeft { cov2.record(z, dt: 10) }
        let d2 = GuidanceDecider.decide(mode: .camera, estimate: est, coverage: cov2,
                                        elapsed: 11, state: d1.newState, config: cfg)
        XCTAssertEqual(d2.promptZone, .upperLeft)
        XCTAssertFalse(d2.shouldAnnounce)                   // 11 - 10 < 3s debounce
        XCTAssertEqual(d2.newState, d1.newState)            // state unchanged

        let d3 = GuidanceDecider.decide(mode: .camera, estimate: est, coverage: cov2,
                                        elapsed: 14, state: d1.newState, config: cfg)
        XCTAssertTrue(d3.shouldAnnounce)                    // 14 - 10 >= 3s
    }

    // AC7 — determinism.
    func testDeterministic() {
        let w = [sample(handX: 0.3, handY: 0.35, t: 0),
                 sample(handX: 0.3, handY: 0.35, t: 1)]
        XCTAssertEqual(BrushingZoneEstimator.estimate(window: w, config: cfg),
                       BrushingZoneEstimator.estimate(window: w, config: cfg))
    }
}
