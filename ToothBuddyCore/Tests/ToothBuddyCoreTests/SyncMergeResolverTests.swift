import XCTest
@testable import ToothBuddyCore

/// Spec 02 §6.8 / AC12 — LWW, tombstones beat stale, union (no loss).
final class SyncMergeResolverTests: XCTestCase {

    private struct Item: SyncMergeable {
        let id: UUID
        var modifiedAt: Date
        var isDeleted: Bool
        var payload: String
    }
    private let t0 = Date(timeIntervalSince1970: 1_000_000)
    private func at(_ s: TimeInterval) -> Date { t0.addingTimeInterval(s) }

    func testLastWriterWins() {
        let id = UUID()
        let local = Item(id: id, modifiedAt: at(10), isDeleted: false, payload: "old")
        let remote = Item(id: id, modifiedAt: at(20), isDeleted: false, payload: "new")
        let merged = SyncMergeResolver.merge([local], [remote])
        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].payload, "new")
    }

    func testTombstoneBeatsStaleUpdate() {
        let id = UUID()
        let deleteNewer = Item(id: id, modifiedAt: at(30), isDeleted: true, payload: "")
        let staleUpdate = Item(id: id, modifiedAt: at(15), isDeleted: false, payload: "x")
        XCTAssertTrue(SyncMergeResolver.merge([staleUpdate], [deleteNewer])[0].isDeleted)
        // order-independent
        XCTAssertTrue(SyncMergeResolver.merge([deleteNewer], [staleUpdate])[0].isDeleted)
    }

    func testTombstoneWinsOnTimestampTie() {
        let id = UUID()
        let del = Item(id: id, modifiedAt: at(40), isDeleted: true, payload: "")
        let upd = Item(id: id, modifiedAt: at(40), isDeleted: false, payload: "y")
        XCTAssertTrue(SyncMergeResolver.merge([upd], [del])[0].isDeleted)
    }

    func testUnionNoLoss() {
        let a = Item(id: UUID(), modifiedAt: at(1), isDeleted: false, payload: "a")
        let b = Item(id: UUID(), modifiedAt: at(2), isDeleted: false, payload: "b")
        let c = Item(id: UUID(), modifiedAt: at(3), isDeleted: false, payload: "c")
        let merged = SyncMergeResolver.merge([a, b], [c])
        XCTAssertEqual(Set(merged.map(\.id)), Set([a, b, c].map(\.id)))
    }

    func testDeterministicStableOrder() {
        let a = Item(id: UUID(), modifiedAt: at(5), isDeleted: false, payload: "a")
        let b = Item(id: UUID(), modifiedAt: at(1), isDeleted: false, payload: "b")
        XCTAssertEqual(SyncMergeResolver.merge([a], [b]),
                       SyncMergeResolver.merge([b], [a]))   // order-independent
        XCTAssertEqual(SyncMergeResolver.merge([a, b], []).map(\.payload), ["b", "a"]) // by modifiedAt
    }
}
