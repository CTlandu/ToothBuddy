import XCTest
import CoreData
import ToothBuddyCore
@testable import ToothBuddy

/// Quality audit 2026-05-28 / Plan U4 — GamificationStore unit tests.
@MainActor
final class GamificationStoreTests: XCTestCase {

    private func make() -> (PersistenceController, ProfileStore, BrushingStore, GamificationStore) {
        UserDefaults.standard.set(true, forKey: "ToothBuddy.didMigrateToCoreData_v1")
        let pc = PersistenceController(inMemory: true)
        let ps = ProfileStore(controller: pc)
        let bs = BrushingStore(controller: pc, profiles: ps)
        let gs = GamificationStore(controller: pc, profiles: ps, brushing: bs)
        return (pc, ps, bs, gs)
    }

    /// Build N records for the given profile and reload.
    private func seedRecords(_ count: Int, into bs: BrushingStore, startingDaysAgo: Int = 0) {
        let cal = Calendar.current
        for i in 0..<count {
            let day = cal.date(byAdding: .day, value: -(startingDaysAgo + i), to: Date())!
            bs.recordSession(start: day.addingTimeInterval(-120), end: day)
        }
    }

    func testLevelGatesByRecordCount() {
        let (_, ps, bs, gs) = make()
        let p = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        ps.setActive(p.id); bs.reload()

        XCTAssertEqual(gs.level, 0)
        seedRecords(1, into: bs);  XCTAssertEqual(gs.level, 1)
        seedRecords(4, into: bs, startingDaysAgo: 1); XCTAssertEqual(gs.level, 2)
        seedRecords(10, into: bs, startingDaysAgo: 6); XCTAssertEqual(gs.level, 3)
    }

    func testFirstBrushUnlocksAfterOneSession() {
        let (_, ps, bs, gs) = make()
        let p = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        ps.setActive(p.id); bs.reload()

        XCTAssertFalse(gs.unlockedAchievementIds.contains("first-brush"))
        seedRecords(1, into: bs)
        gs.checkAndUnlock(records: bs.records)
        XCTAssertTrue(gs.unlockedAchievementIds.contains("first-brush"))
    }

    func testCheckAndUnlockIsIdempotent() {
        let (_, ps, bs, gs) = make()
        let p = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        ps.setActive(p.id); bs.reload()
        seedRecords(5, into: bs)
        gs.checkAndUnlock(records: bs.records)
        let firstPass = gs.unlockedAchievementIds.count
        gs.checkAndUnlock(records: bs.records)
        gs.checkAndUnlock(records: bs.records)
        XCTAssertEqual(gs.unlockedAchievementIds.count, firstPass,
                       "Repeated checkAndUnlock on same records must not duplicate")
    }

    func testUnlockedAchievementsAreIsolatedPerProfile() {
        let (pc, ps, bs, gsA) = make()
        let a = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        let b = ps.createProfile(name: "B", color: .mint, symbol: .bolt)!

        // Unlock first-brush for A.
        ps.setActive(a.id); bs.reload()
        seedRecords(1, into: bs)
        gsA.checkAndUnlock(records: bs.records)
        XCTAssertTrue(gsA.unlockedAchievementIds.contains("first-brush"))

        // Switch to B and instantiate a fresh GamificationStore so the @Published
        // willSet timing is not in play — this is the same logic the production
        // shared store runs after reload(). B must see an empty achievement set,
        // proving the CDAchievementUnlock rows are profile-scoped.
        ps.setActive(b.id); bs.reload()
        let gsB = GamificationStore(controller: pc, profiles: ps, brushing: bs)
        XCTAssertFalse(gsB.unlockedAchievementIds.contains("first-brush"),
                       "Profile B must not inherit profile A's achievements")
        XCTAssertTrue(gsB.unlockedAchievementIds.isEmpty)
    }

    func testEarlyBirdGatesByMorningHour() {
        let (_, ps, bs, gs) = make()
        let p = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        ps.setActive(p.id); bs.reload()

        // 7 AM session → should unlock early-bird.
        let cal = Calendar.current
        let sevenAM = cal.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!
        bs.recordSession(start: sevenAM.addingTimeInterval(-120), end: sevenAM)
        gs.checkAndUnlock(records: bs.records)
        XCTAssertTrue(gs.unlockedAchievementIds.contains("early-bird"))
    }
}
