import AppKit
import Foundation

enum UsageSeverity: Equatable {
    case green
    case yellow
    case red
    case gray

    var color: NSColor {
        switch self {
        case .green: return .systemGreen
        case .yellow: return .systemYellow
        case .red: return .systemRed
        case .gray: return .systemGray
        }
    }
}

struct StatusEvaluator {
    static func severity(for snapshot: UsageSnapshot?, settings: AppSettings) -> UsageSeverity {
        guard
            let pct = snapshot?.fiveHour.pctUsed,
            snapshot?.connectivity != .unavailable
        else {
            return .gray
        }

        if pct >= settings.redThreshold {
            return .red
        }
        if pct >= settings.yellowThreshold {
            return .yellow
        }
        return .green
    }

    static func menuBarText(snapshot: UsageSnapshot?, settings: AppSettings) -> String {
        let icon = "●"
        guard settings.showPercentInMenuBar, let pct = snapshot?.fiveHour.pctUsed else {
            return icon
        }
        return "\(icon) \(Int(pct.rounded()))%"
    }
}
