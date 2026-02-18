# ClaudeUsageBar

Lightweight native macOS menu bar app that tracks Claude subscription usage with **safe, user-controlled providers**:

- **Manual Entry** (local values)
- **Paste from Claude Code `/status`** (defensive parser)
- **Deep Link** (opens Claude usage settings page)

No scraping and no undocumented API calls are used.

## Features

- Top-right menu bar indicator with status severity color (green/yellow/red/gray)
- Popover with:
  - Rolling 5-hour window
  - Weekly window
  - Provider-specific input UI
  - Configurable thresholds and refresh interval
- Exponential backoff for refresh failures
- Snapshot caching and meaningful-change updates to avoid churn
- Local persistence through `UserDefaults`

## Project structure

- `ClaudeUsageBar.xcodeproj` — Xcode project
- `ClaudeUsageBar/` — App source
  - `Models/` — normalized data models + settings
  - `Providers/` — provider implementations
  - `Managers/` — persistence and provider orchestration
  - `Utilities/` — parser, backoff, severity logic
  - `Views/` — popover UI
  - `App/` — app entry + `NSStatusItem` integration
- `ClaudeUsageBarTests/` — unit tests for logic/parsing

## Build & run

1. Open `ClaudeUsageBar.xcodeproj` in Xcode 15+.
2. Select the `ClaudeUsageBar` target.
3. Build and run.
4. The app runs as a menu bar utility (`LSUIElement = YES`), so no dock icon appears.

## Using providers

### Manual Entry

Enter usage values for 5-hour + weekly windows and save.

### Paste from Claude Code `/status`

1. Open Claude Code.
2. Run `/status`.
3. Copy the displayed status output.
4. Paste into the app and click **Parse & Save**.

The parser is defensive and ignores unknown lines while reporting warnings.

### Deep Link

Use **Open Claude Usage Page** to launch Claude settings usage page in your default browser.

## Notes on storage and privacy

- Settings and manual/pasted values are stored locally in `UserDefaults`.
- Session cookies are **not** stored.
- If sensitive credentials are ever needed in a future provider, Keychain should be used.

## Tests

Unit tests cover:

1. Threshold → severity mapping
2. Backoff schedule progression and reset
3. Paste parser behavior with known and unknown lines
