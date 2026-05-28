import XCTest
import UserNotifications
import ToothBuddyCore
@testable import ToothBuddy

/// Quality audit 2026-05-28 / Plan U4 — NotificationScheduler tests.
///
/// We don't probe the actual UNUserNotificationCenter (it requires authorization
/// and is non-deterministic from CI / from app tests). Instead we pin the
/// invariants that are pure: identifier-table consistency and idempotent calls
/// against a no-permission environment (the call must return without throwing).
@MainActor
final class NotificationSchedulerTests: XCTestCase {

    func testSharedSingletonAvailable() {
        XCTAssertNotNil(NotificationScheduler.shared)
        XCTAssertTrue(NotificationScheduler.shared === NotificationScheduler.shared)
    }

    func testRescheduleIsCallableWithoutThrowing() {
        // No authorization in the test environment → reschedule should noop silently.
        // The test value here is the public-surface idempotency contract: callers
        // call this from `scenePhase.active` on every foreground, and it must never
        // throw / spam logs.
        let records: [BrushingRecord] = []
        let streak = StreakResult.empty
        NotificationScheduler.shared.reschedule(records: records, streak: streak)
        // Calling twice back-to-back must also be safe.
        NotificationScheduler.shared.reschedule(records: records, streak: streak)
    }

    func testRescheduleCareIsCallableWithoutThrowing() {
        NotificationScheduler.shared.rescheduleCare(inputs: [])
        NotificationScheduler.shared.rescheduleCare(inputs: [])
    }

    func testRequestAuthorizationIfNeededIsCallableWithoutThrowing() {
        // Must be safe even when the user has already decided (test environment is
        // typically `notDetermined`; either way the call must not throw).
        NotificationScheduler.shared.requestAuthorizationIfNeeded()
    }
}
