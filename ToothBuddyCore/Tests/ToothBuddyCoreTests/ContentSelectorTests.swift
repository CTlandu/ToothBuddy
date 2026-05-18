import XCTest
@testable import ToothBuddyCore

/// Spec 03 §5.2 / AC1–AC4, AC7.
final class ContentSelectorTests: XCTestCase {
    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()
    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        DateComponents(calendar: cal, year: y, month: m, day: d).date!
    }

    // AC7 — library integrity.
    func testLibraryIntegrity() {
        let all = ContentLibrary.all
        XCTAssertFalse(all.isEmpty)
        XCTAssertEqual(Set(all.map(\.id)).count, all.count)            // unique ids
        XCTAssertTrue(all.allSatisfy { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty })
        for k in ContentKind.allCases {
            XCTAssertTrue(all.contains { $0.kind == k }, "missing kind \(k)")
        }
    }

    // AC3 — season mapping.
    func testSeasonMapping() {
        XCTAssertEqual(ContentSelector.season(for: date(2026, 12, 15), calendar: cal), .winter)
        XCTAssertEqual(ContentSelector.season(for: date(2026, 4, 1), calendar: cal), .spring)
        XCTAssertEqual(ContentSelector.season(for: date(2026, 7, 1), calendar: cal), .summer)
        XCTAssertEqual(ContentSelector.season(for: date(2026, 10, 10), calendar: cal), .autumn)
        XCTAssertEqual(ContentSelector.season(for: date(2026, 10, 25), calendar: cal), .halloween)
    }

    // AC2 — tone gating.
    func testToneEssentialsOnlyTips() {
        let now = date(2026, 4, 1)
        XCTAssertNil(ContentSelector.pick(kind: .joke, now: now, history: [],
                                          tone: .essentials, calendar: cal))
        XCTAssertNil(ContentSelector.pick(kind: .storyBeat, now: now, history: [],
                                          tone: .essentials, calendar: cal))
        let tip = ContentSelector.pick(kind: .tip, now: now, history: [],
                                       tone: .essentials, calendar: cal)
        XCTAssertEqual(tip?.kind, .tip)
        XCTAssertEqual(tip?.audience, .everyone)
        XCTAssertNotNil(ContentSelector.pick(kind: .joke, now: now, history: [],
                                             tone: .playful, calendar: cal))
    }

    // AC4 — deterministic.
    func testDeterministic() {
        let now = date(2026, 4, 1)
        let a = ContentSelector.pick(kind: .fact, now: now, history: [],
                                     tone: .playful, calendar: cal)
        let b = ContentSelector.pick(kind: .fact, now: now, history: [],
                                     tone: .playful, calendar: cal)
        XCTAssertEqual(a, b)
        XCTAssertNotNil(a)
    }

    // AC1 — no-repeat then reset.
    func testNoRepeatThenReset() {
        let now = date(2026, 4, 1)   // spring → no seasonal tips → neutral (.none) pool
        // The selector's eligible pool for this date is the neutral tips only.
        let tipIDs = ContentLibrary.all
            .filter { $0.kind == .tip && $0.season == .none }.map(\.id)
        XCTAssertGreaterThan(tipIDs.count, 1)

        // History = all tips but one → must return that one.
        let lone = tipIDs.last!
        let allButLone = Array(tipIDs.dropLast())
        let pickedLone = ContentSelector.pick(kind: .tip, now: now, history: allButLone,
                                              tone: .playful, calendar: cal)
        XCTAssertEqual(pickedLone?.id, lone)

        // History = ALL tips (exhausted) → resets, still returns a tip (never nil).
        let afterReset = ContentSelector.pick(kind: .tip, now: now, history: tipIDs,
                                              tone: .playful, calendar: cal)
        XCTAssertNotNil(afterReset)
        XCTAssertEqual(afterReset?.kind, .tip)
    }

    // AC3 — seasonal preference + neutral fallback.
    func testSeasonalPreferenceAndFallback() {
        // Winter → the winter fact is the seasonal pool (single item).
        let winter = ContentSelector.pick(kind: .fact, now: date(2026, 12, 15),
                                          history: [], tone: .playful, calendar: cal)
        XCTAssertEqual(winter?.season, .winter)

        // Summer now HAS a seasonal fact → it is preferred.
        let summer = ContentSelector.pick(kind: .fact, now: date(2026, 7, 1),
                                          history: [], tone: .playful, calendar: cal)
        XCTAssertEqual(summer?.season, .summer)

        // Neutral fallback still works: no spring jokes exist → returns a .none joke.
        let springJoke = ContentSelector.pick(kind: .joke, now: date(2026, 4, 1),
                                              history: [], tone: .playful, calendar: cal)
        XCTAssertEqual(springJoke?.season, ContentSeason.none)
    }

    // P3.4 — every season has flavor; the selector surfaces it.
    func testSeasonalCoverage() {
        let seasons: [(Date, ContentSeason)] = [
            (date(2026, 12, 15), .winter),
            (date(2026, 4, 1),  .spring),
            (date(2026, 7, 1),  .summer),
            (date(2026, 10, 10), .autumn),
            (date(2026, 10, 25), .halloween)
        ]
        for (d, s) in seasons {
            XCTAssertTrue(ContentLibrary.all.contains { $0.season == s },
                          "no content for season \(s)")
            // For at least one kind, the selector returns the seasonal item that day.
            let picks = ContentKind.allCases.compactMap {
                ContentSelector.pick(kind: $0, now: d, history: [],
                                     tone: .playful, calendar: cal)
            }
            XCTAssertTrue(picks.contains { $0.season == s },
                          "selector surfaced no \(s) item on \(d)")
        }
    }
}
