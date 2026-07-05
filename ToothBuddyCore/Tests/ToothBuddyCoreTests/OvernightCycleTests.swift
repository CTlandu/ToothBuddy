import XCTest
@testable import ToothBuddyCore

/// U4 — overnight send-off / morning reveal, with calendar-boundary edges.
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
                             now: now ?? at(0, 14), calendar: cal)
    }

    func testEveningThenNextMorningReveals() {
        let s = state([met(-1, 20), met(0, 8)])
        XCTAssertTrue(s.isSentOff)
        XCTAssertTrue(s.revealAvailable)
    }

    func testAfterMidnightBrushCountsAsNewDay() {
        // Evening send at day -1 21:00, a 00:xx brush on day 0 → new calendar day → reveal.
        let s = state([met(-1, 21), met(0, 0)])
        XCTAssertTrue(s.revealAvailable)
    }

    func testMorningOnlyNoEveningIsIdle() {
        let s = state([met(0, 8)])
        XCTAssertEqual(s, .idle)
    }

    func testConsumedRevealGoesIdle() {
        let s = state([met(-1, 20), met(0, 8)], lastReveal: at(0, 9))
        XCTAssertEqual(s, .idle)
    }

    func testSentOffWaitingBeforeNewDayBrush() {
        // Evening brush tonight, no later-day brush yet.
        let s = state([met(0, 20)], now: at(0, 22))
        XCTAssertTrue(s.isSentOff)
        XCTAssertFalse(s.revealAvailable)
    }

    func testSameNightSecondBrushIsNotAReveal() {
        // Two evening brushes the same day → no new-day brush → not a reveal.
        let s = state([met(0, 20), met(0, 21)], now: at(0, 22))
        XCTAssertTrue(s.isSentOff)
        XCTAssertFalse(s.revealAvailable)
    }

    func testWelcomeBackAfterGap() {
        // Sent off, then a multi-day gap, then a return brush → intentional welcome-back reveal.
        let s = state([met(-3, 20), met(0, 9)])
        XCTAssertTrue(s.revealAvailable)
    }
}
