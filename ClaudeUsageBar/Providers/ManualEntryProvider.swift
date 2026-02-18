import Foundation

final class ManualEntryProvider: UsageProvider {
    var name: String { "Manual Entry" }
    var supportsAutoRefresh: Bool { false }

    private let storage: AppStorage

    init(storage: AppStorage) {
        self.storage = storage
    }

    func fetchSnapshot() async throws -> UsageSnapshot {
        let state = storage.loadInputState()
        return UsageSnapshot(
            timestamp: Date(),
            fiveHour: state.manualFiveHour.normalized(),
            weekly: state.manualWeekly.normalized(),
            connectivity: .manual
        )
    }
}
