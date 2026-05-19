import XCTest
@testable import ToothBuddyCore

final class ProfileTests: XCTestCase {
    func testValidatedNameTrimsAndAccepts() {
        XCTAssertEqual(Profile.validatedName("  Leo  "), "Leo")
        XCTAssertEqual(Profile.validatedName("Mom"), "Mom")
        XCTAssertEqual(Profile.validatedName(String(repeating: "x", count: 24))?.count, 24)
    }

    func testValidatedNameRejectsEmptyAndTooLong() {
        XCTAssertNil(Profile.validatedName(""))
        XCTAssertNil(Profile.validatedName("   \n  "))
        XCTAssertNil(Profile.validatedName(String(repeating: "x", count: 25)))
    }

    func testSymbolMapsToValidSFSymbolNames() {
        for s in ProfileSymbol.allCases {
            XCTAssertFalse(s.systemImage.isEmpty)
            XCTAssertTrue(s.systemImage.contains(".") || s.systemImage == "sparkles")
        }
    }

    func testMigrationDefaultIsNamedMe() {
        let p = Profile.migrationDefault()
        XCTAssertEqual(p.name, "Me")
        XCTAssertEqual(p.createdAt, p.modifiedAt)
    }

    func testCodableRoundTrip() throws {
        let p = Profile(name: "Mia", colorTag: .grape, symbol: .heart,
                        birthYear: 2016, creatorLabel: "Dad's phone")
        let decoded = try JSONDecoder().decode(Profile.self,
                                               from: JSONEncoder().encode(p))
        XCTAssertEqual(decoded, p)
    }

    // Spec 05 AC1 — mode defaults to .kid; pre-P5 JSON (no "mode") decodes as .kid.
    func testModeDefaultsToKid() {
        let p = Profile(name: "Leo", colorTag: .sky, symbol: .star)
        XCTAssertEqual(p.mode, .kid)
        XCTAssertEqual(Profile.migrationDefault().mode, .kid)
    }

    func testDecodingLegacyProfileWithoutModeYieldsKid() throws {
        // A profile JSON exactly as persisted before P5 — no "mode" key.
        let legacy = """
        {"id":"\(UUID().uuidString)","name":"Old","colorTag":"sky","symbol":"star",
         "creatorLabel":"","createdAt":0,"modifiedAt":0}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Profile.self, from: legacy)
        XCTAssertEqual(decoded.mode, .kid)
        XCTAssertEqual(decoded.name, "Old")
    }

    func testModeRoundTripsWhenAdult() throws {
        let p = Profile(name: "Sam", colorTag: .mint, symbol: .leaf, mode: .adult)
        let decoded = try JSONDecoder().decode(Profile.self,
                                               from: JSONEncoder().encode(p))
        XCTAssertEqual(decoded.mode, .adult)
        XCTAssertEqual(decoded, p)
    }
}
