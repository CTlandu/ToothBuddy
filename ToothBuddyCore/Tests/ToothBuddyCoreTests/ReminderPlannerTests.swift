import XCTest
@testable import ToothBuddyCore

/// Maps 1:1 to Spec 01 §8 AC8–AC11 and edge case 9.
final class ReminderPlannerTests: XCTestCase {

    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()
    private let cfg = ReminderConfig.default

    private var base: Date { DateComponents(calendar: cal, year: 2026, month: 5, day: 18).date! }
    private func day(_ n: Int) -> Date { cal.date(byAdding: .day, value: n, to: base)! }
    /// Session on day offset `n` at h:m.
    private func rec(_ n: Int, _ h: Int, _ m: Int = 0) -> BrushingRecord {
        var dc = cal.dateComponents([.year, .month, .day], from: day(n))
        dc.hour = h; dc.minute = m
        let start = cal.date(from: dc)!
        return BrushingRecord(profileID: pid, startDate: start, endDate: start.addingTimeInterval(130))
    }
    private let pid = UUID()
    private func nowAt(_ h: Int, _ m: Int = 0) -> Date {
        var dc = cal.dateComponents([.year, .month, .day], from: base)
        dc.hour = h; dc.minute = m
        return cal.date(from: dc)!
    }
    private func plan(_ records: [BrushingRecord], now: Date,
                      streak: StreakResult = StreakResult(currentStreak: 5, longestStreak: 5,
                                                          frozenDays: [], isTodayPending: false))
        -> [PlannedReminder] {
        ReminderPlanner.plan(ReminderPlanInput(records: records, now: now, streak: streak, config: cfg),
                             calendar: cal)
    }
    private func fire(_ p: PlannedReminder) -> (h: Int, m: Int) {
        let c = cal.dateComponents([.hour, .minute], from: p.fireDate)
        return (c.hour ?? -1, c.minute ?? -1)
    }

    // AC8 — morning logged today → no morningRoutine.
    func testAC8_morningLoggedSuppressesMorning() {
        let p = plan([rec(0, 7)], now: nowAt(6))   // logged at 07:00; now 06:00
        XCTAssertFalse(p.contains { $0.kind == .morningRoutine })
    }

    // AC8 — none logged, insufficient history → morningRoutine at default 08:00.
    func testAC8_morningDefaultWhenNoneLogged() {
        let p = plan([], now: nowAt(6))
        guard let m = p.first(where: { $0.kind == .morningRoutine }) else {
            return XCTFail("expected morningRoutine")
        }
        XCTAssertEqual(fire(m).h, 8)
        XCTAssertEqual(fire(m).m, 0)
    }

    // AC9 — any session today → no streakAtRisk.
    func testAC9_sessionTodaySuppressesRisk() {
        let p = plan([rec(0, 9)], now: nowAt(10))
        XCTAssertFalse(p.contains { $0.kind == .streakAtRisk })
    }

    // AC9 — streak == 0 → no streakAtRisk.
    func testAC9_zeroStreakSuppressesRisk() {
        let p = plan([], now: nowAt(10),
                     streak: StreakResult(currentStreak: 0, longestStreak: 0,
                                          frozenDays: [], isTodayPending: false))
        XCTAssertFalse(p.contains { $0.kind == .streakAtRisk })
    }

    // AC10 — evening (default 20:30) and risk (20:30) within 60 min → evening dropped.
    func testAC10_collisionDropsEvening() {
        let p = plan([], now: nowAt(10))           // no sessions today, streak 5
        XCTAssertTrue(p.contains { $0.kind == .streakAtRisk })
        XCTAssertFalse(p.contains { $0.kind == .eveningRoutine })
    }

    // AC11 — ≥ minHistory evening sessions clustered ~21:10 → eveningRoutine ≈ 21:10.
    // streak 0 isolates the adaptive-time path (no streakAtRisk → no AC10 collision).
    private let noStreak = StreakResult(currentStreak: 0, longestStreak: 0,
                                        frozenDays: [], isTodayPending: false)

    func testAC11_adaptiveEvening() {
        let r = [rec(-3, 21, 8), rec(-2, 21, 10), rec(-1, 21, 12)] // median 21:10
        let p = plan(r, now: nowAt(10), streak: noStreak)
        guard let e = p.first(where: { $0.kind == .eveningRoutine }) else {
            return XCTFail("expected eveningRoutine")
        }
        XCTAssertEqual(fire(e).h, 21)
        XCTAssertTrue((9...11).contains(fire(e).m), "minute was \(fire(e).m)")
    }

    // AC11 — below minHistory evening sessions → default 20:30.
    func testAC11_belowMinHistoryUsesDefault() {
        let r = [rec(-1, 21, 10), rec(-2, 21, 10)] // only 2 < minHistory(3)
        let p = plan(r, now: nowAt(10), streak: noStreak)
        guard let e = p.first(where: { $0.kind == .eveningRoutine }) else {
            return XCTFail("expected eveningRoutine")
        }
        XCTAssertEqual(fire(e).h, 20)
        XCTAssertEqual(fire(e).m, 30)
    }

    // Edge 9 — reminder time already passed → skipped (not fired immediately).
    func testEdge9_pastTimeSkipped() {
        let p = plan([], now: nowAt(22))           // 22:00 — both 08:00 and 20:30 are in the past
        XCTAssertFalse(p.contains { $0.kind == .morningRoutine })
        XCTAssertFalse(p.contains { $0.kind == .eveningRoutine })
        XCTAssertFalse(p.contains { $0.kind == .streakAtRisk })
    }
}
