import Foundation

final class AppStorage {
    private enum Keys {
        static let settings = "ClaudeUsageBar.settings"
        static let inputState = "ClaudeUsageBar.inputState"
        static let lastSnapshot = "ClaudeUsageBar.lastSnapshot"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
    }

    func loadSettings() -> AppSettings {
        guard
            let data = defaults.data(forKey: Keys.settings),
            let settings = try? decoder.decode(AppSettings.self, from: data)
        else {
            return .default
        }
        return settings
    }

    func saveSettings(_ settings: AppSettings) {
        guard let data = try? encoder.encode(settings) else { return }
        defaults.set(data, forKey: Keys.settings)
    }

    func loadInputState() -> PersistedInputState {
        guard
            let data = defaults.data(forKey: Keys.inputState),
            let state = try? decoder.decode(PersistedInputState.self, from: data)
        else {
            return .default
        }
        return state
    }

    func saveInputState(_ state: PersistedInputState) {
        guard let data = try? encoder.encode(state) else { return }
        defaults.set(data, forKey: Keys.inputState)
    }

    func loadLastSnapshot() -> UsageSnapshot? {
        guard
            let data = defaults.data(forKey: Keys.lastSnapshot),
            let snapshot = try? decoder.decode(UsageSnapshot.self, from: data)
        else {
            return nil
        }
        return snapshot
    }

    func saveSnapshot(_ snapshot: UsageSnapshot) {
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: Keys.lastSnapshot)
    }
}
