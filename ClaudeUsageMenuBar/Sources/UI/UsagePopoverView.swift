import SwiftUI

struct UsagePopoverView: View {
    @EnvironmentObject var appState: AppState

    @State private var manualFiveHourUsed: String = ""
    @State private var manualFiveHourLimit: String = ""
    @State private var manualWeeklyUsed: String = ""
    @State private var manualWeeklyLimit: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                windowSection(title: "Last 5 hours", window: appState.manager.snapshot?.fiveHour)
                windowSection(title: "This week", window: appState.manager.snapshot?.weekly)
                settingsSection
                providerInputSection
            }
            .padding(14)
        }
        .frame(width: 420, height: 680)
        .onAppear { loadManualInputs() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Provider", selection: $appState.store.selectedProvider) {
                ForEach(UsageProviderType.allCases) { provider in
                    Text(provider.displayName).tag(provider)
                }
            }
            .onChange(of: appState.store.selectedProvider) { _ in
                appState.manager.forceRefresh()
            }

            Text("Last Updated: \(formatDate(appState.manager.lastUpdated))")
            Text("Next Update In: \(appState.countdownText)")

            if let error = appState.manager.lastErrorDescription {
                Text("Error: \(error)")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
    }

    private func windowSection(title: String, window: UsageWindow?) -> some View {
        GroupBox(title) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Used: \(formatNumber(window?.used))")
                Text("Limit: \(formatNumber(window?.limit))")
                Text("Remaining: \(formatNumber(window?.remaining))")
                Text("Reset: \(formatDate(window?.resetAt))")

                ProgressView(value: window?.pctUsed ?? 0)
                Text("Usage: \(formatPercent(window?.pctUsed))")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var settingsSection: some View {
        GroupBox("Settings") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Yellow threshold")
                    Slider(value: $appState.store.thresholds.yellowThreshold, in: 0.1...0.95)
                    Text(formatPercent(appState.store.thresholds.yellowThreshold))
                }

                HStack {
                    Text("Red threshold")
                    Slider(value: $appState.store.thresholds.redThreshold, in: 0.2...1)
                    Text(formatPercent(appState.store.thresholds.redThreshold))
                }

                HStack {
                    Text("Refresh interval (seconds)")
                    TextField("60", value: $appState.store.refreshIntervalSeconds, format: .number)
                        .frame(width: 80)
                }

                Toggle("Show percent in menu bar", isOn: $appState.store.showPercentInMenuBar)
            }
        }
    }

    @ViewBuilder
    private var providerInputSection: some View {
        GroupBox("Input") {
            switch appState.store.selectedProvider {
            case .manual:
                manualInputView
            case .pasteStatus:
                pasteInputView
            case .deepLink:
                deepLinkView
            }
        }
    }

    private var manualInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("5-hour used / limit")
            HStack {
                TextField("used", text: $manualFiveHourUsed)
                TextField("limit", text: $manualFiveHourLimit)
            }

            Text("Weekly used / limit")
            HStack {
                TextField("used", text: $manualWeeklyUsed)
                TextField("limit", text: $manualWeeklyLimit)
            }

            HStack {
                Button("Save") {
                    let payload = ManualUsagePayload(
                        fiveHour: UsageWindow.normalized(
                            used: Double(manualFiveHourUsed),
                            limit: Double(manualFiveHourLimit),
                            remaining: nil,
                            resetAt: appState.store.manualPayload.fiveHour.resetAt
                        ),
                        weekly: UsageWindow.normalized(
                            used: Double(manualWeeklyUsed),
                            limit: Double(manualWeeklyLimit),
                            remaining: nil,
                            resetAt: appState.store.manualPayload.weekly.resetAt
                        )
                    )
                    appState.saveManualPayload(payload)
                }

                Button("Update now") {
                    appState.manager.forceRefresh()
                }
            }
        }
    }

    private var pasteInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: $appState.store.pastePayload.rawText)
                .font(.system(size: 12, design: .monospaced))
                .frame(minHeight: 140)

            HStack {
                Button("Parse & Save") {
                    appState.parseAndSavePasteInput()
                }
                Button("Update now") {
                    appState.manager.forceRefresh()
                }
            }

            if !appState.store.pastePayload.warnings.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Parse warnings")
                        .font(.caption).bold()
                    ForEach(appState.store.pastePayload.warnings, id: \.self) { warning in
                        Text("• \(warning)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
    }

    private var deepLinkView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No official subscription usage API is available for direct fetch. Open Claude Usage in your browser.")
                .font(.caption)
            Button("Open Claude Usage Page") {
                appState.deepLinkProvider.openUsagePage()
            }
        }
    }

    private func loadManualInputs() {
        manualFiveHourUsed = appState.store.manualPayload.fiveHour.used.map(String.init) ?? ""
        manualFiveHourLimit = appState.store.manualPayload.fiveHour.limit.map(String.init) ?? ""
        manualWeeklyUsed = appState.store.manualPayload.weekly.used.map(String.init) ?? ""
        manualWeeklyLimit = appState.store.manualPayload.weekly.limit.map(String.init) ?? ""
    }

    private func formatNumber(_ value: Double?) -> String {
        guard let value else { return "-" }
        return String(format: "%.2f", value)
    }

    private func formatPercent(_ value: Double?) -> String {
        guard let value else { return "-" }
        return "\(Int(value * 100))%"
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date else { return "-" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}
