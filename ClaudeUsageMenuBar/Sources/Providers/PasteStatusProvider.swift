import Foundation

struct PasteStatusProvider: UsageProvider {
    let store: SettingsStore

    var name: String { "Paste from Claude Code" }
    var supportsAutoRefresh: Bool { false }

    func fetchSnapshot() async throws -> UsageSnapshot {
        let payload = await MainActor.run { store.pastePayload }
        return payload.parsedSnapshot ?? UsageSnapshot.unavailable()
    }

    static func parse(_ input: String, now: Date = .now) -> (UsageSnapshot?, [String]) {
        var warnings: [String] = []
        let lines = input.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }

        var fiveHour = UsageWindow.empty
        var weekly = UsageWindow.empty
        var sawAnyUsageLine = false

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }

            let lower = line.lowercased()
            if lower.contains("5h") || lower.contains("5-hour") || lower.contains("rolling") {
                sawAnyUsageLine = true
                fiveHour = parseWindow(line: line, existing: fiveHour, warnings: &warnings)
            } else if lower.contains("week") {
                sawAnyUsageLine = true
                weekly = parseWindow(line: line, existing: weekly, warnings: &warnings)
            } else {
                warnings.append("Ignored unknown line: \(line)")
            }
        }

        if !sawAnyUsageLine {
            warnings.append("No recognizable 5-hour or weekly usage lines found.")
        }

        let normalizedFive = UsageWindow.normalized(
            used: fiveHour.used,
            limit: fiveHour.limit,
            remaining: fiveHour.remaining,
            resetAt: fiveHour.resetAt
        )
        let normalizedWeekly = UsageWindow.normalized(
            used: weekly.used,
            limit: weekly.limit,
            remaining: weekly.remaining,
            resetAt: weekly.resetAt
        )

        let hasData = [normalizedFive.used, normalizedFive.limit, normalizedFive.remaining, normalizedFive.pctUsed,
                       normalizedWeekly.used, normalizedWeekly.limit, normalizedWeekly.remaining, normalizedWeekly.pctUsed]
            .contains { $0 != nil }

        let snapshot = hasData
            ? UsageSnapshot(timestamp: now, fiveHour: normalizedFive, weekly: normalizedWeekly, connectivity: .manual)
            : nil

        return (snapshot, warnings)
    }

    private static func parseWindow(line: String, existing: UsageWindow, warnings: inout [String]) -> UsageWindow {
        var window = existing

        if let ratio = parseRatio(from: line) {
            window.used = ratio.used
            window.limit = ratio.limit
        }

        if let percent = parsePercent(from: line) {
            window.pctUsed = percent
        }

        if let remaining = parseValue(after: "remaining", line: line) {
            window.remaining = remaining
        }

        if let used = parseValue(after: "used", line: line) {
            window.used = used
        }

        if let limit = parseValue(after: "limit", line: line) {
            window.limit = limit
        }

        if let reset = parseReset(line: line) {
            window.resetAt = reset
        }

        if window.used == nil && window.limit == nil && window.remaining == nil && window.pctUsed == nil {
            warnings.append("Could not parse usage values from line: \(line)")
        }

        if window.pctUsed == nil, let used = window.used, let limit = window.limit, limit > 0 {
            window.pctUsed = min(max(used / limit, 0), 1)
        }

        return window
    }

    private static func parseRatio(from line: String) -> (used: Double, limit: Double)? {
        let pattern = #"([0-9]+(?:\.[0-9]+)?)\s*/\s*([0-9]+(?:\.[0-9]+)?)"#
        guard let match = line.firstMatch(of: try! Regex(pattern)),
              let used = Double(match.1),
              let limit = Double(match.2) else {
            return nil
        }
        return (used, limit)
    }

    private static func parsePercent(from line: String) -> Double? {
        let pattern = #"([0-9]+(?:\.[0-9]+)?)\s*%"#
        guard let match = line.firstMatch(of: try! Regex(pattern)),
              let value = Double(match.1) else {
            return nil
        }
        return min(max(value / 100, 0), 1)
    }

    private static func parseValue(after key: String, line: String) -> Double? {
        let pattern = #"\#(key)\s*[:=]?\s*([0-9]+(?:\.[0-9]+)?)"#
        guard let regex = try? Regex(pattern),
              let match = line.lowercased().firstMatch(of: regex),
              let value = Double(match.1) else {
            return nil
        }
        return value
    }

    private static func parseReset(line: String) -> Date? {
        guard let range = line.range(of: "reset", options: [.caseInsensitive]) else { return nil }
        let suffix = line[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)

        let formats = [
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd"
        ]

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: suffix.replacingOccurrences(of: ":", with: "", options: [.literal], range: nil)) {
                return date
            }
            if let date = formatter.date(from: suffix) {
                return date
            }
        }

        let iso = ISO8601DateFormatter()
        return iso.date(from: suffix)
    }
}
