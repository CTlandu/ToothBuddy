import XCTest
@testable import ToothBuddyCore

/// Spec 02 §6.7 / AC11 — report is range-correct, profile-isolated, deterministic.
final class ReportBuilderTests: XCTestCase {
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
    private func build(_ pid: UUID, _ all: [BrushingRecord], _ start: Date, _ end: Date) -> ReportData {
        ReportBuilder.build(profileID: pid, profileName: "Mia", in: all,
                            start: start, end: end, now: now,
                            config: .default, calendar: cal)
    }

    func testRangeIsolationCountsAndGrid() {
        let p = UUID(), q = UUID()
        let all = [
            rec(p, 0, hour: 9),
            rec(p, -1, hour: 9), rec(p, -1, hour: 20),   // perfect day
            rec(p, -6, hour: 9),
            rec(p, -10, hour: 9),                         // out of range
            rec(q, 0, hour: 9)                            // other profile
        ]
        let r = build(p, all, day(-6), day(0))
        XCTAssertEqual(r.totalSessions, 4)               // p, in [-6,0] only
        XCTAssertEqual(r.totalDays, 7)
        XCTAssertEqual(r.days.count, 7)
        XCTAssertEqual(r.activeDays, 3)                   // days 0, -1, -6
        XCTAssertEqual(r.completionPercent, 43)          // round(3/7*100)
        XCTAssertEqual(r.currentStreak, 2)               // segment [-1,0]
        XCTAssertEqual(r.longestStreak, 2)

        let cellMinus1 = r.days.first { $0.date == day(-1) }
        XCTAssertEqual(cellMinus1?.active, true)
        XCTAssertEqual(cellMinus1?.perfect, true)
        let cell0 = r.days.first { $0.date == day(0) }
        XCTAssertEqual(cell0?.perfect, false)            // morning only
        XCTAssertEqual(r.days.first { $0.date == day(-2) }?.active, false)
    }

    func testReversedRangeTolerated() {
        let p = UUID()
        let r = build(p, [rec(p, -3)], day(0), day(-6))  // start > end
        XCTAssertEqual(r.start, day(-6))
        XCTAssertEqual(r.end, day(0))
        XCTAssertEqual(r.totalDays, 7)
    }

    func testEmpty() {
        let r = build(UUID(), [], day(-6), day(0))
        XCTAssertEqual(r.totalSessions, 0)
        XCTAssertFalse(r.hasData)                          // U5 — drives the empty-state page
        XCTAssertEqual(r.activeDays, 0)
        XCTAssertEqual(r.totalDays, 7)
        XCTAssertEqual(r.completionPercent, 0)
        XCTAssertEqual(r.currentStreak, 0)
        XCTAssertEqual(r.thoroughSessions, 0)
        XCTAssertEqual(r.verifiedSessions, 0)
        XCTAssertEqual(r.avgActiveSeconds, 0)
        XCTAssertTrue(r.days.allSatisfy { !$0.active && !$0.thorough })
    }

    func testHasDataTrueEvenForGuidedOnly() {
        let p = UUID()
        // A single guided-only (unverified) session still counts as data.
        let r = build(p, [rec(p, -1)], day(-6), day(0))
        XCTAssertTrue(r.hasData)
        XCTAssertEqual(r.verifiedSessions, 0)              // guided-only count not regressed
    }

    func testQualityTallies() {
        let p = UUID()
        let full = Dictionary(uniqueKeysWithValues: CoarseZone.allCases.map { ($0, 20) })
        func thoroughRec(_ n: Int, verified: Bool) -> BrushingRecord {
            let s = cal.date(byAdding: .hour, value: 9, to: day(n))!
            return BrushingRecord(profileID: p, startDate: s, endDate: s.addingTimeInterval(120),
                                  activeSeconds: 120, targetSeconds: 120, coverage: full,
                                  cameraVerified: verified,
                                  guidanceMode: verified ? .camera : .fallbackTimed)
        }
        let all = [thoroughRec(0, verified: true), thoroughRec(-1, verified: false), rec(p, -2)]
        let r = build(p, all, day(-2), day(0))
        XCTAssertEqual(r.totalSessions, 3)
        XCTAssertEqual(r.thoroughSessions, 2)
        XCTAssertEqual(r.verifiedSessions, 1)
        XCTAssertEqual(r.avgActiveSeconds, (120 + 120 + 130) / 3)   // rec() is a 130s session
        XCTAssertEqual(r.days.first { $0.date == day(0) }?.thorough, true)
        XCTAssertEqual(r.days.first { $0.date == day(-2) }?.thorough, false)  // plain → not thorough
    }
}
