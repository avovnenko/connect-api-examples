import Foundation

struct AppSettings: Codable, Equatable {
    var yellowThreshold: Double
    var redThreshold: Double
    var refreshInterval: TimeInterval
    var showPercentInMenuBar: Bool
    var selectedProvider: ProviderKind

    static let `default` = AppSettings(
        yellowThreshold: 60,
        redThreshold: 85,
        refreshInterval: 60,
        showPercentInMenuBar: true,
        selectedProvider: .manualEntry
    )
}

struct PersistedInputState: Codable, Equatable {
    var manualFiveHour: UsageWindow
    var manualWeekly: UsageWindow
    var lastPastedStatusText: String
    var lastParseWarnings: [String]

    static let `default` = PersistedInputState(
        manualFiveHour: .empty,
        manualWeekly: .empty,
        lastPastedStatusText: "",
        lastParseWarnings: []
    )
}
