import Foundation

struct StatusTextParser {
    struct ParseResult {
        var snapshot: UsageSnapshot
        var warnings: [String]
    }

    static func parse(text: String, now: Date = Date()) -> ParseResult {
        var fiveHour = UsageWindow.empty
        var weekly = UsageWindow.empty
        var warnings: [String] = []

        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for line in lines {
            let lower = line.lowercased()
            let target: WindowTarget?
            if lower.contains("5h") || lower.contains("5-hour") || lower.contains("5 hour") {
                target = .fiveHour
            } else if lower.contains("week") {
                target = .weekly
            } else {
                warnings.append("Unrecognized line skipped: \(line)")
                continue
            }

            var updated = false
            if let (used, limit) = parseUsedLimit(from: line) {
                apply(target: target!, fiveHour: &fiveHour, weekly: &weekly) {
                    $0.used = used
                    $0.limit = limit
                }
                updated = true
            }
            if let remaining = parseNamedNumber(keyword: "remaining", line: line) {
                apply(target: target!, fiveHour: &fiveHour, weekly: &weekly) { $0.remaining = remaining }
                updated = true
            }
            if let pct = parsePercent(in: line) {
                apply(target: target!, fiveHour: &fiveHour, weekly: &weekly) { $0.pctUsed = pct }
                updated = true
            }
            if lower.contains("reset"), let reset = parseDateAfterReset(in: line) {
                apply(target: target!, fiveHour: &fiveHour, weekly: &weekly) { $0.resetAt = reset }
                updated = true
            }

            if !updated {
                warnings.append("No known usage values found in line: \(line)")
            }
        }

        let hasAnyData = [fiveHour, weekly].contains {
            $0.used != nil || $0.limit != nil || $0.remaining != nil || $0.resetAt != nil || $0.pctUsed != nil
        }

        return ParseResult(
            snapshot: UsageSnapshot(
                timestamp: now,
                fiveHour: fiveHour.normalized(),
                weekly: weekly.normalized(),
                connectivity: hasAnyData ? .connected : .unavailable
            ),
            warnings: warnings
        )
    }

    private enum WindowTarget { case fiveHour, weekly }

    private static func apply(target: WindowTarget, fiveHour: inout UsageWindow, weekly: inout UsageWindow, update: (inout UsageWindow) -> Void) {
        switch target {
        case .fiveHour: update(&fiveHour)
        case .weekly: update(&weekly)
        }
    }

    private static func parseUsedLimit(from line: String) -> (Double, Double)? {
        captureFirst(pattern: #"([0-9]+(?:\.[0-9]+)?)\s*/\s*([0-9]+(?:\.[0-9]+)?)"#, in: line).flatMap {
            guard $0.count == 2, let used = Double($0[0]), let limit = Double($0[1]) else { return nil }
            return (used, limit)
        }
    }

    private static func parseNamedNumber(keyword: String, line: String) -> Double? {
        let pattern = "\\(keyword)[^0-9-]*([0-9]+(?:\\.[0-9]+)?)"
        return captureFirst(pattern: pattern, in: line, options: [.caseInsensitive]).flatMap {
            guard let raw = $0.first else { return nil }
            return Double(raw)
        }
    }

    private static func parsePercent(in line: String) -> Double? {
        captureFirst(pattern: #"([0-9]+(?:\.[0-9]+)?)\s*%"#, in: line).flatMap {
            guard let raw = $0.first else { return nil }
            return Double(raw)
        }
    }

    private static func parseDateAfterReset(in line: String) -> Date? {
        let lower = line.lowercased()
        guard let range = lower.range(of: "reset") else { return nil }
        let raw = line[range.upperBound...].trimmingCharacters(in: CharacterSet(charactersIn: " :-"))

        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: raw) {
            return date
        }

        let formatters: [DateFormatter] = {
            let a = DateFormatter()
            a.locale = Locale(identifier: "en_US_POSIX")
            a.dateFormat = "yyyy-MM-dd HH:mm"

            let b = DateFormatter()
            b.locale = Locale(identifier: "en_US_POSIX")
            b.dateFormat = "MMM d, yyyy h:mm a"
            return [a, b]
        }()

        for formatter in formatters {
            if let date = formatter.date(from: raw) {
                return date
            }
        }
        return nil
    }

    private static func captureFirst(pattern: String, in line: String, options: NSRegularExpression.Options = []) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = regex.firstMatch(in: line, range: range) else { return nil }
        return (1..<match.numberOfRanges).compactMap { idx in
            guard let captureRange = Range(match.range(at: idx), in: line) else { return nil }
            return String(line[captureRange])
        }
    }
}
