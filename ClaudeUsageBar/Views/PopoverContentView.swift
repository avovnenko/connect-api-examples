import SwiftUI

struct PopoverContentView: View {
    @ObservedObject var manager: ProviderManager

    @State private var manualFiveHourUsed: String = ""
    @State private var manualFiveHourLimit: String = ""
    @State private var manualFiveHourReset: Date = Date()

    @State private var manualWeeklyUsed: String = ""
    @State private var manualWeeklyLimit: String = ""
    @State private var manualWeeklyReset: Date = Date()

    @State private var pastedText: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                windowSection(title: "Last 5 hours", window: manager.snapshot?.fiveHour)
                windowSection(title: "This week", window: manager.snapshot?.weekly)
                settingsSection
                providerInputSection
            }
            .padding()
        }
        .frame(width: 420, height: 650)
        .onAppear(perform: seedLocalState)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Provider", selection: Binding(
                get: { manager.settings.selectedProvider },
                set: { manager.selectProvider($0) }
            )) {
                ForEach(ProviderKind.allCases) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .pickerStyle(.menu)

            Text("Last updated: \(formatted(date: manager.lastUpdated))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Next update: \(countdownText())")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Update now") {
                Task { await manager.refreshNow(force: true) }
            }
        }
    }

    private func windowSection(title: String, window: UsageWindow?) -> some View {
        let normalized = window?.normalized() ?? .empty
        return VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            HStack {
                statCell("Used", value: normalized.used)
                statCell("Limit", value: normalized.limit)
                statCell("Remaining", value: normalized.remaining)
            }
            Text("Reset: \(formatted(date: normalized.resetAt))")
                .font(.caption)
                .foregroundStyle(.secondary)
            ProgressView(value: (normalized.pctUsed ?? 0) / 100)
            Text("\(Int((normalized.pctUsed ?? 0).rounded()))% used")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
        .cornerRadius(8)
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings").font(.headline)
            HStack {
                Text("Yellow")
                Slider(value: Binding(
                    get: { manager.settings.yellowThreshold },
                    set: { manager.settings.yellowThreshold = $0 }
                ), in: 0...100)
                Text("\(Int(manager.settings.yellowThreshold))%")
                    .monospacedDigit()
                    .frame(width: 52)
            }
            HStack {
                Text("Red")
                Slider(value: Binding(
                    get: { manager.settings.redThreshold },
                    set: { manager.settings.redThreshold = $0 }
                ), in: 0...100)
                Text("\(Int(manager.settings.redThreshold))%")
                    .monospacedDigit()
                    .frame(width: 52)
            }
            Stepper(
                "Refresh interval: \(Int(manager.settings.refreshInterval))s",
                value: Binding(
                    get: { Int(manager.settings.refreshInterval) },
                    set: { manager.settings.refreshInterval = TimeInterval(max($0, 30)) }
                ),
                in: 30...600,
                step: 10
            )
            Toggle("Show percent in menu bar", isOn: Binding(
                get: { manager.settings.showPercentInMenuBar },
                set: { manager.settings.showPercentInMenuBar = $0 }
            ))
        }
    }

    @ViewBuilder
    private var providerInputSection: some View {
        switch manager.settings.selectedProvider {
        case .manualEntry:
            manualInputSection
        case .pasteStatus:
            pasteInputSection
        case .deepLink:
            deepLinkSection
        }
    }

    private var manualInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Input · Manual Entry").font(.headline)
            Text("5-hour window")
            HStack {
                TextField("Used", text: $manualFiveHourUsed)
                TextField("Limit", text: $manualFiveHourLimit)
                DatePicker("Reset", selection: $manualFiveHourReset)
            }
            Text("Weekly window")
            HStack {
                TextField("Used", text: $manualWeeklyUsed)
                TextField("Limit", text: $manualWeeklyLimit)
                DatePicker("Reset", selection: $manualWeeklyReset)
            }
            Button("Save") {
                Task {
                    await manager.saveManualValues(
                        fiveHour: UsageWindow(
                            used: Double(manualFiveHourUsed),
                            limit: Double(manualFiveHourLimit),
                            remaining: nil,
                            resetAt: manualFiveHourReset,
                            pctUsed: nil
                        ),
                        weekly: UsageWindow(
                            used: Double(manualWeeklyUsed),
                            limit: Double(manualWeeklyLimit),
                            remaining: nil,
                            resetAt: manualWeeklyReset,
                            pctUsed: nil
                        )
                    )
                }
            }
        }
    }

    private var pasteInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Input · Paste /status").font(.headline)
            TextEditor(text: $pastedText)
                .font(.system(.body, design: .monospaced))
                .frame(height: 160)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))
            Button("Parse & Save") {
                Task { await manager.parseAndSaveStatus(pastedText) }
            }
            if !manager.parseWarnings.isEmpty {
                Text("Warnings")
                    .font(.subheadline)
                    .bold()
                ForEach(manager.parseWarnings, id: \.self) { warning in
                    Text("• \(warning)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var deepLinkSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Input · Deep Link").font(.headline)
            Text("This provider intentionally avoids API calls and scraping.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Open Claude Usage Page") {
                manager.openUsagePage()
            }
        }
    }

    private func statCell(_ label: String, value: Double?) -> some View {
        VStack(alignment: .leading) {
            Text(label).font(.caption)
            Text(value.map { String(format: "%.1f", $0) } ?? "—")
                .font(.body.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatted(date: Date?) -> String {
        guard let date else { return "—" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    private func countdownText() -> String {
        guard let next = manager.nextRefreshAt else { return "—" }
        let seconds = Int(max(next.timeIntervalSinceNow, 0))
        return "\(seconds)s"
    }

    private func seedLocalState() {
        let state = manager.inputState
        manualFiveHourUsed = state.manualFiveHour.used.map { String($0) } ?? ""
        manualFiveHourLimit = state.manualFiveHour.limit.map { String($0) } ?? ""
        manualFiveHourReset = state.manualFiveHour.resetAt ?? Date()

        manualWeeklyUsed = state.manualWeekly.used.map { String($0) } ?? ""
        manualWeeklyLimit = state.manualWeekly.limit.map { String($0) } ?? ""
        manualWeeklyReset = state.manualWeekly.resetAt ?? Date()

        pastedText = state.lastPastedStatusText
    }
}
