import XCTest
@testable import ToothBuddyCore

/// Spec 05 §6.3 / AC7 — the pure per-slot idempotency rule for the quick-log intent.
final class QuickLogTests: XCTestCase {
    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()
    private var base: Date { DateComponents(calendar: cal, year: 2026, month: 5, day: 18).date! }
    private func at(_ dayOffset: Int, hour: Int) -> Date {
        cal.date(byAdding: .hour, value: hour,
                 to: cal.date(byAdding: .day, value: dayOffset, to: base)!)!
    }
    private func rec(_ pid: UUID, _ d: Int, _ h: Int) -> BrushingRecord {
        let s = at(d, hour: h)
        return BrushingRecord(profileID: pid, startDate: s, endDate: s.addingTimeInterval(120))
    }
    private func logged(_ recs: [BrushingRecord], _ pid: UUID, now: Date) -> Bool {
        QuickLog.isCurrentSlotLogged(records: recs, profileID: pid, now: now, calendar: cal)
    }

    func testNoRecordsNotLogged() {
        XCTAssertFalse(logged([], UUID(), now: at(0, hour: 9)))
    }

    func testSameSlotTodayIsLogged() {
        let p = UUID()
        XCTAssertTrue(logged([rec(p, 0, 8)], p, now: at(0, hour: 9)))     // both morning
        XCTAssertTrue(logged([rec(p, 0, 20)], p, now: at(0, hour: 22)))   // both evening
    }

    func testDifferentSlotSameDayNotLogged() {
        let p = UUID()
        XCTAssertFalse(logged([rec(p, 0, 8)], p, now: at(0, hour: 21)))   // AM logged, PM now
    }

    func testDifferentDayNotLogged() {
        let p = UUID()
        XCTAssertFalse(logged([rec(p, -1, 9)], p, now: at(0, hour: 9)))
    }

    func testOtherProfileDoesNotCount() {
        let p = UUID(), other = UUID()
        XCTAssertFalse(logged([rec(other, 0, 8)], p, now: at(0, hour: 9)))
    }
}
