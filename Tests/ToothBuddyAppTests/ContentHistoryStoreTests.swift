import XCTest
import ToothBuddyCore
@testable import ToothBuddy

/// Spec 03 §6 — the per-device "don't repeat" ring + tone setting.
@MainActor
final class ContentHistoryStoreTests: XCTestCase {

    override func setUp() {
        UserDefaults.standard.removeObject(forKey: "ToothBuddy.contentHistory")
        UserDefaults.standard.removeObject(forKey: "ToothBuddy.contentTone")
    }

    func testRecordDedupesAndCapsAtEight() {
        let s = ContentHistoryStore.shared
        var ids: [UUID] = []
        for _ in 0..<12 { let id = UUID(); ids.append(id); s.record(id) }
        let recent = s.recent()
        XCTAssertEqual(recent.count, 8)                       // capped
        XCTAssertEqual(recent, Array(ids.suffix(8)))          // newest 8, in order

        // Re-recording an existing id moves it to the end, no duplicate.
        let again = ids[ids.count - 1]
        s.record(again)
        XCTAssertEqual(s.recent().filter { $0 == again }.count, 1)
        XCTAssertEqual(s.recent().last, again)
    }

    func testToneRoundTrips() {
        let s = ContentHistoryStore.shared
        XCTAssertEqual(s.tone, .playful)                      // default
        s.setTone(.essentials)
        XCTAssertEqual(s.tone, .essentials)
        s.setTone(.playful)
        XCTAssertEqual(s.tone, .playful)
    }
}
