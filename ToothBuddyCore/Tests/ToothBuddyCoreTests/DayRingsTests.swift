import XCTest
@testable import ToothBuddyCore

/// U2 — two-ring/day + weekly progress.
final class DayRingsTests: XCTestCase {

    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()
    private let pid = UUID()
    private var base: Date { DateComponents(calendar: cal, year: 2026, month: 7, day: 3).date! }
    private func day(_ n: Int) -> Date { cal.date(byAdding: .day, value: n, to: base)! }
    private var now: Date { cal.date(byAdding: .hour, value: 14, to: base)! } // today 14:00

    /// A qualifying (metMinimum) session on day `n` at `hour`.
    private func met(_ n: Int, hour: Int) -> BrushingRecord {
        let start = cal.date(byAdding: .hour, value: hour, to: day(n))!
        let coverage = Dictionary(uniqueKeysWithValues: CoarseZone.allCases.map { ($0, 120) })
        return BrushingRecord(profileID: pid, startDate: start,
                              endDate: start.addingTimeInterval(130),
                              activeSeconds: 120, targetSeconds: 120, coverage: coverage)
    }

    /// A below-goal session (does not close a ring).
    private func short(_ n: Int, hour: Int) -> BrushingRecord {
        let start = cal.date(byAdding: .hour, value: hour, to: day(n))!
        return BrushingRecord(profileID: pid, startDate: start,
                              endDate: start.addingTimeInterval(40),
                              activeSeconds: 40, targetSeconds: 120)
    }

    func testAmOnly() {
        let s = DayRings.today(records: [met(0, hour: 8)], now: now, calendar: cal)
        XCTAssertTrue(s.amClosed)
        XCTAssertFalse(s.pmClosed)
        XCTAssertFalse(s.isPerfectDay)
    }

    func testPerfectDay() {
        let s = DayRings.today(records: [met(0, hour: 8), met(0, hour: 20)], now: now, calendar: cal)
        XCTAssertTrue(s.isPerfectDay)
    }

    func testSlotBoundaryNoonSplit() {
        // 11:00 → AM, 12:00 → PM (boundary hour 12).
        let amState = DayRings.today(records: [met(0, hour: 11)], now: now, calendar: cal)
        let pmState = DayRings.today(records: [met(0, hour: 12)], now: now, calendar: cal)
        XCTAssertTrue(amState.amClosed); XCTAssertFalse(amState.pmClosed)
        XCTAssertTrue(pmState.pmClosed); XCTAssertFalse(pmState.amClosed)
    }

    func testBelowGoalDoesNotCloseRing() {
        let s = DayRings.today(records: [short(0, hour: 8)], now: now, calendar: cal)
        XCTAssertFalse(s.amClosed)
    }

    func testEmpty() {
        let s = DayRings.today(records: [], now: now, calendar: cal)
        XCTAssertFalse(s.amClosed); XCTAssertFalse(s.pmClosed)
        let w = DayRings.weekProgress(records: [], now: now, calendar: cal)
        XCTAssertEqual(w, WeekProgress(closed: 0, total: 14))
    }

    func testWeekProgressCountsDistinctSlots() {
        // 3 full days (both slots) + today AM = 7 closed slots; a duplicate AM doesn't double-count.
        var r = [met(-2, hour: 8), met(-2, hour: 20),
                 met(-1, hour: 8), met(-1, hour: 20),
                 met(-3, hour: 8), met(-3, hour: 20),
                 met(0, hour: 8), met(0, hour: 9)]        // two AM sessions today = one slot
        r.append(short(0, hour: 10))                       // below goal, ignored
        let w = DayRings.weekProgress(records: r, now: now, calendar: cal)
        XCTAssertEqual(w.closed, 7)
        XCTAssertEqual(w.total, 14)
    }

    func testWeekProgressExcludesOlderThanSevenDays() {
        let w = DayRings.weekProgress(records: [met(-7, hour: 8), met(0, hour: 8)], now: now, calendar: cal)
        XCTAssertEqual(w.closed, 1) // day -7 is outside the trailing 7-day window
    }
}
