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

    // Spec 05 AC1/AC6 — mode persists, defaults to kid, and is per-profile isolated.
    func testProfileModeDefaultsKidAndFlipsPerProfile() {
        let (_, ps) = freshStores()
        let kid = ps.createProfile(name: "Kid", color: .sky, symbol: .star)!
        let adult = ps.createProfile(name: "Mom", color: .mint, symbol: .leaf,
                                     mode: .adult)!
        XCTAssertEqual(ps.profiles.first { $0.id == kid.id }?.mode, .kid)
        XCTAssertEqual(ps.profiles.first { $0.id == adult.id }?.mode, .adult)

        ps.setMode(.adult, for: kid.id)
        XCTAssertEqual(ps.profiles.first { $0.id == kid.id }?.mode, .adult)
        // Flipping one profile must not touch the sibling.
        XCTAssertEqual(ps.profiles.first { $0.id == adult.id }?.mode, .adult)
        ps.setMode(.kid, for: adult.id)
        XCTAssertEqual(ps.profiles.first { $0.id == adult.id }?.mode, .kid)
        XCTAssertEqual(ps.profiles.first { $0.id == kid.id }?.mode, .adult)
    }

    // Spec 05 §6.1 — explicit user tone wins; otherwise adult⇒essentials, kid⇒playful.
    func testEffectiveToneFollowsModeUntilUserSetsItExplicitly() {
        UserDefaults.standard.removeObject(forKey: "ToothBuddy.contentTone")
        let s = ContentHistoryStore.shared
        XCTAssertFalse(s.toneExplicitlySet)
        XCTAssertEqual(s.effectiveTone(forAdult: true), .essentials)
        XCTAssertEqual(s.effectiveTone(forAdult: false), .playful)
        s.setTone(.playful)                       // explicit choice
        XCTAssertTrue(s.toneExplicitlySet)
        XCTAssertEqual(s.effectiveTone(forAdult: true), .playful)   // user wins
        UserDefaults.standard.removeObject(forKey: "ToothBuddy.contentTone")
    }

    // Spec 05 §6.3 / AC7 — quick-log is idempotent within a slot.
    func testQuickLogIsIdempotentWithinSlot() {
        let (pc, ps) = freshStores()
        let p = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        ps.setActive(p.id)
        let store = BrushingStore(controller: pc, profiles: ps)

        XCTAssertEqual(store.quickLogForCurrentSlot(), .logged)
        XCTAssertEqual(store.records.count, 1)
        let streakAfterFirst = store.consecutiveDaysCount

        // Second call in the same slot → no new record, streak unchanged.
        XCTAssertEqual(store.quickLogForCurrentSlot(), .alreadyLoggedThisSlot)
        XCTAssertEqual(store.records.count, 1)
        XCTAssertEqual(store.consecutiveDaysCount, streakAfterFirst)
    }

    func testQuickLogNoProfileIsGraceful() {
        let (pc, ps) = freshStores()
        ps.setActive(nil)
        let store = BrushingStore(controller: pc, profiles: ps)
        XCTAssertEqual(store.quickLogForCurrentSlot(), .noProfile)
        XCTAssertTrue(store.records.isEmpty)
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
