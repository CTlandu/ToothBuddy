import Foundation

/// Grants collectibles from the catalog. Pure & deterministic — the reveal/celebration
/// layers pass a `seed` (a monotonically increasing counter, e.g. total tokens earned) so a
/// given progression is reproducible. Never calls `Date()`/random internally (Core rule).
public enum CollectionEngine {

    /// Returns one un-owned collectible, weighted by rarity, or `nil` when all are owned.
    /// Rarity weighting: an item appears `rarity.weight` times in the draw pool, so common
    /// items are granted more often than legendary ones.
    public static func grant(owned: Set<String>,
                             seed: Int,
                             catalog: [Collectible] = Collectible.all) -> Collectible? {
        let pool = catalog.filter { !owned.contains($0.id) }
        guard !pool.isEmpty else { return nil }
        let weighted = pool.flatMap { c in Array(repeating: c, count: max(1, c.rarity.weight)) }
        let idx = ((seed % weighted.count) + weighted.count) % weighted.count   // handles negative seeds
        return weighted[idx]
    }

    /// Owned / total for the collection progress header.
    public static func progress(owned: Set<String>,
                                catalog: [Collectible] = Collectible.all) -> (owned: Int, total: Int) {
        let ownedInCatalog = catalog.filter { owned.contains($0.id) }.count
        return (ownedInCatalog, catalog.count)
    }
}
