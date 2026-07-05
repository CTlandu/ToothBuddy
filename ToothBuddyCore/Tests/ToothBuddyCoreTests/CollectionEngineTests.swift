import XCTest
@testable import ToothBuddyCore

/// U5 — collectible selection (unowned, rarity-weighted, deterministic).
final class CollectionEngineTests: XCTestCase {

    func testGrantsAnUnownedItemFromEmpty() {
        let g = CollectionEngine.grant(owned: [], seed: 0)
        XCTAssertNotNil(g)
        XCTAssertTrue(Collectible.all.contains(g!))
    }

    func testNeverGrantsAnOwnedItem() {
        // Own everything except one specific item → must return exactly that item, any seed.
        let target = Collectible.all[7]
        let owned = Set(Collectible.all.map(\.id)).subtracting([target.id])
        for seed in 0..<50 {
            XCTAssertEqual(CollectionEngine.grant(owned: owned, seed: seed)?.id, target.id)
        }
    }

    func testAllOwnedReturnsNil() {
        let owned = Set(Collectible.all.map(\.id))
        XCTAssertNil(CollectionEngine.grant(owned: owned, seed: 3))
    }

    func testRarityWeightingFavorsCommon() {
        var common = 0, legendary = 0
        for seed in 0..<600 {
            guard let g = CollectionEngine.grant(owned: [], seed: seed) else { continue }
            if g.rarity == .common { common += 1 }
            if g.rarity == .legendary { legendary += 1 }
        }
        XCTAssertGreaterThan(common, legendary)
    }

    func testProgressCounts() {
        let owned: Set<String> = ["c01", "r01", "l01"]
        let p = CollectionEngine.progress(owned: owned)
        XCTAssertEqual(p.owned, 3)
        XCTAssertEqual(p.total, Collectible.all.count)
    }

    func testDeterministicForSameSeed() {
        XCTAssertEqual(CollectionEngine.grant(owned: [], seed: 42)?.id,
                       CollectionEngine.grant(owned: [], seed: 42)?.id)
    }
}
