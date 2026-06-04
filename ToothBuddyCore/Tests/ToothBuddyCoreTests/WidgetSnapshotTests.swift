import XCTest
@testable import ToothBuddyCore

/// Spec 05 §6.4 / AC4 — pure widget snapshot: streak/slot correctness, atRisk band,
/// profile isolation, determinism, Codable round-trip.
final class WidgetSnapshotTests: XCTestCase {
    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()
    private var base: Date { DateComponents(calendar: cal, year: 2026, month: 5, day: 18).date! }
    private func at(_ d: Int, _ h: Int) -> Date {
        cal.date(byAdding: .hour, value: h, to: cal.date(byAdding: .day, value: d, to: base)!)!
    }
    private func rec(_ pid: UUID, _ d: Int, _ h: Int) -> BrushingRecord {
        let s = at(d, h)
        return BrushingRecord(profileID: pid, startDate: s, endDate: s.addingTimeInterval(130))
    }
    private func build(_ pid: UUID, _ all: [BrushingRecord], now: Date) -> WidgetSnapshot {
        WidgetSnapshotBuilder.build(records: all, profileID: pid, profileName: "Mia",
                                    asOf: now, calendar: cal)
    }

    func testSlotsAndNameAndDeterminism() {
        let p = UUID()
        let s = build(p, [rec(p, 0, 8), rec(p, 0, 20)], now: at(0, 21))
        XCTAssertEqual(s.profileName, "Mia")
        XCTAssertTrue(s.amDone)
        XCTAssertTrue(s.pmDone)
        XCTAssertFalse(s.atRisk)                       // pm done → not at risk
        XCTAssertEqual(s, build(p, [rec(p, 0, 8), rec(p, 0, 20)], now: at(0, 21)))
    }

    func testAtRiskOnlyWhenEveningPendingLate() {
        let p = UUID()
        XCTAssertFalse(build(p, [rec(p, 0, 8)], now: at(0, 18)).atRisk)   // 18:00 → not yet
        XCTAssertTrue(build(p, [rec(p, 0, 8)], now: at(0, 21)).atRisk)    // 21:00, pm pending
        XCTAssertFalse(build(p, [rec(p, 0, 21)], now: at(0, 22)).atRisk)  // pm done
    }

    func testProfileIsolation() {
        let p = UUID(), other = UUID()
        let s = build(p, [rec(other, 0, 8), rec(other, 0, 20)], now: at(0, 9))
        XCTAssertFalse(s.amDone)
        XCTAssertFalse(s.pmDone)
        XCTAssertEqual(s.currentStreak, 0)
    }

    func testStreakMatchesEngine() {
        let p = UUID()
        let recs = (0...3).flatMap { [rec(p, -$0, 8), rec(p, -$0, 20)] }
        let s = build(p, recs, now: at(0, 12))
        let direct = StreakEngine.evaluate(records: recs, now: at(0, 12),
                                           config: .default, calendar: cal)
        XCTAssertEqual(s.currentStreak, direct.currentStreak)
        XCTAssertGreaterThanOrEqual(s.currentStreak, 4)
    }

    func testCodableRoundTrip() throws {
        let p = UUID()
        let s = build(p, [rec(p, 0, 8)], now: at(0, 21))
        let back = try JSONDecoder().decode(WidgetSnapshot.self,
                                            from: JSONEncoder().encode(s))
        XCTAssertEqual(back, s)
        XCTAssertEqual(WidgetSnapshot.placeholder.profileName, "ToothBuddy")
    }

    func testQualityFieldsFromEnrichedRecords() {
        let p = UUID()
        let s0 = at(0, 8)
        let full = Dictionary(uniqueKeysWithValues: CoarseZone.allCases.map { ($0, 20) })
        let thorough = BrushingRecord(profileID: p, startDate: s0,
                                      endDate: s0.addingTimeInterval(120),
                                      activeSeconds: 120, targetSeconds: 120,
                                      coverage: full, cameraVerified: true, guidanceMode: .camera)
        let s = build(p, [thorough], now: at(0, 21))
        XCTAssertEqual(s.todayThoroughCount, 1)
        XCTAssertEqual(s.lastZonesMet, 6)
        XCTAssertTrue(s.lastVerified)
    }

    func testLegacySnapshotDecodesWithoutQualityKeys() throws {
        // A pre-U12 snapshot (no quality keys) must still decode (defaults), not fail.
        let json = """
        {"profileName":"Mia","currentStreak":3,"amDone":true,"pmDone":false,\
        "atRisk":false,"asOf":0}
        """
        let s = try JSONDecoder().decode(WidgetSnapshot.self, from: Data(json.utf8))
        XCTAssertEqual(s.currentStreak, 3)
        XCTAssertEqual(s.todayThoroughCount, 0)
        XCTAssertEqual(s.lastZonesMet, 0)
        XCTAssertFalse(s.lastVerified)
    }
}
