import Foundation

enum ConnectivityState: String, Codable {
    case connected
    case manual
    case unavailable
}

struct UsageWindow: Codable, Equatable {
    var used: Double?
    var limit: Double?
    var remaining: Double?
    var resetAt: Date?
    var pctUsed: Double?

    static let empty = UsageWindow(used: nil, limit: nil, remaining: nil, resetAt: nil, pctUsed: nil)

    static func normalized(
        used: Double?,
        limit: Double?,
        remaining: Double?,
        resetAt: Date?
    ) -> UsageWindow {
        let computedRemaining = remaining ?? {
            guard let used, let limit else { return nil }
            return max(0, limit - used)
        }()

        let computedPct: Double? = {
            if let used, let limit, limit > 0 {
                return min(max(used / limit, 0), 1)
            }
            if let remaining = computedRemaining, let limit, limit > 0 {
                let used = max(0, limit - remaining)
                return min(max(used / limit, 0), 1)
            }
            return nil
        }()

        return UsageWindow(
            used: used,
            limit: limit,
            remaining: computedRemaining,
            resetAt: resetAt,
            pctUsed: computedPct
        )
    }
}

struct UsageSnapshot: Codable, Equatable {
    var timestamp: Date
    var fiveHour: UsageWindow
    var weekly: UsageWindow
    var connectivity: ConnectivityState

    static func unavailable(timestamp: Date = .now) -> UsageSnapshot {
        UsageSnapshot(
            timestamp: timestamp,
            fiveHour: .empty,
            weekly: .empty,
            connectivity: .unavailable
        )
    }
}

struct ThresholdSettings: Codable, Equatable {
    var yellowThreshold: Double
    var redThreshold: Double

    static let `default` = ThresholdSettings(yellowThreshold: 0.6, redThreshold: 0.85)
}

enum UsageIndicatorState: Equatable {
    case green
    case yellow
    case red
    case gray
}

func indicatorState(
    snapshot: UsageSnapshot?,
    thresholds: ThresholdSettings,
    prioritizeWeekly: Bool = false
) -> UsageIndicatorState {
    guard let snapshot else { return .gray }
    guard snapshot.connectivity != .unavailable else { return .gray }

    let targetPct = prioritizeWeekly ? (snapshot.weekly.pctUsed ?? snapshot.fiveHour.pctUsed) : (snapshot.fiveHour.pctUsed ?? snapshot.weekly.pctUsed)
    guard let pct = targetPct else { return .gray }

    if pct >= thresholds.redThreshold { return .red }
    if pct >= thresholds.yellowThreshold { return .yellow }
    return .green
}
