import Foundation

@MainActor
final class ProviderManager: ObservableObject {
    @Published private(set) var snapshot: UsageSnapshot?
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var nextUpdateAt: Date?
    @Published private(set) var lastErrorDescription: String?

    private let store: SettingsStore
    private let backoff = BackoffPolicy()
    private var refreshTask: Task<Void, Never>?
    private var failureCount = 0

    init(store: SettingsStore) {
        self.store = store
    }

    deinit {
        refreshTask?.cancel()
    }

    func start() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            await self?.runLoop()
        }
    }

    func forceRefresh() {
        Task { [weak self] in
            await self?.refreshOnce()
        }
    }

    private func provider(for type: UsageProviderType) -> UsageProvider {
        switch type {
        case .manual:
            return ManualEntryProvider(store: store)
        case .pasteStatus:
            return PasteStatusProvider(store: store)
        case .deepLink:
            return DeepLinkProvider()
        }
    }

    private func runLoop() async {
        while !Task.isCancelled {
            await refreshOnce()

            let currentProvider = provider(for: store.selectedProvider)
            if !currentProvider.supportsAutoRefresh {
                nextUpdateAt = nil
                try? await Task.sleep(for: .seconds(1))
                continue
            }

            let base = max(15, store.refreshIntervalSeconds)
            let failureDelay = backoff.delay(forFailureCount: failureCount)
            let delay = failureCount == 0 ? base : max(base, failureDelay)

            nextUpdateAt = Date().addingTimeInterval(delay)
            try? await Task.sleep(for: .seconds(delay))
        }
    }

    private func refreshOnce() async {
        let currentProvider = provider(for: store.selectedProvider)

        do {
            let newSnapshot = try await currentProvider.fetchSnapshot()
            if hasMeaningfulChange(old: snapshot, new: newSnapshot) {
                snapshot = newSnapshot
            }
            failureCount = 0
            lastUpdated = .now
            lastErrorDescription = nil
        } catch {
            failureCount += 1
            lastErrorDescription = error.localizedDescription
        }
    }

    private func hasMeaningfulChange(old: UsageSnapshot?, new: UsageSnapshot) -> Bool {
        guard let old else { return true }
        return old.connectivity != new.connectivity
            || old.fiveHour != new.fiveHour
            || old.weekly != new.weekly
    }
}
