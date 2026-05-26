import XCTest
@testable import ToothBuddyCore

/// Spec 05 §6.6 / AC5 — write-only, idempotent export decision.
final class HealthExportDeciderTests: XCTestCase {
    func testExportsOnlyWhenCompletedAndNotAlreadyExported() {
        let a = UUID(), b = UUID()
        XCTAssertTrue(HealthExportDecider.shouldExport(
            sessionID: a, isCompleted: true, alreadyExportedIDs: []))
        XCTAssertTrue(HealthExportDecider.shouldExport(
            sessionID: a, isCompleted: true, alreadyExportedIDs: [b]))
    }

    func testNotExportedWhenIncomplete() {
        let a = UUID()
        XCTAssertFalse(HealthExportDecider.shouldExport(
            sessionID: a, isCompleted: false, alreadyExportedIDs: []))
    }

    func testNotExportedWhenAlreadyExported() {
        let a = UUID()
        XCTAssertFalse(HealthExportDecider.shouldExport(
            sessionID: a, isCompleted: true, alreadyExportedIDs: [a]))
        // Re-completion / relaunch must never double-write.
        XCTAssertFalse(HealthExportDecider.shouldExport(
            sessionID: a, isCompleted: true, alreadyExportedIDs: [a, UUID()]))
    }
}
