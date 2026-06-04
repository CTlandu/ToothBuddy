import XCTest
import CoreData
import ToothBuddyCore
@testable import ToothBuddy

/// U11 — gamification now tracks brushing *quality* (thorough/verified sessions), not raw count.
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

    private func fullCoverage() -> [CoarseZone: Int] {
        Dictionary(uniqueKeysWithValues: CoarseZone.allCases.map { ($0, 20) })
    }

    /// Plain (non-thorough) sessions: no coverage ⇒ metMinimum == false.
    private func seedPlain(_ count: Int, into bs: BrushingStore, startingDaysAgo: Int = 0) {
        let cal = Calendar.current
        for i in 0..<count {
            let day = cal.date(byAdding: .day, value: -(startingDaysAgo + i), to: Date())!
            bs.recordSession(start: day.addingTimeInterval(-120), end: day)
        }
    }

    /// Thorough sessions: full coverage + full time ⇒ metMinimum == true.
    private func seedThorough(_ count: Int, into bs: BrushingStore,
                              verified: Bool = false, startingDaysAgo: Int = 0) {
        let cal = Calendar.current
        for i in 0..<count {
            let day = cal.date(byAdding: .day, value: -(startingDaysAgo + i), to: Date())!
            bs.recordSession(start: day.addingTimeInterval(-120), end: day,
                             activeSeconds: 120, targetSeconds: 120, coverage: fullCoverage(),
                             cameraVerified: verified,
                             guidanceMode: verified ? .camera : .fallbackTimed)
        }
    }

    func testLevelGatesByThoroughCount() {
        let (_, ps, bs, gs) = make()
        let p = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        ps.setActive(p.id); bs.reload()

        XCTAssertEqual(gs.level, 0)
        seedThorough(1, into: bs);  XCTAssertEqual(gs.level, 1)
        seedThorough(4, into: bs, startingDaysAgo: 1);  XCTAssertEqual(gs.level, 2)   // 5 total
        seedThorough(10, into: bs, startingDaysAgo: 6); XCTAssertEqual(gs.level, 3)   // 15 total
    }

    func testPlainSessionsDoNotRaiseLevel() {
        let (_, ps, bs, gs) = make()
        let p = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        ps.setActive(p.id); bs.reload()
        seedPlain(10, into: bs)
        XCTAssertEqual(gs.level, 0, "Sessions without coverage are not thorough ⇒ no level")
    }

    func testFirstBrushUnlocksOnAnySession() {
        let (_, ps, bs, gs) = make()
        let p = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        ps.setActive(p.id); bs.reload()
        XCTAssertFalse(gs.unlockedAchievementIds.contains("first-brush"))
        seedPlain(1, into: bs)
        gs.checkAndUnlock(records: bs.records)
        XCTAssertTrue(gs.unlockedAchievementIds.contains("first-brush"))
        XCTAssertFalse(gs.unlockedAchievementIds.contains("first-thorough"))
    }

    func testThoroughUnlocksQualityAchievements() {
        let (_, ps, bs, gs) = make()
        let p = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        ps.setActive(p.id); bs.reload()
        seedThorough(1, into: bs)
        gs.checkAndUnlock(records: bs.records)
        XCTAssertTrue(gs.unlockedAchievementIds.contains("first-thorough"))
        XCTAssertTrue(gs.unlockedAchievementIds.contains("two-min"))
        XCTAssertFalse(gs.unlockedAchievementIds.contains("verified"))   // not a camera session
    }

    func testVerifiedUnlocksOnlyWithCameraSession() {
        let (_, ps, bs, gs) = make()
        let p = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        ps.setActive(p.id); bs.reload()
        seedThorough(1, into: bs, verified: true)
        gs.checkAndUnlock(records: bs.records)
        XCTAssertTrue(gs.unlockedAchievementIds.contains("verified"))
    }

    func testCheckAndUnlockIsIdempotent() {
        let (_, ps, bs, gs) = make()
        let p = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        ps.setActive(p.id); bs.reload()
        seedThorough(5, into: bs)
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

        ps.setActive(a.id); bs.reload()
        seedPlain(1, into: bs)
        gsA.checkAndUnlock(records: bs.records)
        XCTAssertTrue(gsA.unlockedAchievementIds.contains("first-brush"))

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

        let cal = Calendar.current
        let sevenAM = cal.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!
        bs.recordSession(start: sevenAM.addingTimeInterval(-120), end: sevenAM)
        gs.checkAndUnlock(records: bs.records)
        XCTAssertTrue(gs.unlockedAchievementIds.contains("early-bird"))
    }
}
