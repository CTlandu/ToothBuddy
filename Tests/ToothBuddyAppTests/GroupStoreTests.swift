import XCTest
import CoreData
import ToothBuddyCore
@testable import ToothBuddy

/// Spec 02 P2.2 — AC7 (create attaches profiles), AC9 (leave keeps profile local).
@MainActor
final class GroupStoreTests: XCTestCase {

    private func stores() -> (PersistenceController, ProfileStore, GroupStore) {
        UserDefaults.standard.set(true, forKey: "ToothBuddy.didMigrateToCoreData_v1")
        let pc = PersistenceController(inMemory: true)
        let ps = ProfileStore(controller: pc)
        let gs = GroupStore(controller: pc, profiles: ps)
        return (pc, ps, gs)
    }

    func testCreateGroupAttachesAllProfiles() {
        let (pc, ps, gs) = stores()
        let a = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        let b = ps.createProfile(name: "B", color: .mint, symbol: .bolt)!
        XCTAssertFalse(gs.hasGroup)

        XCTAssertTrue(gs.createGroupWithAllProfiles(name: "The Smiths"))
        XCTAssertTrue(gs.hasGroup)
        XCTAssertEqual(gs.groupName, "The Smiths")

        for id in [a.id, b.id] {
            XCTAssertNotNil(ps.managedProfile(id)?.group, "profile \(id) should be attached")
        }
        // A second group cannot be created while one exists.
        XCTAssertFalse(gs.createGroupWithAllProfiles(name: "Other"))
        _ = pc
    }

    func testLeaveKeepsProfileLocal() {
        let (_, ps, gs) = stores()
        let a = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        _ = gs.createGroupWithAllProfiles(name: "Fam")
        XCTAssertNotNil(ps.managedProfile(a.id)?.group)

        gs.leave(profileID: a.id)
        XCTAssertNil(ps.managedProfile(a.id)?.group)        // detached
        ps.reload()
        XCTAssertTrue(ps.profiles.contains { $0.id == a.id }) // but still a local profile
    }

    func testDisbandGroup() {
        let (_, ps, gs) = stores()
        _ = ps.createProfile(name: "A", color: .sky, symbol: .star)
        _ = gs.createGroupWithAllProfiles(name: "Fam")
        XCTAssertTrue(gs.hasGroup)
        gs.deleteGroup()
        XCTAssertFalse(gs.hasGroup)
        XCTAssertEqual(ps.profiles.count, 1)               // profiles survive
    }
}
