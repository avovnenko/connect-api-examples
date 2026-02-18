import AppKit
import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    let store: SettingsStore
    let manager: ProviderManager
    let deepLinkProvider = DeepLinkProvider()

    @Published var countdownText: String = "-"

    private var cancellables: Set<AnyCancellable> = []
    private var countdownTask: Task<Void, Never>?

    init(store: SettingsStore = SettingsStore()) {
        self.store = store
        self.manager = ProviderManager(store: store)

        manager.$nextUpdateAt
            .sink { [weak self] _ in
                self?.startCountdownLoop()
            }
            .store(in: &cancellables)
    }

    func start() {
        manager.start()
        manager.forceRefresh()
        startCountdownLoop()
    }

    func parseAndSavePasteInput() {
        let result = PasteStatusProvider.parse(store.pastePayload.rawText)
        store.pastePayload.parsedSnapshot = result.0
        store.pastePayload.warnings = result.1
        manager.forceRefresh()
    }

    func saveManualPayload(_ payload: ManualUsagePayload) {
        store.manualPayload = payload
        manager.forceRefresh()
    }

    private func startCountdownLoop() {
        countdownTask?.cancel()
        countdownTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await MainActor.run {
                    guard let next = self.manager.nextUpdateAt else {
                        self.countdownText = "-"
                        return
                    }
                    let remaining = max(0, Int(next.timeIntervalSinceNow))
                    self.countdownText = "\(remaining)s"
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    var menuBarText: String {
        let state = indicatorState(snapshot: manager.snapshot, thresholds: store.thresholds)
        let dot: String
        switch state {
        case .green: dot = "🟢"
        case .yellow: dot = "🟡"
        case .red: dot = "🔴"
        case .gray: dot = "⚪️"
        }

        guard store.showPercentInMenuBar,
              let pct = manager.snapshot?.fiveHour.pctUsed ?? manager.snapshot?.weekly.pctUsed else {
            return dot
        }

        return "\(dot) \(Int(pct * 100))%"
    }
}
