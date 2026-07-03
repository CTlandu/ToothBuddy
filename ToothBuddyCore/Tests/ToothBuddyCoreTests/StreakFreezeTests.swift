import XCTest
@testable import ToothBuddyCore

/// U3 — the earned/spent freeze economy over StreakEngine.
final class StreakFreezeTests: XCTestCase {

    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()
    private let config = StreakConfig.default
    private let pid = UUID()
    private var base: Date { DateComponents(calendar: cal, year: 2026, month: 7, day: 3).date! }
    private func day(_ n: Int) -> Date { cal.date(byAdding: .day, value: n, to: base)! }
    private func rec(_ n: Int, hour: Int = 9) -> BrushingRecord {
        let start = cal.date(byAdding: .hour, value: hour, to: day(n))!
        return BrushingRecord(profileID: pid, startDate: start, endDate: start.addingTimeInterval(130))
    }
    private var now: Date { cal.date(byAdding: .hour, value: 10, to: base)! }

    private func eval(_ records: [BrushingRecord]) -> FreezeState {
        StreakFreeze.evaluate(records: records, now: now, config: config, calendar: cal)
    }

    func testEmpty() {
        XCTAssertEqual(eval([]), .empty)
    }

    func testShortStreakEarnsNothing() {
        let s = eval((-4...0).map { rec($0) })   // 5-day streak
        XCTAssertEqual(s.earnedTotal, 0)
        XCTAssertEqual(s.balance, 0)
    }

    func testSevenDayStreakEarnsOne() {
        let s = eval((-6...0).map { rec($0) })   // 7-day streak
        XCTAssertEqual(s.earnedTotal, 1)
        XCTAssertEqual(s.balance, 1)
        XCTAssertEqual(s.savedDays, [])
    }

    func testBalanceCapsAtTwo() {
        let s = eval((-20...0).map { rec($0) })  // 21-day streak → earned 3, capped balance 2
        XCTAssertEqual(s.earnedTotal, 3)
        XCTAssertEqual(s.balance, 2)
    }

    func testBridgedMissedDayIsSavedAndSpends() {
        // 20 active days, day -1 missed, today active → streak bridges the gap (AC2 shape).
        var r = (-21 ... -2).map { rec($0) }
        r.append(rec(0))
        let s = eval(r)
        XCTAssertEqual(s.savedDays, [day(-1)])          // the bridged day is surfaced
        XCTAssertEqual(s.earnedTotal, 3)                // longest ≥ 21 → 21/7 = 3
        XCTAssertEqual(s.balance, 2)                    // min(cap 2, 3 - 1 spent) = 2
    }
}
