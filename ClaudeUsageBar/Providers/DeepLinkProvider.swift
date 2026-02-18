import AppKit
import Foundation

final class DeepLinkProvider: UsageProvider {
    var name: String { "Deep Link" }
    var supportsAutoRefresh: Bool { false }

    func fetchSnapshot() async throws -> UsageSnapshot {
        UsageSnapshot(timestamp: Date(), fiveHour: .empty, weekly: .empty, connectivity: .unavailable)
    }

    func openUsagePage() {
        guard let url = URL(string: "https://claude.ai/settings/usage") else { return }
        NSWorkspace.shared.open(url)
    }
}
