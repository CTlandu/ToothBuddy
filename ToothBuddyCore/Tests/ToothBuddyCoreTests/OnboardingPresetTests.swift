import XCTest
@testable import ToothBuddyCore

/// U2 — preset → default-value mapping. Presets only seed values (no behavior branch);
/// each maps to the spec'd bundle and every target is a valid 120/180.
final class OnboardingPresetTests: XCTestCase {

    func testKidDefaults() {
        XCTAssertEqual(OnboardingPreset.kid.defaults,
                       PreferenceDefaults(contentTone: .playful, gameEnabled: true,
                                          celebrationsEnabled: true, targetSeconds: 120))
    }

    func testAdultDefaults() {
        XCTAssertEqual(OnboardingPreset.adult.defaults,
                       PreferenceDefaults(contentTone: .essentials, gameEnabled: false,
                                          celebrationsEnabled: false, targetSeconds: 120))
    }

    func testIntensiveDefaults() {
        XCTAssertEqual(OnboardingPreset.intensive.defaults,
                       PreferenceDefaults(contentTone: .essentials, gameEnabled: false,
                                          celebrationsEnabled: true, targetSeconds: 180))
    }

    func testEveryPresetTargetIsAValidStandard() {
        for preset in OnboardingPreset.allCases {
            XCTAssertTrue([120, 180].contains(preset.defaults.targetSeconds),
                          "\(preset) has a non-standard target")
        }
    }

    func testEveryPresetHasHumanReadableCopy() {
        for preset in OnboardingPreset.allCases {
            // Display strings must be present and not a bare code identifier.
            XCTAssertFalse(preset.displayName.isEmpty)
            XCTAssertFalse(preset.caption.isEmpty)
            XCTAssertTrue(preset.displayName.contains(" "),
                          "\(preset) displayName should read like a phrase, not an identifier")
        }
    }

    func testDisplayNamesAreDistinct() {
        let names = Set(OnboardingPreset.allCases.map(\.displayName))
        XCTAssertEqual(names.count, OnboardingPreset.allCases.count)
    }
}
