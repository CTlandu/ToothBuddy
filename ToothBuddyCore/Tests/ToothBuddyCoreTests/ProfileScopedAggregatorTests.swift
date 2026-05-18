import XCTest
@testable import ToothBuddyCore

/// Spec 02 §6.3 / AC2 (isolation) + AC3 (per-profile streak independence).
final class ProfileScopedAggregatorTests: XCTestCase {
    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()
    private var base: Date { DateComponents(calendar: cal, year: 2026, month: 5, day: 18).date! }
    private func day(_ n: Int) -> Date { cal.date(byAdding: .day, value: n, to: base)! }
    private var now: Date { cal.date(byAdding: .hour, value: 10, to: base)! }
    private func rec(_ pid: UUID, _ n: Int) -> BrushingRecord {
        let start = cal.date(byAdding: .hour, value: 9, to: day(n))!
        return BrushingRecord(profileID: pid, startDate: start, endDate: start.addingTimeInterval(130))
    }

    func testRecordsAreFilteredByProfile() {
        let a = UUID(), b = UUID()
        let all = [rec(a, 0), rec(a, -1), rec(b, 0)]
        XCTAssertEqual(ProfileScopedAggregator.records(for: a, in: all).count, 2)
        XCTAssertEqual(ProfileScopedAggregator.records(for: b, in: all).count, 1)
        XCTAssertTrue(ProfileScopedAggregator.records(for: UUID(), in: all).isEmpty)
    }

    // AC3: A's missed day must not reset B's streak.
    func testPerProfileStreaksAreIndependent() {
        let a = UUID(), b = UUID()
        // A: only today (streak 1). B: 10 unbroken days incl. today (streak 10).
        var all = [rec(a, 0)]
        all += (-9...0).map { rec(b, $0) }

        let sa = ProfileScopedAggregator.streak(for: a, in: all, now: now,
                                                config: .default, calendar: cal)
        let sb = ProfileScopedAggregator.streak(for: b, in: all, now: now,
                                                config: .default, calendar: cal)
        XCTAssertEqual(sa.currentStreak, 1)
        XCTAssertEqual(sb.currentStreak, 10)
    }
}
