import XCTest
import CoreData
import ToothBuddyCore
@testable import ToothBuddy

/// U6 — RetentionStore grants collectibles on qualifying sessions, persists them (CloudKit-safe
/// CDCollectibleUnlock), and drives the overnight reveal. Mirrors GamificationStoreTests' setup.
@MainActor
final class RetentionStoreTests: XCTestCase {

    private func make() -> (PersistenceController, ProfileStore, BrushingStore, RetentionStore) {
        UserDefaults.standard.set(true, forKey: "ToothBuddy.didMigrateToCoreData_v1")
        let pc = PersistenceController(inMemory: true)
        let ps = ProfileStore(controller: pc)
        let bs = BrushingStore(controller: pc, profiles: ps)
        let defaults = UserDefaults(suiteName: "test.retention.\(UUID().uuidString)")!
        let rs = RetentionStore(controller: pc, profiles: ps, brushing: bs, defaults: defaults)
        return (pc, ps, bs, rs)
    }

    private func fullCoverage() -> [CoarseZone: Int] {
        Dictionary(uniqueKeysWithValues: CoarseZone.allCases.map { ($0, 20) })
    }

    /// Thorough (metMinimum) sessions — one per day going back.
    private func seedThorough(_ count: Int, into bs: BrushingStore) {
        let cal = Calendar.current
        for i in 0..<count {
            let day = cal.date(byAdding: .day, value: -i, to: Date())!
            bs.recordSession(start: day.addingTimeInterval(-120), end: day,
                             activeSeconds: 120, targetSeconds: 120, coverage: fullCoverage(),
                             cameraVerified: false, guidanceMode: .fallbackTimed)
        }
    }

    /// Plain (below-goal, no coverage) sessions.
    private func seedPlain(_ count: Int, into bs: BrushingStore) {
        let cal = Calendar.current
        for i in 0..<count {
            let day = cal.date(byAdding: .day, value: -i, to: Date())!
            bs.recordSession(start: day.addingTimeInterval(-120), end: day)
        }
    }

    private func withOwner(_ ps: ProfileStore, _ bs: BrushingStore) {
        let p = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        ps.setActive(p.id); bs.reload()
    }

    func testQualifyingSessionGrantsOneCollectible() {
        let (_, ps, bs, rs) = make()
        withOwner(ps, bs)
        seedThorough(1, into: bs)
        rs.refresh()
        XCTAssertEqual(rs.ownedCollectibleIds.count, 1)
        XCTAssertNotNil(rs.pendingCollectible)
    }

    func testPlainSessionGrantsNothing() {
        let (_, ps, bs, rs) = make()
        withOwner(ps, bs)
        seedPlain(1, into: bs)
        rs.refresh()
        XCTAssertEqual(rs.ownedCollectibleIds.count, 0)
        XCTAssertNil(rs.pendingCollectible)
    }

    func testCollectibleUnlockRoundTrips() {
        let (pc, ps, bs, rs) = make()
        withOwner(ps, bs)
        seedThorough(2, into: bs)
        rs.refresh()
        let granted = rs.ownedCollectibleIds
        XCTAssertEqual(granted.count, 2)
        // A fresh store on the same context loads the persisted unlocks.
        let defaults = UserDefaults(suiteName: "test.retention.\(UUID().uuidString)")!
        let rs2 = RetentionStore(controller: pc, profiles: ps, brushing: bs, defaults: defaults)
        XCTAssertEqual(rs2.ownedCollectibleIds, granted)
    }

    func testConsumeRevealClearsPending() {
        let (_, ps, bs, rs) = make()
        withOwner(ps, bs)
        seedThorough(1, into: bs)
        rs.refresh()
        XCTAssertNotNil(rs.pendingCollectibleID)
        rs.consumeReveal()
        XCTAssertNil(rs.pendingCollectibleID)
    }

    func testCollectionProgressCounts() {
        let (_, ps, bs, rs) = make()
        withOwner(ps, bs)
        seedThorough(3, into: bs)
        rs.refresh()
        XCTAssertEqual(rs.collectionProgress.owned, 3)
        XCTAssertEqual(rs.collectionProgress.total, Collectible.all.count)
    }
}
