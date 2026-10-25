import SwiftUI

struct ControlPanelView: View {
    @ObservedObject var engine: TeleprompterEngine

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                Text("Guion")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(Int(engine.wordsPerMinute)) ppm")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
            }

            TextEditor(text: $engine.scriptText)
                .font(.system(size: 11))
                .scrollContentBackground(.hidden)
                .foregroundStyle(.white)
                .padding(8)
                .frame(height: 145)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .onChange(of: engine.scriptText) {
                    engine.updateScript()
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("Velocidad")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                Slider(value: $engine.wordsPerMinute, in: 60...220, step: 10)
                    .controlSize(.mini)
                    .tint(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Texto")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                HStack {
                    Slider(value: $engine.fontSize, in: 9...18, step: 1)
                    Picker("Grosor", selection: $engine.fontWeightIndex) {
                        Text("Regular").tag(0)
                        Text("Medium").tag(1)
                        Text("Semibold").tag(2)
                        Text("Bold").tag(3)
                    }
                    .labelsHidden()
                    .controlSize(.mini)
                    .frame(width: 82)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Color RGB")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                HStack {
                    colorSlider(value: $engine.textColorRed, color: .red)
                    colorSlider(value: $engine.textColorGreen, color: .green)
                    colorSlider(value: $engine.textColorBlue, color: .blue)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Ancho y líneas")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                HStack {
                    Slider(value: $engine.notchWidth, in: 240...420, step: 10)
                    Picker("Líneas", selection: $engine.visibleLineCount) {
                        Text("1 línea").tag(1)
                        Text("2 líneas").tag(2)
                    }
                    .labelsHidden()
                    .controlSize(.mini)
                    .frame(width: 78)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Micrófono")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                HStack {
                    Circle()
                        .fill(engine.voiceDetector.isSpeaking ? .green : .white.opacity(0.2))
                        .frame(width: 8, height: 8)
                    Text(engine.voiceDetector.isSpeaking ? "Te escucho" : "En silencio")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                }
                Slider(value: engine.voiceSensitivity, in: 0...1)
                    .controlSize(.mini)
                    .tint(.white)
                Button(engine.voiceDetector.isListening ? "Detener micro" : "Activar micro") {
                    if engine.voiceDetector.isListening {
                        engine.voiceDetector.stop()
                    } else {
                        engine.voiceDetector.start()
                    }
                }
                .controlSize(.small)
            }

            HStack(spacing: 8) {
                Button("Anterior") {
                    engine.moveBackward()
                }
                .controlSize(.small)
                Button("Siguiente") {
                    engine.moveForward()
                }
                .controlSize(.small)
                Text("\(engine.currentLineIndex + 1)/\(engine.lineCount)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
            }

            Text("Vista previa: \(engine.currentLine ?? "Guion vacío")")
                .font(.system(size: engine.fontSize, weight: engine.fontWeight))
                .foregroundStyle(engine.textColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }
        }
        .padding(12)
    }

    private func colorSlider(value: Binding<Double>, color: Color) -> some View {
        Slider(value: value, in: 0...1)
            .tint(color)
            .controlSize(.mini)
    }
}
