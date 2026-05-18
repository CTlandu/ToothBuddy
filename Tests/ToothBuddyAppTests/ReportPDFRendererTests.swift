import XCTest
import ToothBuddyCore
@testable import ToothBuddy

/// Spec 02 §6.7 — PDF rendering is smoke-only; this just proves it produces a valid,
/// non-empty PDF from report data (the numbers are tested in Core's ReportBuilderTests).
final class ReportPDFRendererTests: XCTestCase {

    func testRendersNonEmptyValidPDF() {
        let pid = UUID()
        let cal = Calendar.current
        let end = Date()
        let start = cal.date(byAdding: .day, value: -29, to: end)!
        let rec = BrushingRecord(profileID: pid, startDate: start,
                                 endDate: start.addingTimeInterval(130))
        let data = ReportBuilder.build(profileID: pid, profileName: "Mia",
                                       in: [rec], start: start, end: end, now: end,
                                       config: .default, calendar: cal)

        let pdf = ReportPDFRenderer.render(data)
        XCTAssertGreaterThan(pdf.count, 500)
        XCTAssertEqual(String(decoding: pdf.prefix(4), as: UTF8.self), "%PDF")

        let url = ReportPDFRenderer.writeTempPDF(data)
        XCTAssertNotNil(url)
        if let url { XCTAssertTrue(FileManager.default.fileExists(atPath: url.path)) }
    }
}
