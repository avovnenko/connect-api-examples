import XCTest
@testable import ClaudeUsageBar

final class UsageLogicTests: XCTestCase {
    func testThresholdMapping() {
        let settings = AppSettings(yellowThreshold: 60, redThreshold: 85, refreshInterval: 60, showPercentInMenuBar: true, selectedProvider: .manualEntry)

        let green = UsageSnapshot(timestamp: .now, fiveHour: UsageWindow(pctUsed: 20), weekly: .empty, connectivity: .connected)
        XCTAssertEqual(StatusEvaluator.severity(for: green, settings: settings), .green)

        let yellow = UsageSnapshot(timestamp: .now, fiveHour: UsageWindow(pctUsed: 70), weekly: .empty, connectivity: .connected)
        XCTAssertEqual(StatusEvaluator.severity(for: yellow, settings: settings), .yellow)

        let red = UsageSnapshot(timestamp: .now, fiveHour: UsageWindow(pctUsed: 90), weekly: .empty, connectivity: .connected)
        XCTAssertEqual(StatusEvaluator.severity(for: red, settings: settings), .red)

        XCTAssertEqual(StatusEvaluator.severity(for: nil, settings: settings), .gray)
    }

    func testBackoffSchedule() {
        var scheduler = BackoffScheduler()
        XCTAssertEqual(scheduler.nextInterval(base: 60), 60)

        scheduler.registerFailure()
        XCTAssertEqual(scheduler.nextInterval(base: 60), 120)

        scheduler.registerFailure()
        XCTAssertEqual(scheduler.nextInterval(base: 60), 300)

        scheduler.registerFailure()
        XCTAssertEqual(scheduler.nextInterval(base: 60), 600)

        scheduler.registerSuccess()
        XCTAssertEqual(scheduler.nextInterval(base: 60), 60)
    }

    func testStatusParsingWithUnknownLines() {
        let input = """
        5h used 20/100 (20%) remaining 80 reset 2026-01-01T12:00:00Z
        weekly usage: 120/500 remaining 380 reset 2026-01-04T00:00:00Z
        random line here
        """

        let result = StatusTextParser.parse(text: input, now: Date(timeIntervalSince1970: 0))

        XCTAssertEqual(result.snapshot.fiveHour.used, 20)
        XCTAssertEqual(result.snapshot.fiveHour.limit, 100)
        XCTAssertEqual(result.snapshot.weekly.used, 120)
        XCTAssertEqual(result.snapshot.weekly.limit, 500)
        XCTAssertEqual(result.snapshot.connectivity, .connected)
        XCTAssertFalse(result.warnings.isEmpty)
    }
}
