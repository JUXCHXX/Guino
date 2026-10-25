import AVFoundation
import Combine
import Foundation

@MainActor
final class VoiceActivityDetector: ObservableObject {
    @Published private(set) var isSpeaking = false
    @Published private(set) var isListening = false
    @Published var sensitivity: Double {
        didSet { UserDefaults.standard.set(sensitivity, forKey: "voiceSensitivity") }
    }

    private var recorder: AVAudioRecorder?
    private var meterTimer: Timer?
    private var silentSince: Date?

    init() {
        sensitivity = UserDefaults.standard.object(forKey: "voiceSensitivity") as? Double ?? 0.50
    }

    func start() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            guard granted else { return }
            Task { @MainActor in
                self?.beginCapture()
            }
        }
    }

    func stop() {
        meterTimer?.invalidate()
        meterTimer = nil
        recorder?.stop()
        recorder = nil
        isSpeaking = false
        isListening = false
    }

    private func beginCapture() {
        guard recorder == nil else { return }

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1
        ]
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("guino-meter.caf")

        do {
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.isMeteringEnabled = true
            guard recorder.record() else { return }
            self.recorder = recorder
            isListening = true
            meterTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.sampleMeter()
                }
            }
        } catch {
            stop()
        }
    }

    private func sampleMeter() {
        guard let recorder else { return }
        recorder.updateMeters()
        let average = recorder.averagePower(forChannel: 0)

        let threshold = Float(-55 + sensitivity * 30)
        let now = Date()

        if average >= threshold {
            silentSince = nil
            isSpeaking = true
        } else if isSpeaking {
            if let silentSince {
                if now.timeIntervalSince(silentSince) >= 0.5 {
                    isSpeaking = false
                }
            } else {
                silentSince = now
            }
        }
    }
}
