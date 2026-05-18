import Foundation

/// A value type that can be merged across CloudKit replicas (Spec 02 §6.8). Carries a
/// `modifiedAt` for last-writer-wins and an `isDeleted` tombstone so deletes propagate.
public protocol SyncMergeable: Identifiable, Equatable, Sendable {
    var modifiedAt: Date { get }
    var isDeleted: Bool { get }
}

/// Pure, deterministic conflict resolution. `NSPersistentCloudKitContainer` handles
/// store-level merge; this resolves app-level duplicates (e.g. two members create the
/// same profile) and is the unit-tested truth source. Spec 02 AC12.
public enum SyncMergeResolver {

    /// Merge two replicas keyed by `id`:
    /// - the version with the greater `modifiedAt` wins (LWW);
    /// - on a tie, a tombstone (`isDeleted`) wins over a live update (deletes beat stale);
    /// - the result is the **union** of all ids — no record is ever dropped (tombstones
    ///   are kept so deletes propagate; callers purge them at the persistence boundary).
    public static func merge<T: SyncMergeable>(_ local: [T], _ remote: [T]) -> [T] {
        var winner: [T.ID: T] = [:]
        for item in local + remote {
            if let existing = winner[item.id] {
                winner[item.id] = pick(existing, item)
            } else {
                winner[item.id] = item
            }
        }
        // Deterministic order: by id's hash is unstable across runs, so sort by
        // modifiedAt then by String(describing: id) for a stable, testable output.
        return winner.values.sorted {
            if $0.modifiedAt != $1.modifiedAt { return $0.modifiedAt < $1.modifiedAt }
            return String(describing: $0.id) < String(describing: $1.id)
        }
    }

    private static func pick<T: SyncMergeable>(_ a: T, _ b: T) -> T {
        if a.modifiedAt != b.modifiedAt {
            return a.modifiedAt > b.modifiedAt ? a : b
        }
        // Equal timestamps: a tombstone wins; otherwise keep `a` deterministically.
        if a.isDeleted != b.isDeleted {
            return a.isDeleted ? a : b
        }
        return a
    }
}
