import Foundation

struct ManualUsagePayload: Codable, Equatable {
    var fiveHour: UsageWindow
    var weekly: UsageWindow

    static let empty = ManualUsagePayload(fiveHour: .empty, weekly: .empty)
}

struct PastePayload: Codable, Equatable {
    var rawText: String
    var parsedSnapshot: UsageSnapshot?
    var warnings: [String]

    static let empty = PastePayload(rawText: "", parsedSnapshot: nil, warnings: [])
}

@MainActor
final class SettingsStore: ObservableObject {
    @Published var thresholds: ThresholdSettings {
        didSet { save(thresholds, key: Keys.thresholds) }
    }

    @Published var refreshIntervalSeconds: TimeInterval {
        didSet { defaults.set(refreshIntervalSeconds, forKey: Keys.refreshIntervalSeconds) }
    }

    @Published var showPercentInMenuBar: Bool {
        didSet { defaults.set(showPercentInMenuBar, forKey: Keys.showPercentInMenuBar) }
    }

    @Published var selectedProvider: UsageProviderType {
        didSet { defaults.set(selectedProvider.rawValue, forKey: Keys.selectedProvider) }
    }

    @Published var manualPayload: ManualUsagePayload {
        didSet { save(manualPayload, key: Keys.manualPayload) }
    }

    @Published var pastePayload: PastePayload {
        didSet { save(pastePayload, key: Keys.pastePayload) }
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        self.thresholds = Self.load(
            defaults: defaults,
            decoder: decoder,
            key: Keys.thresholds,
            fallback: .default
        )

        let refresh = defaults.double(forKey: Keys.refreshIntervalSeconds)
        self.refreshIntervalSeconds = refresh > 0 ? refresh : 60

        if defaults.object(forKey: Keys.showPercentInMenuBar) == nil {
            self.showPercentInMenuBar = true
        } else {
            self.showPercentInMenuBar = defaults.bool(forKey: Keys.showPercentInMenuBar)
        }

        if let raw = defaults.string(forKey: Keys.selectedProvider),
           let provider = UsageProviderType(rawValue: raw) {
            self.selectedProvider = provider
        } else {
            self.selectedProvider = .manual
        }

        self.manualPayload = Self.load(
            defaults: defaults,
            decoder: decoder,
            key: Keys.manualPayload,
            fallback: .empty
        )

        self.pastePayload = Self.load(
            defaults: defaults,
            decoder: decoder,
            key: Keys.pastePayload,
            fallback: .empty
        )
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private static func load<T: Decodable>(defaults: UserDefaults, decoder: JSONDecoder, key: String, fallback: T) -> T {
        guard let data = defaults.data(forKey: key),
              let decoded = try? decoder.decode(T.self, from: data) else {
            return fallback
        }
        return decoded
    }

    private enum Keys {
        static let thresholds = "thresholdSettings"
        static let refreshIntervalSeconds = "refreshIntervalSeconds"
        static let showPercentInMenuBar = "showPercentInMenuBar"
        static let selectedProvider = "selectedProvider"
        static let manualPayload = "manualPayload"
        static let pastePayload = "pastePayload"
    }
}
