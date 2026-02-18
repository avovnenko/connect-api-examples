import AppKit
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?
    private var cancellables: Set<AnyCancellable> = []

    let appState = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 420, height: 680)
        popover.contentViewController = NSHostingController(
            rootView: UsagePopoverView().environmentObject(appState)
        )

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)

        appState.$menuBarText
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.statusItem.button?.title = value
            }
            .store(in: &cancellables)

        statusItem.button?.title = appState.menuBarText
        appState.start()
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
            stopEventMonitor()
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            startEventMonitor()
        }
    }

    private func startEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self else { return }
            if self.popover.isShown {
                self.popover.performClose(nil)
                self.stopEventMonitor()
            }
        }
    }

    private func stopEventMonitor() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }
}
