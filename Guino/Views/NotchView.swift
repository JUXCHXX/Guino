import SwiftUI

struct NotchView: View {
    @ObservedObject var engine: TeleprompterEngine
    @State private var isExpanded = false
    @State private var isSafeMode = false

    var body: some View {
        VStack(spacing: 0) {
            NotchShape()
                .fill(Color(red: 0.008, green: 0.008, blue: 0.008))
                .overlay(alignment: .leading) {
                    HStack(spacing: 8) {

                        Button(action: engine.togglePause) {
                            Image(systemName: engine.isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white.opacity(0.9))
                                .frame(width: 16, height: 16)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 0) {
                            Text(engine.currentLine ?? "")
                                .font(.system(size: engine.fontSize, weight: engine.fontWeight))
                                .foregroundStyle(engine.textColor)
                                .lineLimit(2)
                                .minimumScaleFactor(0.75)
                                .allowsTightening(true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: engine.visibleLineCount > 1 ? 20 : 30, alignment: .leading)
                                .id(engine.currentLineIndex)
                                .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .move(edge: .top).combined(with: .opacity)))
                            if engine.visibleLineCount > 1 {
                                Text(engine.nextLine ?? "")
                                    .font(.system(size: max(engine.fontSize - 2, 9), weight: engine.fontWeight))
                                    .foregroundStyle(engine.textColor.opacity(0.38))
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.75)
                                    .allowsTightening(true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(height: 14, alignment: .leading)
                                    .transition(.opacity)
                            }
                        }
                        .animation(.easeInOut(duration: 0.35), value: engine.currentLineIndex)
                        .frame(maxWidth: .infinity, minHeight: 34, maxHeight: 34, alignment: .leading)
                    }
                    .padding(.horizontal, 12)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2, perform: togglePanel)
                    .gesture(
                        DragGesture(minimumDistance: 12)
                            .onEnded { value in
                                if value.translation.height < -12 {
                                    engine.moveForward()
                                } else if value.translation.height > 12 {
                                    engine.moveBackward()
                                }
                            }
                    )
                    .opacity(engine.isSafeMode ? 0 : 1)
                }
                .frame(width: engine.notchWidth, height: 44)

            if isExpanded {
                ControlPanelView(engine: engine)
                    .frame(width: engine.notchWidth, height: 350)
                    .background(Color(red: 0.008, green: 0.008, blue: 0.008))
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.24), value: isExpanded)
        .onTapGesture(count: 2, perform: togglePanel)
        .onReceive(NotificationCenter.default.publisher(for: .guinoTogglePause)) { _ in
            engine.togglePause()
        }
        .onReceive(NotificationCenter.default.publisher(for: .guinoTogglePanel)) { _ in
            togglePanel()
        }
        .onReceive(NotificationCenter.default.publisher(for: .guinoToggleSafeMode)) { _ in
            isSafeMode.toggle()
            NotificationCenter.default.post(name: .guinoSafeModeChanged, object: nil, userInfo: ["safeMode": isSafeMode])
        }
        .onChange(of: isSafeMode) { _, safeMode in
            engine.isSafeMode = safeMode
        }
    }

    private func togglePanel() {
        isExpanded.toggle()
        NotificationCenter.default.post(
            name: .guinoPanelVisibilityChanged,
            object: nil,
            userInfo: ["expanded": isExpanded]
        )
    }
}

extension Notification.Name {
    static let guinoPanelVisibilityChanged = Notification.Name("guinoPanelVisibilityChanged")
    static let guinoLayoutChanged = Notification.Name("guinoLayoutChanged")
    static let guinoSafeModeChanged = Notification.Name("guinoSafeModeChanged")
}
