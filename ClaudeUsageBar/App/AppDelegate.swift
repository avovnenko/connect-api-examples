import AppKit
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let manager = ProviderManager()
    private var cancellables: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        manager.start()
        updateStatusAppearance()

        manager.$snapshot
            .combineLatest(manager.$settings)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _ in
                self?.updateStatusAppearance()
            }
            .store(in: &cancellables)
    }

    func applicationWillTerminate(_ notification: Notification) {
        manager.stop()
    }
}

private extension AppDelegate {
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
            button.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .medium)
        }
    }

    func setupPopover() {
        popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 420, height: 650)
        popover.contentViewController = NSHostingController(rootView: PopoverContentView(manager: manager))
    }

    func updateStatusAppearance() {
        guard let button = statusItem.button else { return }
        let severity = StatusEvaluator.severity(for: manager.snapshot, settings: manager.settings)
        let title = StatusEvaluator.menuBarText(snapshot: manager.snapshot, settings: manager.settings)
        let attributed = NSAttributedString(string: title, attributes: [
            .foregroundColor: severity.color,
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .semibold)
        ])
        button.attributedTitle = attributed
    }

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
