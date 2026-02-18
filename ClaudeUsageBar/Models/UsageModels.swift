import Foundation

struct UsageWindow: Codable, Equatable {
    var used: Double?
    var limit: Double?
    var remaining: Double?
    var resetAt: Date?
    var pctUsed: Double?

    static let empty = UsageWindow()

    init(
        used: Double? = nil,
        limit: Double? = nil,
        remaining: Double? = nil,
        resetAt: Date? = nil,
        pctUsed: Double? = nil
    ) {
        self.used = used
        self.limit = limit
        self.remaining = remaining
        self.resetAt = resetAt
        self.pctUsed = pctUsed
    }

    func normalized() -> UsageWindow {
        var copy = self
        if copy.pctUsed == nil, let used, let limit, limit > 0 {
            copy.pctUsed = min(max((used / limit) * 100.0, 0), 100)
        }
        if copy.remaining == nil, let used, let limit {
            copy.remaining = max(limit - used, 0)
        }
        return copy
    }
}

enum ConnectivityState: String, Codable {
    case connected
    case manual
    case unavailable
}

struct UsageSnapshot: Codable, Equatable {
    var timestamp: Date
    var fiveHour: UsageWindow
    var weekly: UsageWindow
    var connectivity: ConnectivityState

    static let unavailable = UsageSnapshot(
        timestamp: Date(),
        fiveHour: .empty,
        weekly: .empty,
        connectivity: .unavailable
    )

    func normalized() -> UsageSnapshot {
        UsageSnapshot(
            timestamp: timestamp,
            fiveHour: fiveHour.normalized(),
            weekly: weekly.normalized(),
            connectivity: connectivity
        )
    }

    func isMeaningfullyDifferent(from other: UsageSnapshot) -> Bool {
        fiveHour != other.fiveHour || weekly != other.weekly || connectivity != other.connectivity
    }
}

enum ProviderKind: String, CaseIterable, Codable, Identifiable {
    case manualEntry
    case pasteStatus
    case deepLink

    var id: String { rawValue }

    var title: String {
        switch self {
        case .manualEntry: return "Manual Entry"
        case .pasteStatus: return "Paste from /status"
        case .deepLink: return "Deep Link"
        }
    }
}
