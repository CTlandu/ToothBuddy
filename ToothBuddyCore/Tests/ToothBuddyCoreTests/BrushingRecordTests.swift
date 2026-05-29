import XCTest
@testable import ToothBuddyCore

final class BrushingRecordTests: XCTestCase {
    private let pid = UUID()
    private func record(durationSeconds: Int) -> BrushingRecord {
        let start = Date(timeIntervalSince1970: 1_000_000)
        return BrushingRecord(profileID: pid, startDate: start,
                              endDate: start.addingTimeInterval(TimeInterval(durationSeconds)))
    }

    func testDurationSeconds() {
        XCTAssertEqual(record(durationSeconds: 90).durationSeconds, 90)
    }

    func testDurationNeverNegative() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        let r = BrushingRecord(profileID: pid, startDate: start, endDate: start.addingTimeInterval(-50))
        XCTAssertEqual(r.durationSeconds, 0)
        XCTAssertEqual(r.starCount, 0)
    }

    func testStarThresholds() {
        XCTAssertEqual(record(durationSeconds: 0).starCount, 0)
        XCTAssertEqual(record(durationSeconds: 1).starCount, 1)
        XCTAssertEqual(record(durationSeconds: 59).starCount, 1)
        XCTAssertEqual(record(durationSeconds: 60).starCount, 2)
        XCTAssertEqual(record(durationSeconds: 119).starCount, 2)
        XCTAssertEqual(record(durationSeconds: 120).starCount, 3)
        XCTAssertEqual(record(durationSeconds: 600).starCount, 3)
    }

    func testCodableRoundTrip() throws {
        let original = record(durationSeconds: 125)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BrushingRecord.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    // MARK: - Enriched fields (U1: quality-pivot record)

    private func fullCoverage(seconds: Int) -> [CoarseZone: Int] {
        Dictionary(uniqueKeysWithValues: CoarseZone.allCases.map { ($0, seconds) })
    }

    private func enriched(active: Int, target: Int,
                          coverage: [CoarseZone: Int],
                          verified: Bool = false,
                          mode: GuidanceMode = .fallbackTimed) -> BrushingRecord {
        let start = Date(timeIntervalSince1970: 1_000_000)
        return BrushingRecord(profileID: pid, startDate: start,
                              endDate: start.addingTimeInterval(TimeInterval(active)),
                              activeSeconds: active, targetSeconds: target,
                              coverage: coverage, cameraVerified: verified, guidanceMode: mode)
    }

    func testMetMinimumTrueWhenAllZonesAndDurationMet() {
        // target 120 ⇒ per-zone 20; all zones 20s, active 120 ⇒ met.
        let r = enriched(active: 120, target: 120, coverage: fullCoverage(seconds: 20))
        XCTAssertTrue(r.metMinimum)
    }

    func testMetMinimumFalseWhenOneZoneShort() {
        var cov = fullCoverage(seconds: 20)
        cov[.frontBottom] = 19
        let r = enriched(active: 120, target: 120, coverage: cov)
        XCTAssertFalse(r.metMinimum)
    }

    func testMetMinimumFalseWhenActiveBelowTargetBoundary() {
        // All zones covered but active one second short of target.
        let r = enriched(active: 119, target: 120, coverage: fullCoverage(seconds: 20))
        XCTAssertFalse(r.metMinimum)
    }

    func testMetMinimumScalesWith180Target() {
        // target 180 ⇒ per-zone 30.
        let met = enriched(active: 180, target: 180, coverage: fullCoverage(seconds: 30))
        XCTAssertTrue(met.metMinimum)
        let notMet = enriched(active: 180, target: 180, coverage: fullCoverage(seconds: 29))
        XCTAssertFalse(notMet.metMinimum)
    }

    func testCoverageRoundTripFull() throws {
        let original = enriched(active: 120, target: 120, coverage: fullCoverage(seconds: 20),
                                verified: true, mode: .camera)
        let decoded = try JSONDecoder().decode(BrushingRecord.self,
                                               from: try JSONEncoder().encode(original))
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.coverage.count, CoarseZone.allCases.count)
        XCTAssertTrue(decoded.cameraVerified)
        XCTAssertEqual(decoded.guidanceMode, .camera)
    }

    func testCoverageRoundTripEmpty() throws {
        let original = enriched(active: 30, target: 120, coverage: [:])
        let decoded = try JSONDecoder().decode(BrushingRecord.self,
                                               from: try JSONEncoder().encode(original))
        XCTAssertEqual(decoded, original)
        XCTAssertTrue(decoded.coverage.isEmpty)
    }

    func testLegacyJSONDecodesWithDefaults() throws {
        // Old-shape record (pre-enrichment) must decode without crashing, new fields defaulted.
        let id = UUID(), profile = UUID()
        let start = Date(timeIntervalSince1970: 1_000_000)
        let end = start.addingTimeInterval(90)
        let json = """
        {"id":"\(id.uuidString)","profileID":"\(profile.uuidString)",\
        "startDate":\(start.timeIntervalSinceReferenceDate),\
        "endDate":\(end.timeIntervalSinceReferenceDate)}
        """
        let decoded = try JSONDecoder().decode(BrushingRecord.self, from: Data(json.utf8))
        XCTAssertEqual(decoded.id, id)
        XCTAssertEqual(decoded.targetSeconds, 120)        // default
        XCTAssertFalse(decoded.cameraVerified)            // default
        XCTAssertEqual(decoded.guidanceMode, .fallbackTimed)
        XCTAssertTrue(decoded.coverage.isEmpty)
        XCTAssertEqual(decoded.activeSeconds, 90)         // falls back to duration
    }
}
