import XCTest
@testable import ToothBuddyCore

/// U1 — brush-token gate (P1: reward only the verifiable ritual, never quality).
final class RewardEngineTests: XCTestCase {

    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()
    private let pid = UUID()
    private var base: Date { DateComponents(calendar: cal, year: 2026, month: 7, day: 3).date! }

    /// A record that satisfies `metMinimum`: active ≥ target and every zone covered to target.
    private func metRecord(durationSeconds: Int = 130,
                           targetSeconds: Int = 120,
                           activeSeconds: Int? = nil,
                           cameraVerified: Bool = false) -> BrushingRecord {
        let coverage = Dictionary(uniqueKeysWithValues: CoarseZone.allCases.map { ($0, targetSeconds) })
        return BrushingRecord(profileID: pid,
                              startDate: base,
                              endDate: base.addingTimeInterval(TimeInterval(durationSeconds)),
                              activeSeconds: activeSeconds ?? targetSeconds,
                              targetSeconds: targetSeconds,
                              coverage: coverage,
                              cameraVerified: cameraVerified)
    }

    /// A record that fails `metMinimum`: active below target, no coverage.
    private func shortRecord(durationSeconds: Int = 40, targetSeconds: Int = 120) -> BrushingRecord {
        BrushingRecord(profileID: pid,
                       startDate: base,
                       endDate: base.addingTimeInterval(TimeInterval(durationSeconds)),
                       activeSeconds: durationSeconds,
                       targetSeconds: targetSeconds)
    }

    func testMintsTokenWhenMetMinimum() {
        let out = RewardEngine.evaluate(record: metRecord(), priorRecords: [])
        XCTAssertTrue(out.mintsToken)
    }

    func testNoTokenBelowMinimum() {
        let out = RewardEngine.evaluate(record: shortRecord(), priorRecords: [])
        XCTAssertFalse(out.mintsToken)
        XCTAssertEqual(out.tier, .belowMinimum)
    }

    func testFullTwoMinutesTier() {
        // Met, ≥120s, and NOT a record (a longer prior exists).
        let prior = metRecord(durationSeconds: 200)
        let out = RewardEngine.evaluate(record: metRecord(durationSeconds: 130),
                                        priorRecords: [prior])
        XCTAssertEqual(out.tier, .fullTwoMinutes)
    }

    func testPersonalRecord() {
        let prior = metRecord(durationSeconds: 130)
        let out = RewardEngine.evaluate(record: metRecord(durationSeconds: 210),
                                        priorRecords: [prior])
        XCTAssertEqual(out.tier, .personalRecord)
        XCTAssertTrue(out.mintsToken)
    }

    func testFirstGoodBrushIsNotAFalseRecord() {
        // Empty priors → the first met brush celebrates, but is NOT tagged personalRecord.
        let out = RewardEngine.evaluate(record: metRecord(durationSeconds: 130), priorRecords: [])
        XCTAssertEqual(out.tier, .fullTwoMinutes)
        XCTAssertTrue(out.mintsToken)
    }

    func testShortTargetMetTier() {
        // A sub-2-minute target that is met → .metMinimum (distinct from fullTwoMinutes).
        let out = RewardEngine.evaluate(record: metRecord(durationSeconds: 90, targetSeconds: 80),
                                        priorRecords: [])
        XCTAssertTrue(out.mintsToken)
        XCTAssertEqual(out.tier, .metMinimum)
    }

    /// P1: the outcome must not depend on cameraVerified (quality is not measurable).
    func testCameraVerifiedDoesNotChangeOutcome() {
        let verified = RewardEngine.evaluate(record: metRecord(cameraVerified: true), priorRecords: [])
        let unverified = RewardEngine.evaluate(record: metRecord(cameraVerified: false), priorRecords: [])
        XCTAssertEqual(verified, unverified)
    }
}
