import XCTest
@testable import ToothBuddyCore

final class BrushingRecordTests: XCTestCase {
    private func record(durationSeconds: Int) -> BrushingRecord {
        let start = Date(timeIntervalSince1970: 1_000_000)
        return BrushingRecord(startDate: start,
                              endDate: start.addingTimeInterval(TimeInterval(durationSeconds)))
    }

    func testDurationSeconds() {
        XCTAssertEqual(record(durationSeconds: 90).durationSeconds, 90)
    }

    func testDurationNeverNegative() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        let r = BrushingRecord(startDate: start, endDate: start.addingTimeInterval(-50))
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
}
