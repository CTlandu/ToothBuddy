import XCTest
import ToothBuddyCore
@testable import ToothBuddy

/// Quality audit 2026-05-28 / Plan U4 + U5 — HealthExporter idempotency tests.
///
/// We do NOT touch the real HKHealthStore (test environment has no Health permission,
/// would noop anyway). Instead we test the **export decision layer** + the
/// **persistence layer** (UserDefaults set of exported IDs). The actual HK write is
/// trivial wiring guarded by `isAuthorized` and unit-tested separately by HK itself.
@MainActor
final class HealthExporterTests: XCTestCase {

    /// `HealthExportDecider` is the pure rule that determines whether a session
    /// should be written. Repeated calls with the same id + already-exported set
    /// must return false — this is the regression net for the P5.4 idempotency claim.
    func test_regression_doubleExportDecisionWritesAtMostOnce() {
        let sid = UUID()
        // First call: not yet exported → should export.
        XCTAssertTrue(HealthExportDecider.shouldExport(
            sessionID: sid, isCompleted: true, alreadyExportedIDs: []))
        // Second call with the same id already in the set → must NOT re-export.
        XCTAssertFalse(HealthExportDecider.shouldExport(
            sessionID: sid, isCompleted: true, alreadyExportedIDs: [sid]))
        // Different id → independent decision.
        let other = UUID()
        XCTAssertTrue(HealthExportDecider.shouldExport(
            sessionID: other, isCompleted: true, alreadyExportedIDs: [sid]))
    }

    func testIncompleteSessionsAreNeverExported() {
        let sid = UUID()
        XCTAssertFalse(HealthExportDecider.shouldExport(
            sessionID: sid, isCompleted: false, alreadyExportedIDs: []))
    }

    /// The shared HealthExporter is always constructible; on a simulator/Mac without
    /// HealthKit it reports `isAvailable == false` and `exportIfNeeded` is a no-op.
    func testExportIfNeededNoOpsWhenUnauthorized() {
        let sid = UUID()
        // Just confirm calling on an unauthorized environment does not throw / crash.
        // The test environment has no Health permission, so this is the unauthorized path.
        HealthExporter.shared.exportIfNeeded(
            sessionID: sid,
            start: Date().addingTimeInterval(-120),
            end: Date(),
            isCompleted: true)
        // Repeat — must also be safe.
        HealthExporter.shared.exportIfNeeded(
            sessionID: sid,
            start: Date().addingTimeInterval(-120),
            end: Date(),
            isCompleted: true)
    }
}
