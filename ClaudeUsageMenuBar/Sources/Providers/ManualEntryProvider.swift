import Foundation

struct ManualEntryProvider: UsageProvider {
    let store: SettingsStore

    var name: String { "Manual Entry" }
    var supportsAutoRefresh: Bool { false }

    func fetchSnapshot() async throws -> UsageSnapshot {
        let payload = await MainActor.run { store.manualPayload }
        return UsageSnapshot(
            timestamp: .now,
            fiveHour: payload.fiveHour,
            weekly: payload.weekly,
            connectivity: .manual
        )
    }
}
