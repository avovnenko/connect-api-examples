import AppKit
import Foundation

struct DeepLinkProvider: UsageProvider {
    var name: String { "Deep Link" }
    var supportsAutoRefresh: Bool { false }

    func fetchSnapshot() async throws -> UsageSnapshot {
        UsageSnapshot.unavailable()
    }

    func openUsagePage() {
        guard let url = URL(string: "https://claude.ai/settings/usage") else { return }
        NSWorkspace.shared.open(url)
    }
}
