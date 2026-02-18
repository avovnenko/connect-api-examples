# Claude Usage Menu Bar (macOS)

A lightweight native macOS menu bar app (SwiftUI + `NSStatusItem`) that tracks Claude subscription usage using **safe local providers** only:

1. **Deep Link provider**: opens Claude usage page in your browser.
2. **Manual Entry provider**: local values for 5-hour and weekly usage windows.
3. **Paste-from-Claude-Code provider**: paste `/status` output and parse defensively.

> This app does **not** scrape claude.ai and does **not** use undocumented endpoints.

## Project Layout

- `ClaudeUsageMenuBar/ClaudeUsageMenuBar.xcodeproj` — Xcode project.
- `ClaudeUsageMenuBar/App` — app entry, app delegate, app state.
- `ClaudeUsageMenuBar/Sources/Core` — models, provider protocol, manager, persistence.
- `ClaudeUsageMenuBar/Sources/Providers` — manual/paste/deep-link providers.
- `ClaudeUsageMenuBar/Sources/UI` — SwiftUI popover.
- `ClaudeUsageMenuBar/Tests/ClaudeUsageMenuBarTests` — unit tests.

## Build & Run

1. Open `ClaudeUsageMenuBar/ClaudeUsageMenuBar.xcodeproj` in Xcode 16+.
2. Select the `ClaudeUsageMenuBar` scheme.
3. Run on macOS.
4. The app appears in the top-right menu bar.

## Usage

### Provider selection
Use the provider picker in the popover header:
- **Manual Entry**: edit values and click **Save**.
- **Paste from Claude Code**: paste text, click **Parse & Save**.
- **Deep Link**: click **Open Claude Usage Page**.

### Getting `/status` text from Claude Code
In Claude Code, run `/status`, then copy the output and paste it into this app’s Paste provider input box. The parser is defensive and ignores unknown lines while reporting warnings.

## Behaviors

- Menu bar indicator supports color states: green/yellow/red/gray.
- Popover shows:
  - rolling 5-hour window
  - weekly window
  - thresholds
  - refresh interval
  - show-percent toggle
- Provider manager:
  - polls only providers that support auto refresh
  - default refresh interval: 60s (configurable)
  - exponential backoff on failures: 1m → 2m → 5m → 10m
  - caches last good snapshot and updates UI only on meaningful changes

## Storage & Security

- Settings and local usage values are persisted in `UserDefaults`.
- Sensitive material should use Keychain design for future enhancements.
- Session cookies are not collected or stored.

## Tests

Included unit tests:
1. threshold → indicator state mapping
2. backoff schedule behavior
3. paste parser known/unknown line behavior
