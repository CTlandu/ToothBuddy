import XCTest
@testable import ToothBuddyCore

/// U3 (D-2) — the crash-safety snapshot survives a Codable round-trip and reconstructs an
/// honest (non-inflated) end timestamp from its active seconds.
final class InProgressSessionSnapshotTests: XCTestCase {

    private func sample() -> InProgressSessionSnapshot {
        InProgressSessionSnapshot(
            startDate: Date(timeIntervalSinceReferenceDate: 1_000),
            activeSeconds: 95,
            targetSeconds: 120,
            coverage: [.upperLeft: 20, .frontTop: 15],
            cameraVerified: true,
            guidanceMode: .camera)
    }

    func testCodableRoundTrip() throws {
        let snap = sample()
        let data = try JSONEncoder().encode(snap)
        let decoded = try JSONDecoder().decode(InProgressSessionSnapshot.self, from: data)
        XCTAssertEqual(snap, decoded)
    }

    func testRecoveredEndDateIsStartPlusActive() {
        let snap = sample()
        XCTAssertEqual(snap.recoveredEndDate, snap.startDate.addingTimeInterval(95))
        // The recovered record's wall-clock duration equals the non-inflated active total.
        XCTAssertEqual(Int(snap.recoveredEndDate.timeIntervalSince(snap.startDate)), 95)
    }

    func testRecoveredEndDateClampsNegativeActive() {
        var snap = sample()
        snap.activeSeconds = -5
        XCTAssertEqual(snap.recoveredEndDate, snap.startDate)   // never before start
    }
}
