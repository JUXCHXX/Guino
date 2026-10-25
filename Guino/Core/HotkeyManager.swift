import AppKit

final class HotkeyManager {
    private var monitor: Any?

    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            guard event.modifierFlags.contains(.option) else { return }

            switch event.keyCode {
            case 49:
                NotificationCenter.default.post(name: .guinoTogglePause, object: nil)
            case 4:
                NotificationCenter.default.post(name: .guinoToggleSafeMode, object: nil)
            case 2:
                NotificationCenter.default.post(name: .guinoTogglePanel, object: nil)
            default:
                break
            }
        }
    }
}

extension Notification.Name {
    static let guinoTogglePause = Notification.Name("guinoTogglePause")
    static let guinoToggleSafeMode = Notification.Name("guinoToggleSafeMode")
    static let guinoTogglePanel = Notification.Name("guinoTogglePanel")
}
