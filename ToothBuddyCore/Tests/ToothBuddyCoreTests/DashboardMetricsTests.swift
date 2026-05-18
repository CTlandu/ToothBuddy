import XCTest
@testable import ToothBuddyCore

/// Spec 02 §6.5 / AC8 — dashboard metrics match the engines, isolated per profile.
final class DashboardMetricsTests: XCTestCase {
    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()
    private var base: Date { DateComponents(calendar: cal, year: 2026, month: 5, day: 18).date! }
    private func day(_ n: Int) -> Date { cal.date(byAdding: .day, value: n, to: base)! }
    private var now: Date { cal.date(byAdding: .hour, value: 10, to: base)! }
    private func rec(_ pid: UUID, _ n: Int, hour: Int = 9) -> BrushingRecord {
        let s = cal.date(byAdding: .hour, value: hour, to: day(n))!
        return BrushingRecord(profileID: pid, startDate: s, endDate: s.addingTimeInterval(130))
    }
    private func compute(_ pid: UUID, _ all: [BrushingRecord]) -> DashboardMetric {
        DashboardMetrics.compute(profileID: pid, in: all, now: now,
                                 config: .default, calendar: cal)
    }

    func testEmpty() {
        let m = compute(UUID(), [])
        XCTAssertFalse(m.didMorningToday)
        XCTAssertFalse(m.didEveningToday)
        XCTAssertEqual(m.currentStreak, 0)
        XCTAssertEqual(m.longestStreak, 0)
        XCTAssertEqual(m.last7DaysActive, 0)
        XCTAssertEqual(m.weeklyTrend, [0, 0, 0, 0])
        XCTAssertTrue(m.missedYesterday)
    }

    func testTodaySlots() {
        let p = UUID()
        let m = compute(p, [rec(p, 0, hour: 9), rec(p, 0, hour: 20)])
        XCTAssertTrue(m.didMorningToday)
        XCTAssertTrue(m.didEveningToday)
    }

    func testTrendStreakAndMissedYesterday() {
        let p = UUID()
        // Active on offsets 0, -1, -6, -7, -14, -21.
        let all = [0, -1, -6, -7, -14, -21].map { rec(p, $0) }
        let m = compute(p, all)
        // Blocks oldest→newest end at -21, -14, -7, 0.
        XCTAssertEqual(m.weeklyTrend, [1, 1, 1, 3])
        XCTAssertEqual(m.last7DaysActive, 3)
        XCTAssertFalse(m.missedYesterday)            // -1 is active
        // qual-day segments → current run [-1,0] = 2; longest segment = 2.
        XCTAssertEqual(m.currentStreak, 2)
        XCTAssertEqual(m.longestStreak, 2)
    }

    func testMissedYesterdayWhenNoActivityYesterday() {
        let p = UUID()
        let m = compute(p, [rec(p, 0)])              // only today
        XCTAssertTrue(m.missedYesterday)
    }

    func testIsolationOnlyCountsTargetProfile() {
        let a = UUID(), b = UUID()
        let all = [rec(a, 0), rec(b, 0), rec(b, -1), rec(b, -2)]
        let ma = compute(a, all)
        XCTAssertEqual(ma.last7DaysActive, 1)        // only A's single day
        XCTAssertEqual(ma.currentStreak, 1)
    }
}
