import SwiftUI

@main
struct GuinoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Guino", systemImage: "rectangle.topthird.inset.filled") {
            Button("Pausar / reanudar") {
                NotificationCenter.default.post(name: .guinoTogglePause, object: nil)
            }
            Button("Desplegar / cerrar") {
                NotificationCenter.default.post(name: .guinoTogglePanel, object: nil)
            }
            Button("Modo seguro") {
                NotificationCenter.default.post(name: .guinoToggleSafeMode, object: nil)
            }
            Button("Abrir ajustes de privacidad") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                    NSWorkspace.shared.open(url)
                }
            }
            Divider()
            Text("Guino 1.0")
            Divider()
            Button("Salir") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
