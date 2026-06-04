import XCTest
@testable import ToothBuddyCore

/// U3 — SessionClock accumulates only active (non-paused) segments, so a session's
/// duration never inflates with background / interruption time.
final class SessionClockTests: XCTestCase {

    func testSingleRunningSegment() {
        let c = SessionClock(startedAt: 0)
        XCTAssertEqual(c.activeSeconds(asOf: 30), 30)
        XCTAssertFalse(c.isPaused)
    }

    func testPauseExcludesGap() {
        // Active 0–20, then paused. Querying later still reads 20.
        let c = SessionClock(startedAt: 0).paused(at: 20)
        XCTAssertEqual(c.activeSeconds(asOf: 30), 20)
        XCTAssertEqual(c.activeSeconds(asOf: 999), 20)
        XCTAssertTrue(c.isPaused)
    }

    func testResumeContinuesAccumulating() {
        // Active 0–20 (=20), paused 20–30, active 30–45 (=15) → 35.
        let c = SessionClock(startedAt: 0).paused(at: 20).resumed(at: 30)
        XCTAssertEqual(c.activeSeconds(asOf: 45), 35)
        XCTAssertFalse(c.isPaused)
    }

    func testMultiplePauseResumeCycles() {
        // active 0–10 (10), pause 10–20, active 20–25 (5), pause 25–40, active 40–50 (10) = 25.
        let c = SessionClock(startedAt: 0)
            .paused(at: 10).resumed(at: 20)
            .paused(at: 25).resumed(at: 40)
        XCTAssertEqual(c.activeSeconds(asOf: 50), 25)
    }

    func testNeverExceedsWallClock() {
        // Whatever the transitions, active time can't exceed elapsed wall time.
        let start = 100.0
        let c = SessionClock(startedAt: start)
            .paused(at: 110).resumed(at: 130).paused(at: 140).resumed(at: 200)
        let now = 250.0
        XCTAssertLessThanOrEqual(c.activeSeconds(asOf: now), Int(now - start))
    }

    func testZeroLengthPauseThenResume() {
        // Pause and resume at the same instant: no time lost, no time double-counted.
        let c = SessionClock(startedAt: 0).paused(at: 10).resumed(at: 10)
        XCTAssertEqual(c.activeSeconds(asOf: 20), 20)
    }

    func testIdempotentPause() {
        // Pausing while already paused does not advance or rewind accumulated time.
        let c = SessionClock(startedAt: 0).paused(at: 10).paused(at: 20)
        XCTAssertEqual(c.activeSeconds(asOf: 30), 10)
        XCTAssertTrue(c.isPaused)
    }

    func testIdempotentResume() {
        // Resuming while already running is a no-op (does not reset the open segment).
        let c = SessionClock(startedAt: 0).resumed(at: 10)
        XCTAssertEqual(c.activeSeconds(asOf: 30), 30)
        XCTAssertFalse(c.isPaused)
    }

    func testQueryWhilePausedIgnoresLaterTimestamps() {
        let c = SessionClock(startedAt: 0).paused(at: 20)
        // Even though we query "as of 1000", the open segment is closed → still 20.
        XCTAssertEqual(c.activeSeconds(asOf: 1000), 20)
    }

    func testDeterministicReplay() {
        func build() -> SessionClock {
            SessionClock(startedAt: 5).paused(at: 15).resumed(at: 25).paused(at: 30).resumed(at: 50)
        }
        XCTAssertEqual(build(), build())
        XCTAssertEqual(build().activeSeconds(asOf: 60), build().activeSeconds(asOf: 60))
    }

    func testOutOfOrderTimestampDoesNotGoNegative() {
        // Defensive: a pause timestamp before the segment start clamps at 0, not negative.
        let c = SessionClock(startedAt: 100).paused(at: 90)
        XCTAssertEqual(c.activeSeconds(asOf: 200), 0)
    }
}
