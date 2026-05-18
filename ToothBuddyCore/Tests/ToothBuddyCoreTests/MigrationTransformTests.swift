import XCTest
@testable import ToothBuddyCore

/// Spec 02 §7.2 / AC1 — zero-loss, deterministic legacy migration.
final class MigrationTransformTests: XCTestCase {
    private func legacy(_ n: Int) -> [LegacyBrushingRecord] {
        (0..<n).map { i in
            let start = Date(timeIntervalSince1970: 1_000_000 + Double(i) * 86_400)
            return LegacyBrushingRecord(id: UUID(), startDate: start,
                                        endDate: start.addingTimeInterval(130))
        }
    }

    func testMigratePreservesCountIdsDatesAndOrder() {
        let pid = UUID()
        let src = legacy(5)
        let out = MigrationTransform.migrate(legacy: src, defaultProfileID: pid)
        XCTAssertEqual(out.count, 5)
        for (l, m) in zip(src, out) {
            XCTAssertEqual(m.id, l.id)
            XCTAssertEqual(m.startDate, l.startDate)
            XCTAssertEqual(m.endDate, l.endDate)
            XCTAssertEqual(m.profileID, pid)
        }
    }

    func testMigrateEmptyIsEmpty() {
        XCTAssertEqual(MigrationTransform.migrate(legacy: [], defaultProfileID: UUID()), [])
    }

    /// Re-running the transform on its own re-decoded output is stable (no dup/loss):
    /// decoding legacy JSON then migrating is deterministic for the same input.
    func testDecodeThenMigrateIsDeterministic() throws {
        let src = legacy(3)
        let data = try JSONEncoder().encode(src)
        let decoded = try MigrationTransform.decodeLegacy(data)
        XCTAssertEqual(decoded, src)
        let pid = UUID()
        XCTAssertEqual(MigrationTransform.migrate(legacy: decoded, defaultProfileID: pid),
                       MigrationTransform.migrate(legacy: src, defaultProfileID: pid))
    }

    /// A real pre-P2 `brushing_records.json` (plain JSONEncoder of {id,startDate,endDate})
    /// decodes via LegacyBrushingRecord.
    func testDecodesLegacyJSONShape() throws {
        let id = UUID()
        let json = """
        [{"id":"\(id.uuidString)","startDate":1000000,"endDate":1000130}]
        """.data(using: .utf8)!
        let decoded = try MigrationTransform.decodeLegacy(json)
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].id, id)
    }
}
