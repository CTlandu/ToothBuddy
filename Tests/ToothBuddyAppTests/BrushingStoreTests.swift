import XCTest
import CoreData
import ToothBuddyCore
@testable import ToothBuddy

/// Quality audit 2026-05-28 / Plan U4 + U5 — BrushingStore behavior + regression tests.
/// Tests use in-memory PersistenceController, isolated from `BrushingStore.shared`.
@MainActor
final class BrushingStoreTests: XCTestCase {

    private func freshTriple() -> (PersistenceController, ProfileStore, BrushingStore) {
        UserDefaults.standard.set(true, forKey: "ToothBuddy.didMigrateToCoreData_v1")
        let pc = PersistenceController(inMemory: true)
        let ps = ProfileStore(controller: pc)
        let bs = BrushingStore(controller: pc, profiles: ps)
        return (pc, ps, bs)
    }

    // MARK: - Happy path

    func testRecordSessionAddsOneRecord() {
        let (_, ps, bs) = freshTriple()
        let p = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        ps.setActive(p.id)
        bs.reload()
        XCTAssertTrue(bs.records.isEmpty)

        let start = Date().addingTimeInterval(-120)
        bs.recordSession(start: start, end: Date())
        XCTAssertEqual(bs.records.count, 1)
        XCTAssertEqual(bs.records.first?.profileID, p.id)
    }

    // MARK: - Profile isolation

    func testRecordsAreScopedToActiveProfile() {
        let (_, ps, bs) = freshTriple()
        let a = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        let b = ps.createProfile(name: "B", color: .mint, symbol: .bolt)!

        ps.setActive(a.id); bs.reload()
        bs.recordSession(start: Date().addingTimeInterval(-120), end: Date())
        XCTAssertEqual(bs.records.count, 1)

        ps.setActive(b.id); bs.reload()
        XCTAssertEqual(bs.records.count, 0)

        ps.setActive(a.id); bs.reload()
        XCTAssertEqual(bs.records.count, 1)
    }

    // MARK: - allRecords spans every profile (Group dashboard)

    func testAllRecordsSpansEveryProfile() {
        let (_, ps, bs) = freshTriple()
        let a = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        let b = ps.createProfile(name: "B", color: .mint, symbol: .bolt)!

        ps.setActive(a.id); bs.reload()
        bs.recordSession(start: Date().addingTimeInterval(-120), end: Date())
        ps.setActive(b.id); bs.reload()
        bs.recordSession(start: Date().addingTimeInterval(-120), end: Date())

        XCTAssertEqual(bs.allRecords().count, 2)
    }

    // MARK: - Delete + Undo round-trip

    func testDeleteAndRestoreRoundTrip() {
        let (_, ps, bs) = freshTriple()
        let p = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        ps.setActive(p.id); bs.reload()
        bs.recordSession(start: Date().addingTimeInterval(-120), end: Date())
        let id = bs.records.first!.id

        bs.deleteRecord(id: id)
        XCTAssertTrue(bs.records.isEmpty)
        XCTAssertNotNil(bs.lastDeletedRecord)

        bs.restoreLastDeleted()
        XCTAssertEqual(bs.records.count, 1)
        XCTAssertNil(bs.lastDeletedRecord)
    }

    // MARK: - Edge: boundary date span

    func testRecordSessionHandlesNoonBoundaryCleanly() {
        let (_, ps, bs) = freshTriple()
        let p = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        ps.setActive(p.id); bs.reload()
        // Two sessions, one before noon, one after.
        let cal = Calendar.current
        let am = cal.date(bySettingHour: 8,  minute: 0, second: 0, of: Date())!
        let pm = cal.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!
        bs.recordSession(start: am.addingTimeInterval(-120), end: am)
        bs.recordSession(start: pm.addingTimeInterval(-120), end: pm)
        XCTAssertEqual(bs.records.count, 2)
        XCTAssertEqual(bs.recordsTodayCount, 2)
    }

    // MARK: - U5 regression: reentrant `shared` does not crash

    /// The P5.3 commit (CHANGELOG: "Fixed a launch crash: BrushingStore.reload()
    /// referenced BrushingStore.shared while that singleton was still initializing —
    /// reentrant static init trap") fixed the bug by gating widget-refresh behind a
    /// post-init flag. This test pins the fix: accessing `.shared` from app launch
    /// must not trap.
    func test_regression_sharedSingletonCanBeAccessedAtLaunchWithoutTrap() {
        // If `BrushingStore.shared` ever tried to recursively touch itself during
        // init, this access would trap. We just need to evaluate the static.
        let s = BrushingStore.shared
        XCTAssertNotNil(s)
        // Repeat access returns the same instance (identity stable).
        XCTAssertTrue(s === BrushingStore.shared)
        // And it can serve a basic read without crashing.
        _ = s.records
    }

    // MARK: - U3: enriched quality fields persist

    func testRecordSessionPersistsEnrichedQualityFields() {
        let (_, ps, bs) = freshTriple()
        let p = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        ps.setActive(p.id); bs.reload()
        let cov: [CoarseZone: Int] = Dictionary(uniqueKeysWithValues:
            CoarseZone.allCases.map { ($0, 20) })
        bs.recordSession(start: Date().addingTimeInterval(-120), end: Date(),
                         activeSeconds: 120, targetSeconds: 120, coverage: cov,
                         cameraVerified: true, guidanceMode: .camera)
        let r = bs.records.first!
        XCTAssertEqual(r.activeSeconds, 120)
        XCTAssertEqual(r.targetSeconds, 120)
        XCTAssertTrue(r.cameraVerified)
        XCTAssertEqual(r.guidanceMode, .camera)
        XCTAssertEqual(r.coverage.count, 6)
        XCTAssertTrue(r.metMinimum)
    }

    func testQuickLogMarksGuidedOnlyUnverified() {
        let (_, ps, bs) = freshTriple()
        let p = ps.createProfile(name: "A", color: .sky, symbol: .star)!
        ps.setActive(p.id); bs.reload()
        bs.quickLogForCurrentSlot()
        let r = bs.records.first!
        XCTAssertFalse(r.cameraVerified)
        XCTAssertEqual(r.guidanceMode, .fallbackTimed)
        XCTAssertTrue(r.coverage.isEmpty)
        XCTAssertFalse(r.metMinimum)   // synthetic log has no coverage ⇒ not a verified brush
    }
}
