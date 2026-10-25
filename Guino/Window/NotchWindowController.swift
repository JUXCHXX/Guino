import AppKit
import SwiftUI

@MainActor
final class NotchWindowController {
    private let panel: NotchPanel
    private let teleprompter = TeleprompterEngine()

    init() {
        let size = NSSize(width: 280, height: 44)
        let hostingView = NSHostingView(rootView: NotchView(engine: teleprompter))
        hostingView.frame = NSRect(origin: .zero, size: size)

        panel = NotchPanel(contentView: hostingView)
        panel.setContentSize(size)

        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        panel.place(width: size.width, height: size.height, on: screen)
        panel.orderFrontRegardless()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(panelVisibilityDidChange(_:)),
            name: .guinoPanelVisibilityChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(layoutDidChange),
            name: .guinoLayoutChanged,
            object: nil
        )
    }

    @objc private func layoutDidChange() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let width = teleprompter.notchWidth
        panel.setContentSize(NSSize(width: width, height: panel.frame.height))
        if let hostingView = panel.contentView {
            hostingView.frame = NSRect(x: 0, y: 0, width: width, height: panel.frame.height)
        }
        panel.place(width: width, height: panel.frame.height, on: screen)
    }

    @objc private func panelVisibilityDidChange(_ notification: Notification) {
        guard let expanded = notification.userInfo?["expanded"] as? Bool else { return }
        let height: CGFloat = expanded ? 394 : 44
        let width: CGFloat = teleprompter.notchWidth
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        panel.setContentSize(NSSize(width: width, height: height))
        if let hostingView = panel.contentView as? NSHostingView<NotchView> {
            hostingView.frame = NSRect(x: 0, y: 0, width: width, height: height)
        }
        panel.place(width: width, height: height, on: screen)
    }

    @objc private func screenConfigurationDidChange() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        panel.place(width: panel.frame.width, height: panel.frame.height, on: screen)
    }
}
