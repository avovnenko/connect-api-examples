import Foundation

protocol UsageProvider {
    var name: String { get }
    var supportsAutoRefresh: Bool { get }
    func fetchSnapshot() async throws -> UsageSnapshot
}

enum UsageProviderError: Error {
    case unavailable
}
