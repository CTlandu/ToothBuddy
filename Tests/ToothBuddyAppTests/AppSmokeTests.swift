import XCTest
import ToothBuddyCore
@testable import ToothBuddy

/// Native app-target test scaffold (Xcode `.xcodeproj`). The exhaustive logic suite
/// lives in ToothBuddyCore (`cd ToothBuddyCore && swift test`); this only proves the
/// app target links the core and is testable for future app-layer/UI tests.
final class AppSmokeTests: XCTestCase {
    func testAppLinksToothBuddyCore() {
        XCTAssertEqual(StreakConfig.default.gracePeriod, 7)
        XCTAssertEqual(StreakConfig.default.slotBoundaryHour, 12)
        XCTAssertFalse(StreakConfig.default.requirePerfectDay)
    }
}
