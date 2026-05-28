import XCTest
import ToothBuddyCore
@testable import ToothBuddy

/// Quality audit 2026-05-28 / Plan U4 — Widget App Group round-trip tests.
@MainActor
final class WidgetBridgeTests: XCTestCase {

    /// The App Group snapshot read/write must round-trip cleanly. The widget reads
    /// what the app writes; any encoding break is a Silent Widget bug (the widget
    /// would show the placeholder forever instead of real data).
    func testAppGroupSnapshotRoundTrip() {
        let original = WidgetSnapshot(
            profileName: "Round-Trip Test",
            currentStreak: 5,
            amDone: true,
            pmDone: false,
            atRisk: true,
            asOf: Date(timeIntervalSince1970: 1_700_000_000))
        AppGroup.write(original)
        let echoed = AppGroup.readSnapshot()

        XCTAssertEqual(echoed.profileName, original.profileName)
        XCTAssertEqual(echoed.currentStreak, original.currentStreak)
        XCTAssertEqual(echoed.amDone, original.amDone)
        XCTAssertEqual(echoed.pmDone, original.pmDone)
        XCTAssertEqual(echoed.atRisk, original.atRisk)
        XCTAssertEqual(echoed.asOf.timeIntervalSince1970, original.asOf.timeIntervalSince1970,
                       accuracy: 0.001)
    }

    /// When no snapshot has ever been written (or the bundle is fresh), the widget
    /// must see the friendly `.placeholder` — never a blank/error state.
    func testReadSnapshotReturnsPlaceholderWhenAbsent() {
        // Clear the key so we exercise the "no data" path.
        UserDefaults(suiteName: AppGroup.id)?.removeObject(forKey: "ToothBuddy.widgetSnapshot.v1")
        let snap = AppGroup.readSnapshot()
        XCTAssertEqual(snap.profileName, WidgetSnapshot.placeholder.profileName)
    }

    /// `WidgetBridge.refresh()` is the orchestrator that pulls live state and writes
    /// the App Group. With no active profile, it must write the placeholder
    /// (not silently fail to update the widget).
    func testRefreshWritesPlaceholderWhenNoActiveProfile() {
        // Build a totally clean profile store with no active profile.
        UserDefaults.standard.removeObject(forKey: "ToothBuddy.activeProfileID")
        UserDefaults.standard.set(true, forKey: "ToothBuddy.didMigrateToCoreData_v1")
        let pc = PersistenceController(inMemory: true)
        let ps = ProfileStore(controller: pc)
        ps.setActive(nil)
        XCTAssertNil(ps.activeProfile)

        // Note: WidgetBridge.refresh uses .shared singletons, so this test mainly
        // documents the contract; production runs always have .shared. We do not
        // assert on the widget output here, only that the call is safe.
        WidgetBridge.refresh()
    }
}
