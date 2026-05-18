import XCTest
@testable import ToothBuddyCore

/// Spec 03 §5.3 / AC5.
final class SessionScriptTests: XCTestCase {
    private let cal = Calendar(identifier: .gregorian)
    private func item() -> ContentItem {
        ContentItem(kind: .fact, text: "Enamel is the hardest stuff your body makes!")
    }

    func testPlayful120HasIntroQuadrantsContentWrap() {
        let s = SessionScript.build(durationSeconds: 120, tone: .playful,
                                    content: item(), calendar: cal)
        XCTAssertEqual(s.first?.kind, .intro)
        XCTAssertEqual(s.first?.atSecond, 0)

        let quads = s.filter { $0.kind == .quadrant }
        XCTAssertEqual(quads.count, 4)
        XCTAssertEqual(quads.map(\.atSecond), [0, 30, 60, 90])

        XCTAssertEqual(s.filter { $0.kind == .content }.count, 1)
        XCTAssertEqual(s.first { $0.kind == .content }?.atSecond, 60)

        let wrap = s.last
        XCTAssertEqual(wrap?.kind, .wrap)
        XCTAssertEqual(wrap?.atSecond, 120)
        XCTAssertTrue(s.contains { $0.kind == .encourage })
    }

    func testEssentialsNilContentOmitsContentCue() {
        let s = SessionScript.build(durationSeconds: 120, tone: .essentials,
                                    content: nil, calendar: cal)
        XCTAssertTrue(s.allSatisfy { $0.kind != .content })
        XCTAssertEqual(s.filter { $0.kind == .quadrant }.count, 4)
        XCTAssertEqual(s.last?.kind, .wrap)
        XCTAssertEqual(s.first?.text, "Two-minute brush. Let's begin.")
    }

    func testSortedAscendingByTime() {
        let s = SessionScript.build(durationSeconds: 120, tone: .playful,
                                    content: item(), calendar: cal)
        XCTAssertEqual(s.map(\.atSecond), s.map(\.atSecond).sorted())
        // intro precedes the t=0 quadrant.
        XCTAssertEqual(s[0].kind, .intro)
        XCTAssertEqual(s[1].kind, .quadrant)
    }

    func testDeterministic() {
        let a = SessionScript.build(durationSeconds: 120, tone: .playful,
                                    content: item(), calendar: cal)
        let b = SessionScript.build(durationSeconds: 120, tone: .playful,
                                    content: item(), calendar: cal)
        XCTAssertEqual(a, b)
    }

    func testShortDurationClamped() {
        let s = SessionScript.build(durationSeconds: 5, tone: .playful,
                                    content: nil, calendar: cal)
        XCTAssertEqual(s.last?.atSecond, 20)        // floored to 20s
        XCTAssertEqual(s.filter { $0.kind == .quadrant }.count, 4)
    }
}
