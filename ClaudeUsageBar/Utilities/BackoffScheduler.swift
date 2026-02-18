import Foundation

struct BackoffScheduler {
    private(set) var failureCount: Int = 0

    mutating func registerSuccess() {
        failureCount = 0
    }

    mutating func registerFailure() {
        failureCount += 1
    }

    func nextInterval(base: TimeInterval) -> TimeInterval {
        switch failureCount {
        case 0: return base
        case 1: return max(base, 120)
        case 2: return max(base, 300)
        default: return max(base, 600)
        }
    }
}
