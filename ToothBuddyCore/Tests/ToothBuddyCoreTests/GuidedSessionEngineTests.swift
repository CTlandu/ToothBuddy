import XCTest
@testable import ToothBuddyCore

/// U2 — pure prescribed-route session engine. No camera, no UI: drives the guided
/// zone sequence, accumulates coverage, decides progress + completion.
final class GuidedSessionEngineTests: XCTestCase {

    func testPerZoneTargetScales() {
        XCTAssertEqual(SessionPlan(targetSeconds: 120).perZoneTarget, 20) // 6 zones
        XCTAssertEqual(SessionPlan(targetSeconds: 180).perZoneTarget, 30)
    }

    func testGuidedRouteTraversesAllZonesInOrder() {
        let plan = SessionPlan(targetSeconds: 120)
        var cov: [CoarseZone: Int] = [:]
        var visited: [CoarseZone] = []
        for _ in 0..<120 {
            let z = GuidedSessionEngine.currentZone(plan: plan, coverage: cov, mode: .fallbackTimed)!
            if visited.last != z { visited.append(z) }
            cov = GuidedSessionEngine.tick(plan: plan, coverage: cov, mode: .fallbackTimed,
                                           detected: nil, dt: 1)
        }
        XCTAssertEqual(visited, CoarseZone.allCases)               // each zone, in order
        for z in CoarseZone.allCases { XCTAssertEqual(cov[z], 20) } // each got its target
        let p = GuidedSessionEngine.progress(plan: plan, coverage: cov, mode: .fallbackTimed)
        XCTAssertTrue(p.isComplete)
        XCTAssertNil(p.currentZone)
        XCTAssertEqual(p.overall, 1.0, accuracy: 0.0001)
        XCTAssertEqual(p.zonesCompleted, 6)
    }

    func testEarlyEndReflectsActualCoverage() {
        let plan = SessionPlan(targetSeconds: 120) // perZone 20
        var cov: [CoarseZone: Int] = [:]
        for _ in 0..<50 {
            cov = GuidedSessionEngine.tick(plan: plan, coverage: cov, mode: .fallbackTimed,
                                           detected: nil, dt: 1)
        }
        let p = GuidedSessionEngine.progress(plan: plan, coverage: cov, mode: .fallbackTimed)
        XCTAssertFalse(p.isComplete)
        XCTAssertLessThan(p.overall, 1.0)
        XCTAssertEqual(p.zonesCompleted, 2)          // 50s ⇒ 2 full zones (40s) + 10s into 3rd
        XCTAssertEqual(p.currentZone, .lowerLeft)    // 3rd zone in order
        XCTAssertEqual(p.zoneRemainingSeconds, 10)
    }

    func testCameraModeSteersToLeastCoveredUnfinished() {
        let plan = SessionPlan(targetSeconds: 120) // perZone 20
        let cov: [CoarseZone: Int] = [.upperLeft: 20, .upperRight: 5] // others absent (0)
        // upperLeft is done ⇒ excluded; least-covered unfinished = first 0 in order = lowerLeft.
        XCTAssertEqual(GuidedSessionEngine.currentZone(plan: plan, coverage: cov, mode: .camera),
                       .lowerLeft)
    }

    func testCameraTickCreditsDetectedZoneOnlyWhenBrushing() {
        let plan = SessionPlan(targetSeconds: 120)
        let brushing = ZoneEstimate(zone: .frontTop, isActivelyBrushing: true)
        XCTAssertEqual(GuidedSessionEngine.tick(plan: plan, coverage: [:], mode: .camera,
                                                detected: brushing, dt: 3)[.frontTop], 3)
        let idle = ZoneEstimate(zone: .frontTop, isActivelyBrushing: false)
        XCTAssertTrue(GuidedSessionEngine.tick(plan: plan, coverage: [:], mode: .camera,
                                               detected: idle, dt: 3).isEmpty)
        XCTAssertTrue(GuidedSessionEngine.tick(plan: plan, coverage: [:], mode: .camera,
                                               detected: nil, dt: 3).isEmpty)
    }

    func testCameraVerificationThreshold() {
        XCTAssertTrue(CameraVerification.decide(cameraAuthorized: true,
                                                brushingDetectedSeconds: 60, activeSeconds: 100))
        XCTAssertFalse(CameraVerification.decide(cameraAuthorized: true,
                                                 brushingDetectedSeconds: 40, activeSeconds: 100))
        XCTAssertFalse(CameraVerification.decide(cameraAuthorized: false,
                                                 brushingDetectedSeconds: 100, activeSeconds: 100))
        XCTAssertFalse(CameraVerification.decide(cameraAuthorized: true,
                                                 brushingDetectedSeconds: 0, activeSeconds: 0))
    }

    func testDeterministic() {
        let plan = SessionPlan(targetSeconds: 120)
        let cov: [CoarseZone: Int] = [.upperLeft: 5, .lowerLeft: 12]
        XCTAssertEqual(GuidedSessionEngine.progress(plan: plan, coverage: cov, mode: .camera),
                       GuidedSessionEngine.progress(plan: plan, coverage: cov, mode: .camera))
        XCTAssertEqual(GuidedSessionEngine.currentZone(plan: plan, coverage: cov, mode: .fallbackTimed),
                       GuidedSessionEngine.currentZone(plan: plan, coverage: cov, mode: .fallbackTimed))
    }
}
