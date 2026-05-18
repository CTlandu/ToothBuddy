import XCTest
@testable import ToothBuddyCore

/// Spec 03 §5.4 / AC6.
final class CourseProgressionTests: XCTestCase {

    func testLibraryIntegrity() {
        let all = CourseLibrary.all
        XCTAssertFalse(all.isEmpty)
        XCTAssertEqual(all.map(\.id), Array(1...all.count))          // 1-based, ordered
        XCTAssertTrue(all.allSatisfy { !$0.title.isEmpty && !$0.body.isEmpty })
    }

    func testUnlockSchedule() {
        let total = 8
        XCTAssertEqual(CourseProgression.unlockedCount(activeDays: 0, totalLessons: total), 1)
        XCTAssertEqual(CourseProgression.unlockedCount(activeDays: 1, totalLessons: total), 1)
        XCTAssertEqual(CourseProgression.unlockedCount(activeDays: 2, totalLessons: total), 2)
        XCTAssertEqual(CourseProgression.unlockedCount(activeDays: 3, totalLessons: total), 2)
        XCTAssertEqual(CourseProgression.unlockedCount(activeDays: 4, totalLessons: total), 3)
    }

    func testCapsAtTotalAndHandlesEdges() {
        XCTAssertEqual(CourseProgression.unlockedCount(activeDays: 9999, totalLessons: 8), 8)
        XCTAssertEqual(CourseProgression.unlockedCount(activeDays: -5, totalLessons: 8), 1)
        XCTAssertEqual(CourseProgression.unlockedCount(activeDays: 10, totalLessons: 0), 0)
    }
}
