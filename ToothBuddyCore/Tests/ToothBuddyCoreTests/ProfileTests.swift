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
}
