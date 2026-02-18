import Foundation

final class PasteStatusProvider: UsageProvider {
    var name: String { "Paste from /status" }
    var supportsAutoRefresh: Bool { true }

    private let storage: AppStorage

    init(storage: AppStorage) {
        self.storage = storage
    }

    func fetchSnapshot() async throws -> UsageSnapshot {
        let state = storage.loadInputState()
        guard !state.lastPastedStatusText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return UsageSnapshot(timestamp: Date(), fiveHour: .empty, weekly: .empty, connectivity: .unavailable)
        }
        let parsed = StatusTextParser.parse(text: state.lastPastedStatusText)
        var nextState = state
        nextState.lastParseWarnings = parsed.warnings
        storage.saveInputState(nextState)
        return parsed.snapshot.normalized()
    }

    func parseAndStore(text: String) -> StatusTextParser.ParseResult {
        let parsed = StatusTextParser.parse(text: text)
        var state = storage.loadInputState()
        state.lastPastedStatusText = text
        state.lastParseWarnings = parsed.warnings
        storage.saveInputState(state)
        return parsed
    }
}
