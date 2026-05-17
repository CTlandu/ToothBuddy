import XCTest
@testable import ToothBuddyCore

/// Maps 1:1 to Spec 01 §8 acceptance criteria and §7 edge cases.
final class StreakEngineTests: XCTestCase {

    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()
    private let config = StreakConfig.default          // boundary 12, grace 7, active

    /// Anchor "today" = 2026-05-18 00:00 UTC. `day(n)` offsets by n days.
    private var base: Date {
        DateComponents(calendar: cal, year: 2026, month: 5, day: 18).date!
    }
    private func day(_ n: Int) -> Date { cal.date(byAdding: .day, value: n, to: base)! }

    /// One active session (130s ≥ 2 min) on day offset `n` at `hour`.
    private func rec(_ n: Int, hour: Int = 9) -> BrushingRecord {
        let start = cal.date(byAdding: .hour, value: hour, to: day(n))!
        return BrushingRecord(startDate: start, endDate: start.addingTimeInterval(130))
    }
    /// `now` = today (offset 0) at 10:00.
    private var now: Date { cal.date(byAdding: .hour, value: 10, to: base)! }

    private func evaluate(_ records: [BrushingRecord], now: Date? = nil,
                          config: StreakConfig? = nil) -> StreakResult {
        StreakEngine.evaluate(records: records, now: now ?? self.now,
                              config: config ?? self.config, calendar: cal)
    }

    // AC1 / E1
    func testAC1_tenUnbrokenDays() {
        let r = (-9...0).map { rec($0) }
        let s = evaluate(r)
        XCTAssertEqual(s.currentStreak, 10)
        XCTAssertEqual(s.longestStreak, 10)
        XCTAssertEqual(s.frozenDays, [])
        XCTAssertFalse(s.isTodayPending)
    }

    // AC2 / E2 — 20 active, 1 missed (day -1), today active.
    func testAC2_oneMissedBridged() {
        var r = (-21 ... -2).map { rec($0) }   // 20 days
        r.append(rec(0))                        // today
        let s = evaluate(r)
        XCTAssertEqual(s.currentStreak, 21)
        XCTAssertEqual(s.frozenDays, [day(-1)])
        XCTAssertFalse(s.isTodayPending)
        XCTAssertGreaterThanOrEqual(s.longestStreak, 21)
    }

    // AC3 / E3 — two consecutive missed days sever the older run.
    func testAC3_twoConsecutiveMissedReset() {
        var r = (-17 ... -13).map { rec($0) }   // 5 active
        r += (-10 ... -1).map { rec($0) }       // 10 active (days -12,-11 missed)
        r.append(rec(0))                         // today
        let s = evaluate(r)
        XCTAssertEqual(s.currentStreak, 11)
        XCTAssertEqual(s.frozenDays, [])
        XCTAssertEqual(s.longestStreak, 11)
    }

    // AC3b / E4 — budget trim drops the older 2 + the miss.
    func testAC3b_budgetTrim() {
        let r = [rec(-6), rec(-5), rec(-3), rec(-2), rec(-1), rec(0)] // miss = day -4
        let s = evaluate(r)
        XCTAssertEqual(s.currentStreak, 4)
        XCTAssertEqual(s.frozenDays, [])
    }

    // AC4 — longest preserved across a reset.
    func testAC4_longestAcrossReset() {
        var r = (-35 ... -6).map { rec($0) }     // 30 active
        r += [rec(-3), rec(-2), rec(-1), rec(0)] // days -5,-4 missed → hard break
        let s = evaluate(r)
        XCTAssertEqual(s.longestStreak, 30)
        XCTAssertEqual(s.currentStreak, 4)
    }

    // AC5 — today not brushed yet, yesterday-anchored run of 5.
    func testAC5_todayPending() {
        let r = (-5 ... -1).map { rec($0) }      // no record for day 0
        let s = evaluate(r)
        XCTAssertEqual(s.currentStreak, 5)
        XCTAssertTrue(s.isTodayPending)
    }

    // AC6 — requirePerfectDay parameter path.
    func testAC6_requirePerfectDay() {
        let perfect = StreakConfig(slotBoundaryHour: 12, gracePeriod: 7, requirePerfectDay: true)
        let morningOnly = evaluate([rec(0, hour: 9)], config: perfect)
        XCTAssertEqual(morningOnly.currentStreak, 0)
        let both = evaluate([rec(0, hour: 9), rec(0, hour: 20)], config: perfect)
        XCTAssertEqual(both.currentStreak, 1)
    }

    // AC12 — DST boundary day (US spring-forward 2026-03-08).
    func testAC12_dstBoundary() {
        var ny = Calendar(identifier: .gregorian)
        ny.timeZone = TimeZone(identifier: "America/New_York")!
        let dstBase = DateComponents(calendar: ny, year: 2026, month: 3, day: 9).date! // day after spring-forward
        func d(_ n: Int) -> Date { ny.date(byAdding: .day, value: n, to: dstBase)! }
        func r(_ n: Int) -> BrushingRecord {
            let s = ny.date(byAdding: .hour, value: 9, to: d(n))!
            return BrushingRecord(startDate: s, endDate: s.addingTimeInterval(130))
        }
        let nowNY = ny.date(byAdding: .hour, value: 10, to: dstBase)!
        let result = StreakEngine.evaluate(records: [r(-2), r(-1), r(0)],
                                           now: nowNY,
                                           config: .default, calendar: ny)
        XCTAssertEqual(result.currentStreak, 3) // spans the DST transition without miscount
    }

    // AC14 — 5000 records evaluate well under 50 ms.
    func testAC14_performanceLargeHistory() {
        var r: [BrushingRecord] = []
        for n in 0..<2500 {                      // 2 sessions/day, 2500 days, ending today
            r.append(rec(-n, hour: 9))
            r.append(rec(-n, hour: 20))
        }
        let start = Date()
        let s = evaluate(r)
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertEqual(s.currentStreak, 2500)
        XCTAssertLessThan(elapsed, 0.05, "evaluate took \(elapsed)s, expected < 0.05s")
    }

    // §7 edge cases
    func testEdge1_noRecords() {
        XCTAssertEqual(evaluate([]), .empty)
    }

    func testEdge2_onlyTodayOneSession() {
        let s = evaluate([rec(0)])
        XCTAssertEqual(s.currentStreak, 1)
        XCTAssertFalse(s.isTodayPending)
    }

    func testEdge3_multipleSessionsSameDayCountOnce() {
        let s = evaluate([rec(-1, hour: 8), rec(-1, hour: 20), rec(0, hour: 9)])
        XCTAssertEqual(s.currentStreak, 2)
    }

    func testEdge5_clockMovedBackIgnoresFuture() {
        // A record dated in the "future" relative to now must not break or inflate the streak.
        let s = evaluate([rec(0), rec(5)])       // day +5 is future vs now (today 10:00)
        XCTAssertEqual(s.currentStreak, 1)
        XCTAssertGreaterThanOrEqual(s.longestStreak, 1)
    }

    func testEdge_neitherTodayNorYesterdayResetsToZero() {
        // Long past streak but the last two days (incl. today) missed → broken.
        let r = (-10 ... -3).map { rec($0) }
        let s = evaluate(r)
        XCTAssertEqual(s.currentStreak, 0)
        XCTAssertFalse(s.isTodayPending)
        XCTAssertEqual(s.longestStreak, 8)
    }
}
