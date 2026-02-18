import Foundation

protocol UsageProvider {
    var name: String { get }
    var supportsAutoRefresh: Bool { get }
    func fetchSnapshot() async throws -> UsageSnapshot
}

enum UsageProviderType: String, CaseIterable, Codable, Identifiable {
    case manual
    case pasteStatus
    case deepLink

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .manual: return "Manual Entry"
        case .pasteStatus: return "Paste from Claude Code"
        case .deepLink: return "Deep Link"
        }
    }
}

struct BackoffPolicy: Equatable {
    private let schedule: [TimeInterval] = [60, 120, 300, 600]

    func delay(forFailureCount failures: Int) -> TimeInterval {
        let safeFailures = max(0, failures)
        let index = min(safeFailures, schedule.count - 1)
        return schedule[index]
    }
}
