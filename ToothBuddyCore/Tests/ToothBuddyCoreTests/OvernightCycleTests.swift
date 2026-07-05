import XCTest
@testable import ToothBuddyCore

/// U4 — overnight send-off → next-morning greeting (the hook to brush), with calendar edges.
/// The greeting fires on a new calendar day after an evening send-off — it does NOT require a
/// morning brush first (that's the pull *to* brush; the reward is earned by the brush itself).
final class OvernightCycleTests: XCTestCase {

    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()
    private let pid = UUID()
    private var baseDay: Date { DateComponents(calendar: cal, year: 2026, month: 7, day: 3).date! }
    private func day(_ n: Int) -> Date { cal.date(byAdding: .day, value: n, to: baseDay)! }
    private func at(_ n: Int, _ hour: Int) -> Date { cal.date(byAdding: .hour, value: hour, to: day(n))! }

    /// A qualifying (metMinimum) brush on day `n` at `hour`.
    private func met(_ n: Int, _ hour: Int) -> BrushingRecord {
        let coverage = Dictionary(uniqueKeysWithValues: CoarseZone.allCases.map { ($0, 120) })
        return BrushingRecord(profileID: pid, startDate: at(n, hour),
                              endDate: at(n, hour).addingTimeInterval(130),
                              activeSeconds: 120, targetSeconds: 120, coverage: coverage)
    }

    private func state(_ records: [BrushingRecord], lastReveal: Date? = nil, now: Date? = nil) -> OvernightState {
        OvernightCycle.state(records: records, lastReveal: lastReveal,
                             now: now ?? at(0, 8), calendar: cal)  // default "now" = this morning 08:00
    }

    func testGreetsMorningAfterEveningSendoff() {
        // Evening brush yesterday; this morning, BEFORE brushing, Buddy greets you.
        let s = state([met(-1, 20)])
        XCTAssertTrue(s.isSentOff)
        XCTAssertTrue(s.revealAvailable)
    }

    func testAfterMidnightCountsAsNewDay() {
        // Evening send at day -1 21:00, app opened at 00:xx on day 0 → new calendar day → greet.
        let s = state([met(-1, 21)], now: at(0, 0))
        XCTAssertTrue(s.revealAvailable)
    }

    func testNoEveningIsIdle() {
        // Only a morning brush ever → nothing was sent off → no greeting.
        let s = state([met(0, 8)])
        XCTAssertEqual(s, .idle)
    }

    func testGreetedTodayGoesIdle() {
        let s = state([met(-1, 20)], lastReveal: at(0, 7))  // already greeted this morning
        XCTAssertEqual(s, .idle)
    }

    func testSameEveningWaitsForTomorrow() {
        // Brushed this evening → Buddy is out for tonight; no greeting until a new day.
        let s = state([met(0, 20)], now: at(0, 22))
        XCTAssertTrue(s.isSentOff)
        XCTAssertFalse(s.revealAvailable)
    }

    func testWelcomeBackAfterGap() {
        // Evening send-off, then a multi-day gap, then app-open → welcome-back greeting.
        let s = state([met(-3, 20)])
        XCTAssertTrue(s.revealAvailable)
    }

    func testGreetingDoesNotRequireAMorningBrush() {
        // Explicit: no brush at all today, only last night's evening brush → greeting still fires.
        let s = state([met(-1, 21)])
        XCTAssertTrue(s.revealAvailable)
    }
}
