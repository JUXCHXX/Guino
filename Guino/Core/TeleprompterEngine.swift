import Combine
import Foundation
import SwiftUI

@MainActor
final class TeleprompterEngine: ObservableObject {
    @Published private(set) var currentLineIndex = 0
    @Published private(set) var isPaused = false
    @Published var isSafeMode = false
    @Published var scriptText: String {
        didSet { saveScript() }
    }
    @Published var wordsPerMinute: Double {
        didSet {
            UserDefaults.standard.set(wordsPerMinute, forKey: "wordsPerMinute")
            restartTimer()
        }
    }
    @Published var fontSize: Double {
        didSet { save(fontSize, forKey: "fontSize") }
    }
    @Published var fontWeightIndex: Int {
        didSet { save(fontWeightIndex, forKey: "fontWeightIndex") }
    }
    @Published var textColorRed: Double {
        didSet { save(textColorRed, forKey: "textColorRed") }
    }
    @Published var textColorGreen: Double {
        didSet { save(textColorGreen, forKey: "textColorGreen") }
    }
    @Published var textColorBlue: Double {
        didSet { save(textColorBlue, forKey: "textColorBlue") }
    }
    @Published var notchWidth: Double {
        didSet {
            save(notchWidth, forKey: "notchWidth")
            notifyLayoutChange()
        }
    }
    @Published var visibleLineCount: Int {
        didSet {
            save(visibleLineCount, forKey: "visibleLineCount")
            notifyLayoutChange()
        }
    }

    let voiceDetector = VoiceActivityDetector()

    private let defaults = UserDefaults.standard
    private var timer: Timer?

    var voiceSensitivity: Binding<Double> {
        Binding(
            get: { self.voiceDetector.sensitivity },
            set: { self.voiceDetector.sensitivity = $0 }
        )
    }

    private var lines: [String] {
        scriptText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var lineCount: Int { max(lines.count, 1) }
    var currentLine: String? { lines[safe: currentLineIndex] }
    var nextLine: String? { lines[safe: currentLineIndex + 1] }

    init() {
        scriptText = defaults.string(forKey: "scriptText") ?? "Hola, soy Guino.\nTe ayudaré a mirar a cámara\nsin perder el hilo de tu guion.\nEl texto avanza a tu velocidad."
        wordsPerMinute = defaults.double(forKey: "wordsPerMinute") == 0 ? 120 : defaults.double(forKey: "wordsPerMinute")
        fontSize = defaults.object(forKey: "fontSize") as? Double ?? 11
        fontWeightIndex = defaults.object(forKey: "fontWeightIndex") as? Int ?? 2
        textColorRed = defaults.object(forKey: "textColorRed") as? Double ?? 1
        textColorGreen = defaults.object(forKey: "textColorGreen") as? Double ?? 1
        textColorBlue = defaults.object(forKey: "textColorBlue") as? Double ?? 1
        notchWidth = defaults.object(forKey: "notchWidth") as? Double ?? 280
        visibleLineCount = defaults.object(forKey: "visibleLineCount") as? Int ?? 2
        startTimer()
    }

    var textColor: Color {
        Color(red: textColorRed, green: textColorGreen, blue: textColorBlue)
    }

    var fontWeight: Font.Weight {
        [.regular, .medium, .semibold, .bold][safe: fontWeightIndex] ?? .semibold
    }

    func togglePause() {
        isPaused.toggle()
    }

    func moveForward() {
        guard currentLineIndex < lines.count - 1 else { return }
        currentLineIndex += 1
    }

    func moveBackward() {
        guard currentLineIndex > 0 else { return }
        currentLineIndex -= 1
    }

    func updateScript() {
        currentLineIndex = 0
        restartTimer()
    }

    private func saveScript() {
        defaults.set(scriptText, forKey: "scriptText")
    }

    private func save(_ value: Any, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    private func notifyLayoutChange() {
        NotificationCenter.default.post(name: .guinoLayoutChanged, object: nil)
    }

    private func restartTimer() {
        timer?.invalidate()
        startTimer()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, !self.isPaused, !self.lines.isEmpty else { return }
                if self.voiceDetector.isListening {
                    guard self.voiceDetector.isSpeaking else { return }
                }

                self.moveForwardOrLoop()
            }
        }
    }

    private func moveForwardOrLoop() {
        if currentLineIndex < lines.count - 1 {
            currentLineIndex += 1
        } else {
            currentLineIndex = 0
        }
    }

    private var interval: TimeInterval {
        let wordCount = max(currentLine?.split(separator: " ").count ?? 1, 1)
        return max(60.0 / wordsPerMinute * Double(wordCount), 1.0)
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
