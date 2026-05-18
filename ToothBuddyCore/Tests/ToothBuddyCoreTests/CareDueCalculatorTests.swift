import XCTest
@testable import ToothBuddyCore

/// Spec 02 §6.6 / AC10 — care due-date math + reminder planning.
final class CareDueCalculatorTests: XCTestCase {
    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()
    private var base: Date { DateComponents(calendar: cal, year: 2026, month: 5, day: 18).date! }
    private func day(_ n: Int) -> Date { cal.date(byAdding: .day, value: n, to: base)! }
    private var now: Date { cal.date(byAdding: .hour, value: 10, to: base)! }

    func testDefaultIntervals() {
        XCTAssertEqual(CareKind.brushHead.defaultIntervalDays, 90)
        XCTAssertEqual(CareKind.dentist.defaultIntervalDays, 180)
    }

    func testNoBaseline() {
        let s = CareDueCalculator.status(anchor: nil, intervalDays: 90,
                                         now: now, calendar: cal)
        XCTAssertEqual(s, .noBaseline)
        XCTAssertNil(CareDueCalculator.dueDate(anchor: nil, intervalDays: 90, calendar: cal))
    }

    func testDueExactlyIntervalDaysAfterAnchor() {
        let s = CareDueCalculator.status(anchor: day(-90), intervalDays: 90,
                                         now: now, calendar: cal)
        XCTAssertEqual(s.dueDate, day(0))
        XCTAssertTrue(s.isDue)
        XCTAssertEqual(s.daysRemaining, 0)
    }

    func testNotYetDue() {
        let s = CareDueCalculator.status(anchor: day(-89), intervalDays: 90,
                                         now: now, calendar: cal)
        XCTAssertFalse(s.isDue)
        XCTAssertEqual(s.daysRemaining, 1)
    }

    func testOverdue() {
        let s = CareDueCalculator.status(anchor: day(-100), intervalDays: 90,
                                         now: now, calendar: cal)
        XCTAssertTrue(s.isDue)
        XCTAssertEqual(s.daysRemaining, -10)
    }

    func testPlannerSchedulesFutureDueOnly() {
        let p1 = UUID(), p2 = UUID()
        let inputs = [
            ProfileCareInput(profileID: p1, profileName: "Mia",
                             brushHeadAnchor: day(-1), brushHeadIntervalDays: 90,   // due day 89 → future
                             dentistAnchor: nil, dentistIntervalDays: 180),          // no baseline → none
            ProfileCareInput(profileID: p2, profileName: "Leo",
                             brushHeadAnchor: day(-100), brushHeadIntervalDays: 90,  // due day -10 → overdue, skip
                             dentistAnchor: day(-1), dentistIntervalDays: 180)       // due day 179 → future
        ]
        let plan = CareReminderPlanner.plan(inputs, now: now, calendar: cal)
        XCTAssertEqual(plan.count, 2)
        XCTAssertEqual(plan[0].kind, .brushHead)          // day 89 sorts before day 179
        XCTAssertEqual(plan[0].profileName, "Mia")
        XCTAssertEqual(plan[1].kind, .dentist)
        XCTAssertEqual(plan[1].profileID, p2)
        XCTAssertFalse(plan.contains { $0.profileID == p2 && $0.kind == .brushHead })
    }
}
