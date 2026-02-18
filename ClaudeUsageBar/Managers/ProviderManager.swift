import Combine
import Foundation

@MainActor
final class ProviderManager: ObservableObject {
    @Published private(set) var snapshot: UsageSnapshot?
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var nextRefreshAt: Date?
    @Published private(set) var parseWarnings: [String] = []
    @Published var settings: AppSettings {
        didSet {
            storage.saveSettings(settings)
        }
    }
    @Published var inputState: PersistedInputState {
        didSet {
            storage.saveInputState(inputState)
        }
    }

    private let storage: AppStorage
    private var refreshTask: Task<Void, Never>?
    private var scheduler = BackoffScheduler()

    private lazy var manualProvider = ManualEntryProvider(storage: storage)
    private lazy var pasteProvider = PasteStatusProvider(storage: storage)
    private lazy var deepLinkProvider = DeepLinkProvider()

    init(storage: AppStorage = AppStorage()) {
        self.storage = storage
        self.settings = storage.loadSettings()
        self.inputState = storage.loadInputState()
        self.snapshot = storage.loadLastSnapshot()
        self.parseWarnings = inputState.lastParseWarnings
    }

    var currentProvider: UsageProvider {
        switch settings.selectedProvider {
        case .manualEntry: return manualProvider
        case .pasteStatus: return pasteProvider
        case .deepLink: return deepLinkProvider
        }
    }

    func start() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshLoop()
        }
    }

    func stop() {
        refreshTask?.cancel()
    }

    func selectProvider(_ provider: ProviderKind) {
        settings.selectedProvider = provider
        scheduler.registerSuccess()
        Task { await refreshNow(force: true) }
    }

    func refreshNow(force: Bool = false) async {
        do {
            let fetched = try await currentProvider.fetchSnapshot().normalized()
            scheduler.registerSuccess()
            nextRefreshAt = Date().addingTimeInterval(currentProvider.supportsAutoRefresh ? settings.refreshInterval : 0)
            parseWarnings = storage.loadInputState().lastParseWarnings
            if force || snapshot?.isMeaningfullyDifferent(from: fetched) != false {
                snapshot = fetched
                lastUpdated = Date()
                storage.saveSnapshot(fetched)
            }
        } catch {
            scheduler.registerFailure()
            nextRefreshAt = Date().addingTimeInterval(scheduler.nextInterval(base: settings.refreshInterval))
        }
    }

    func saveManualValues(fiveHour: UsageWindow, weekly: UsageWindow) async {
        inputState.manualFiveHour = fiveHour
        inputState.manualWeekly = weekly
        if settings.selectedProvider == .manualEntry {
            await refreshNow(force: true)
        }
    }

    func parseAndSaveStatus(_ text: String) async {
        let result = pasteProvider.parseAndStore(text: text)
        inputState.lastPastedStatusText = text
        inputState.lastParseWarnings = result.warnings
        parseWarnings = result.warnings
        if settings.selectedProvider == .pasteStatus {
            await refreshNow(force: true)
        }
    }

    func openUsagePage() {
        deepLinkProvider.openUsagePage()
    }

    private func refreshLoop() async {
        while !Task.isCancelled {
            await refreshNow()
            let interval: TimeInterval
            if currentProvider.supportsAutoRefresh {
                interval = scheduler.nextInterval(base: settings.refreshInterval)
            } else {
                interval = max(settings.refreshInterval, 30)
            }
            nextRefreshAt = Date().addingTimeInterval(interval)
            do {
                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            } catch {
                break
            }
        }
    }
}
