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

    // MARK: - U2 onboarding preset apply

    func testApplyPresetSeedsAndPersists() {
        let d = freshDefaults()
        let p1 = PreferencesStore(defaults: d)
        p1.apply(OnboardingPreset.intensive.defaults)
        XCTAssertEqual(p1.contentTone, .essentials)
        XCTAssertFalse(p1.gameEnabled)
        XCTAssertTrue(p1.celebrationsEnabled)
        XCTAssertEqual(p1.targetSeconds, 180)
        // Persisted via the @Published didSets.
        let p2 = PreferencesStore(defaults: d)
        XCTAssertEqual(p2.contentTone, .essentials)
        XCTAssertFalse(p2.gameEnabled)
        XCTAssertTrue(p2.celebrationsEnabled)
        XCTAssertEqual(p2.targetSeconds, 180)
    }

    func testApplyLeavesNonPresetFieldsUntouched() {
        let p = PreferencesStore(defaults: freshDefaults())
        p.apply(OnboardingPreset.adult.defaults)   // only seeds tone/game/celebrations/target
        XCTAssertTrue(p.showLevelAchievements)
        XCTAssertTrue(p.showHabitCurve)
        XCTAssertTrue(p.voiceEnabled)
        XCTAssertTrue(p.healthConnectEnabled)
        XCTAssertEqual(p.sessionMode, .mirror)
    }

    func testApplyKidReturnsToOpenDefaults() {
        let p = PreferencesStore(defaults: freshDefaults())
        p.gameEnabled = false; p.contentTone = .essentials   // dirty it first
        p.apply(OnboardingPreset.kid.defaults)
        XCTAssertTrue(p.gameEnabled)
        XCTAssertEqual(p.contentTone, .playful)
        XCTAssertEqual(p.targetSeconds, 120)
    }
}
