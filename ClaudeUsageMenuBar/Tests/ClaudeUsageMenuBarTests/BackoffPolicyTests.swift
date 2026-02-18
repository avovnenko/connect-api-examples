import XCTest
@testable import ClaudeUsageMenuBar

final class BackoffPolicyTests: XCTestCase {
    func testBackoffSchedule() {
        let policy = BackoffPolicy()

        XCTAssertEqual(policy.delay(forFailureCount: 0), 60)
        XCTAssertEqual(policy.delay(forFailureCount: 1), 120)
        XCTAssertEqual(policy.delay(forFailureCount: 2), 300)
        XCTAssertEqual(policy.delay(forFailureCount: 3), 600)
        XCTAssertEqual(policy.delay(forFailureCount: 10), 600)
    }
}
