import XCTest
import ToothBuddyCore
@testable import ToothBuddy

@MainActor
final class PreferencesStoreTests: XCTestCase {

    private func freshDefaults() -> UserDefaults {
        let name = "test.prefs.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    func testDefaultsAllOn() {
        let p = PreferencesStore(defaults: freshDefaults())
        XCTAssertTrue(p.gameEnabled)
        XCTAssertTrue(p.celebrationsEnabled)
        XCTAssertTrue(p.showLevelAchievements)
        XCTAssertTrue(p.showHabitCurve)
        XCTAssertTrue(p.voiceEnabled)
        XCTAssertTrue(p.healthConnectEnabled)
        XCTAssertEqual(p.sessionMode, .mirror)
        XCTAssertEqual(p.contentTone, .playful)
        XCTAssertEqual(p.targetSeconds, 120)
    }

    func testPersistsAcrossInstances() {
        let d = freshDefaults()
        let p1 = PreferencesStore(defaults: d)
        p1.gameEnabled = false
        p1.sessionMode = .audio
        p1.targetSeconds = 180
        p1.contentTone = .essentials
        let p2 = PreferencesStore(defaults: d)
        XCTAssertFalse(p2.gameEnabled)
        XCTAssertEqual(p2.sessionMode, .audio)
        XCTAssertEqual(p2.targetSeconds, 180)
        XCTAssertEqual(p2.contentTone, .essentials)
    }

    func testTargetSecondsAcceptsOnlyStandardValues() {
        let d = freshDefaults()
        d.set(999, forKey: "pref.targetSeconds")
        XCTAssertEqual(PreferencesStore(defaults: d).targetSeconds, 120) // unknown → 2 min
        d.set(180, forKey: "pref.targetSeconds")
        XCTAssertEqual(PreferencesStore(defaults: d).targetSeconds, 180)
    }

    func testMigratesLegacyMuteFlag() {
        let d = freshDefaults()
        d.set(true, forKey: "voiceCoachMuted")              // old standalone: muted
        XCTAssertFalse(PreferencesStore(defaults: d).voiceEnabled) // ⇒ voice disabled
    }
}
