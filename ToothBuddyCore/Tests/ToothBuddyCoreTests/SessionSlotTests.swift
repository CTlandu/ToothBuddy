import XCTest
@testable import ToothBuddyCore

final class SessionSlotTests: XCTestCase {
    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    // AC7 — boundary 12: 11:59 → morning, 12:00 → evening.
    func testBoundaryMapping() {
        XCTAssertEqual(SessionSlot(hour: 0, boundaryHour: 12), .morning)
        XCTAssertEqual(SessionSlot(hour: 11, boundaryHour: 12), .morning)
        XCTAssertEqual(SessionSlot(hour: 12, boundaryHour: 12), .evening)
        XCTAssertEqual(SessionSlot(hour: 23, boundaryHour: 12), .evening)
    }

    func testSlotForDate() {
        let base = DateComponents(calendar: cal, year: 2026, month: 5, day: 18, hour: 11, minute: 59)
        XCTAssertEqual(SessionSlot.slot(for: base.date!, boundaryHour: 12, calendar: cal), .morning)
        let noon = DateComponents(calendar: cal, year: 2026, month: 5, day: 18, hour: 12, minute: 0)
        XCTAssertEqual(SessionSlot.slot(for: noon.date!, boundaryHour: 12, calendar: cal), .evening)
    }
}
