import XCTest
@testable import ClaudeUsageMenuBar

final class IndicatorStateTests: XCTestCase {
    func testIndicatorThresholdMapping() {
        let thresholds = ThresholdSettings(yellowThreshold: 0.6, redThreshold: 0.85)

        let greenSnapshot = UsageSnapshot(
            timestamp: .now,
            fiveHour: UsageWindow.normalized(used: 20, limit: 100, remaining: nil, resetAt: nil),
            weekly: .empty,
            connectivity: .connected
        )
        XCTAssertEqual(indicatorState(snapshot: greenSnapshot, thresholds: thresholds), .green)

        let yellowSnapshot = UsageSnapshot(
            timestamp: .now,
            fiveHour: UsageWindow.normalized(used: 70, limit: 100, remaining: nil, resetAt: nil),
            weekly: .empty,
            connectivity: .connected
        )
        XCTAssertEqual(indicatorState(snapshot: yellowSnapshot, thresholds: thresholds), .yellow)

        let redSnapshot = UsageSnapshot(
            timestamp: .now,
            fiveHour: UsageWindow.normalized(used: 90, limit: 100, remaining: nil, resetAt: nil),
            weekly: .empty,
            connectivity: .connected
        )
        XCTAssertEqual(indicatorState(snapshot: redSnapshot, thresholds: thresholds), .red)

        XCTAssertEqual(indicatorState(snapshot: UsageSnapshot.unavailable(), thresholds: thresholds), .gray)
    }
}
