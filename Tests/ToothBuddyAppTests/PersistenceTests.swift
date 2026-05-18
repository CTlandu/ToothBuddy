import XCTest
import CoreData
import ToothBuddyCore
@testable import ToothBuddy

/// App-layer Core Data verification (Spec 02 AC2/AC5-ish). The exhaustive pure-logic
/// suite lives in ToothBuddyCore; this checks the managed-object stack + isolation.
@MainActor
final class PersistenceTests: XCTestCase {

    private func freshStores() -> (PersistenceController, ProfileStore) {
        // Skip the legacy-JSON migration path in tests.
        UserDefaults.standard.set(true, forKey: "ToothBuddy.didMigrateToCoreData_v1")
        let pc = PersistenceController(inMemory: true)
        let ps = ProfileStore(controller: pc)
        return (pc, ps)
    }

    func testCreateAndFetchProfile() {
        let (_, ps) = freshStores()
        XCTAssertTrue(ps.profiles.isEmpty)
        let p = ps.createProfile(name: "  Mia  ", color: .grape, symbol: .heart)
        XCTAssertEqual(p?.name, "Mia")
        XCTAssertEqual(ps.profiles.count, 1)
        XCTAssertEqual(ps.activeProfileID, p?.id)
    }

    func testInvalidNameRejected() {
        let (_, ps) = freshStores()
        XCTAssertNil(ps.createProfile(name: "   ", color: .sky, symbol: .star))
        XCTAssertTrue(ps.profiles.isEmpty)
    }

    func testRecordsAreIsolatedPerProfile() {
        let (pc, ps) = freshStores()
        let a = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        let b = ps.createProfile(name: "B", color: .mint, symbol: .bolt)!

        func addRecord(to id: UUID, _ daysAgo: Int) {
            let cdp = ps.managedProfile(id)!
            let r = CDBrushingRecord(context: pc.viewContext)
            r.id = UUID()
            r.startDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())
            r.endDate = r.startDate?.addingTimeInterval(130)
            r.profile = cdp
        }
        addRecord(to: a.id, 0); addRecord(to: a.id, 1); addRecord(to: b.id, 0)
        try? pc.viewContext.save()

        ps.setActive(a.id)
        let storeA = BrushingStore(controller: pc, profiles: ps)
        XCTAssertEqual(storeA.records.count, 2)

        ps.setActive(b.id)
        storeA.reload()
        XCTAssertEqual(storeA.records.count, 1)
    }

    func testDeleteProfileCascadesRecords() {
        let (pc, ps) = freshStores()
        let a = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        let cdp = ps.managedProfile(a.id)!
        let r = CDBrushingRecord(context: pc.viewContext)
        r.id = UUID(); r.startDate = Date(); r.endDate = Date(); r.profile = cdp
        try? pc.viewContext.save()

        ps.deleteProfile(a.id)
        let req = NSFetchRequest<CDBrushingRecord>(entityName: "CDBrushingRecord")
        XCTAssertEqual((try? pc.viewContext.count(for: req)) ?? -1, 0)
        XCTAssertTrue(ps.profiles.isEmpty)
    }
}
