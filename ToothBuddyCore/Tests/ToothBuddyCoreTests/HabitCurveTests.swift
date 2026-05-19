import XCTest
@testable import ToothBuddyCore

/// Spec 05 §6.2 / AC2–AC3 — pure adult habit curve: window length, completed01 values,
/// profile isolation, determinism, and the smoothed adherence (partial at start/end).
final class HabitCurveTests: XCTestCase {
    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()
    private var base: Date { DateComponents(calendar: cal, year: 2026, month: 5, day: 18).date! }
    private func day(_ n: Int) -> Date { cal.date(byAdding: .day, value: n, to: base)! }
    private var asOf: Date { cal.date(byAdding: .hour, value: 13, to: base)! }
    private func rec(_ pid: UUID, _ n: Int, hour: Int) -> BrushingRecord {
        let s = cal.date(byAdding: .hour, value: hour, to: day(n))!
        return BrushingRecord(profileID: pid, startDate: s, endDate: s.addingTimeInterval(130))
    }
    private func pts(_ pid: UUID, _ all: [BrushingRecord], days: Int) -> [HabitCurvePoint] {
        HabitCurve.points(records: all, profileID: pid, asOf: asOf, days: days, calendar: cal)
    }

    func testWindowLengthAndOrderingAndGuard() {
        let p = UUID()
        let out = pts(p, [], days: 7)
        XCTAssertEqual(out.count, 7)
        XCTAssertEqual(out.map(\.date), (-6...0).map { day($0) })          // oldest→newest
        XCTAssertEqual(out.last?.date, cal.startOfDay(for: asOf))           // ends on asOf
        XCTAssertTrue(pts(p, [], days: 0).isEmpty)
        XCTAssertTrue(pts(p, [], days: -3).isEmpty)
    }

    func testCompleted01ValuesPerSlot() {
        let p = UUID()
        let recs = [
            rec(p, 0, hour: 8), rec(p, 0, hour: 20),   // today: perfect → 1.0
            rec(p, -1, hour: 9),                        // yesterday: morning only → 0.5
            rec(p, -2, hour: 21),                       // -2: evening only → 0.5
        ]                                               // -3: nothing → 0.0
        let out = pts(p, recs, days: 4)
        XCTAssertEqual(out.map(\.completed01), [0.0, 0.5, 0.5, 1.0])
        for v in out.map(\.completed01) { XCTAssertTrue([0.0, 0.5, 1.0].contains(v)) }
    }

    func testProfileIsolationAndDeterminism() {
        let p = UUID(), other = UUID()
        let all = [rec(p, 0, hour: 8), rec(other, 0, hour: 8), rec(other, -1, hour: 9)]
        let a = pts(p, all, days: 3)
        XCTAssertEqual(a.map(\.completed01), [0.0, 0.0, 0.5])   // other's records excluded
        XCTAssertEqual(a, pts(p, all, days: 3))                 // deterministic
    }

    func testAdherenceIsClampedTrailingMeanPartialAtStart() {
        let p = UUID()
        // Day -3 perfect (1.0), then nothing. With window 7 the trailing mean at each
        // index includes all prior points (partial window at the start).
        let out = pts(p, [rec(p, -3, hour: 8), rec(p, -3, hour: 20)], days: 4)
        XCTAssertEqual(out.map(\.completed01), [1.0, 0.0, 0.0, 0.0])
        // i0: mean[1.0]=1.0 ; i1: mean[1.0,0]=0.5 ; i2: [1,0,0]=1/3 ; i3:[1,0,0,0]=0.25
        XCTAssertEqual(out[0].adherence, 1.0, accuracy: 1e-9)
        XCTAssertEqual(out[1].adherence, 0.5, accuracy: 1e-9)
        XCTAssertEqual(out[2].adherence, 1.0 / 3.0, accuracy: 1e-9)
        XCTAssertEqual(out[3].adherence, 0.25, accuracy: 1e-9)
        for pt in out { XCTAssertTrue(pt.adherence >= 0 && pt.adherence <= 1) }
    }

    func testAdherenceWindowDropsOldestBeyondWindow() {
        let p = UUID()
        // 8-day window, only the oldest day active. At the last point the 7-day trailing
        // window no longer includes that oldest active day → adherence 0.
        let out = pts(p, [rec(p, -7, hour: 8), rec(p, -7, hour: 20)], days: 8)
        XCTAssertEqual(out.first?.completed01, 1.0)
        XCTAssertEqual(out.last.map(\.adherence) ?? -1, 0.0, accuracy: 1e-9)
    }
}
