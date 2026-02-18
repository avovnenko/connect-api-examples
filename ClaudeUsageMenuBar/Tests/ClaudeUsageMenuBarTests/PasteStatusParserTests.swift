import XCTest
@testable import ClaudeUsageMenuBar

final class PasteStatusParserTests: XCTestCase {
    func testParseKnownLinesAndWarnings() {
        let input = """
        5h usage: 35/100 (35%) remaining 65
        week usage: 180/500 (36%)
        some random line to ignore
        """

        let result = PasteStatusProvider.parse(input)
        XCTAssertNotNil(result.0)
        XCTAssertEqual(result.0?.fiveHour.used, 35)
        XCTAssertEqual(result.0?.fiveHour.limit, 100)
        XCTAssertEqual(result.0?.weekly.used, 180)
        XCTAssertEqual(result.0?.weekly.limit, 500)
        XCTAssertFalse(result.1.isEmpty)
    }

    func testParseUnknownOnly() {
        let input = """
        hello world
        status unavailable
        """

        let result = PasteStatusProvider.parse(input)
        XCTAssertNil(result.0)
        XCTAssertTrue(result.1.contains { $0.contains("No recognizable") })
    }
}
