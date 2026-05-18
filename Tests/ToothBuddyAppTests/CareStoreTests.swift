import XCTest
import CoreData
import ToothBuddyCore
@testable import ToothBuddy

/// Spec 02 §6.6 / AC10 (app side) — defaults + "Mark done" resets the anchor.
@MainActor
final class CareStoreTests: XCTestCase {

    private func stores() -> (ProfileStore, CareStore, UUID) {
        UserDefaults.standard.set(true, forKey: "ToothBuddy.didMigrateToCoreData_v1")
        let pc = PersistenceController(inMemory: true)
        let ps = ProfileStore(controller: pc)
        let cs = CareStore(controller: pc, profiles: ps)
        let p = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        return (ps, cs, p.id)
    }

    func testNoBaselineByDefault() {
        let (_, cs, pid) = stores()
        XCTAssertEqual(cs.status(pid, .brushHead), .noBaseline)
        XCTAssertEqual(cs.status(pid, .dentist), .noBaseline)
    }

    func testMarkDoneSetsAnchorAndResetsCountdown() {
        let (_, cs, pid) = stores()
        cs.markDone(pid, .brushHead)
        let s = cs.status(pid, .brushHead)
        XCTAssertFalse(s.isDue)                       // just reset → not due
        XCTAssertNotNil(s.dueDate)
        // ~90 days out (allow 89/90 for start-of-day rounding).
        XCTAssertTrue([89, 90].contains(s.daysRemaining ?? -1),
                      "daysRemaining was \(String(describing: s.daysRemaining))")
    }

    func testCareInputsReflectDefaults() {
        let (_, cs, pid) = stores()
        let inputs = cs.careInputs()
        let mine = inputs.first { $0.profileID == pid }
        XCTAssertEqual(mine?.brushHeadIntervalDays, 90)
        XCTAssertEqual(mine?.dentistIntervalDays, 180)
        XCTAssertNil(mine?.brushHeadAnchor)
    }
}
