# Guino

> Teleprompter en forma de notch de MacBook, pegado debajo de la cámara, que avanza solo mientras hablas y se puede ocultar al compartir pantalla.

---

## 1. Resumen de la idea

**Guino** es una app para macOS que dibuja un **notch falso** en el centro del borde superior de la pantalla, justo debajo de la cámara. Ese notch muestra tu guion en 1 o 2 líneas, para que al leer parezca que miras directamente a la cámara.

- El **notch normal (sin desplegar)** es el modo de uso: muestra el guion corriendo, con un botón de pausa/play al lado del texto.
- El **notch desplegado** es el panel de control: ahí se configura la app y se edita el guion.
- El texto **baja solo mientras detecta que estás hablando** y se detiene cuando te quedas en silencio.
- Se puede **ocultar con un atajo de teclado** para reducir el riesgo de que se vea al compartir pantalla o grabar.

### Por qué tiene sentido en tu equipo

La MacBook Neo **no tiene notch**: la cámara de 1080p va en el marco superior y la pantalla empieza justo debajo. Por eso un notch dibujado por software queda pegado a la cámara y se ve natural. En Macs que sí tienen notch también funciona.

### Problema que resuelve

Cuando lees un guion en otra ventana, la mirada se desvía de la cámara y se nota. Los teleprompters de hardware son caros y las apps normales ocupan espacio en pantalla y se ven al compartir.

### Público objetivo

Presentadores, docentes, creadores de contenido, personas que graban videos o hacen reuniones y presentaciones en línea.

---

## 2. Funcionalidades

### Modo normal (notch sin desplegar)
- Notch negro y angosto, más ancho que uno real para que el texto se lea cómodo.
- 1 o 2 líneas visibles, con la línea actual resaltada y las siguientes atenuadas.
- Botón de **pausa/play** junto al texto.
- Avance **línea a línea** con animación suave.
- **Avanza mientras hablas** y se detiene en silencio.

### Modo desplegado (panel de control)
- Editar, pegar e importar el guion.
- Velocidad de avance.
- Tamaño de letra.
- **Grosor** de letra (regular, medio, semibold, bold).
- **Color** del texto.
- Ancho del notch y número de líneas visibles.
- Sensibilidad del micrófono.
- Configuración de atajos.

### Ocultar
- Atajo de teclado global para **colapsar u ocultar** el notch al instante.
- Modo seguro: se reduce a un notch negro sin texto.

### Para una versión posterior
- Seguimiento **palabra por palabra** de lo que dices, comparando tu voz con el guion.
- Varios guiones guardados.
- Temporizador y palabras por minuto.
- Notas por diapositiva.
- Soporte para otros idiomas.

---

## 3. Stack recomendado

| Parte | Tecnología | Por qué |
|---|---|---|
| Lenguaje | **Swift** | Control total del sistema y de las ventanas en macOS |
| Interfaz | **SwiftUI** | Animaciones fluidas y poco código |
| Ventana del notch | **AppKit** (`NSPanel`) | SwiftUI solo no permite posicionar ni controlar el nivel de la ventana |
| Audio | **AVFoundation** (`AVAudioEngine`) | Detectar cuándo hablas |
| Voz a texto (después) | **Speech** (`SFSpeechRecognizer`) o `SpeechAnalyzer` | Seguir el guion palabra por palabra, en el propio equipo |
| Atajos globales | Paquete **KeyboardShortcuts** (o Carbon `RegisterEventHotKey`) | Atajos que funcionan aunque la app no esté en primer plano |
| Barra de menú | `MenuBarExtra` | Acceso rápido sin ícono en el Dock |
| Guardado | `UserDefaults` / `@AppStorage` y archivos en Application Support | Ajustes y guiones |
| IDE | **Xcode** | Compilar y probar |

**Alternativa:** Tauri o Electron. Sirven si algún día quieres Windows, pero el resultado se siente menos nativo y hay que cuidar más el consumo de recursos.

**Versión mínima de macOS sugerida:** 14 o superior.

---

## 4. Arquitectura

```
Guino/
├── GuinoApp.swift              # Punto de entrada, MenuBarExtra
├── Window/
│   ├── NotchPanel.swift        # NSPanel sin bordes, nivel alto, posición
│   └── NotchWindowController.swift
├── Views/
│   ├── NotchShape.swift        # Forma con esquinas inferiores redondeadas
│   ├── NotchView.swift         # Modo normal: texto + botón de pausa
│   ├── ControlPanelView.swift  # Modo desplegado: ajustes y editor
│   └── TeleprompterTextView.swift
├── Core/
│   ├── TeleprompterEngine.swift   # Estado, velocidad, línea actual
│   ├── VoiceActivityDetector.swift # Detecta si hablas
│   └── HotkeyManager.swift        # Atajos globales
├── Models/
│   ├── Script.swift
│   └── Settings.swift
└── Resources/
```

### Piezas principales
- **NotchPanel**: ventana flotante sin bordes, fondo transparente, siempre visible, que no roba el foco.
- **TeleprompterEngine**: decide qué línea se muestra y cuándo avanzar, según velocidad, pausa y detección de voz.
- **VoiceActivityDetector**: mide el nivel del micrófono y decide si estás hablando.
- **HotkeyManager**: atajos para pausar, ocultar y desplegar.

---

## 5. Detalles técnicos clave

### 5.1 Ventana del notch

```swift
final class NotchPanel: NSPanel {
    init(contentView: NSView) {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .screenSaver               // por encima de la barra de menú
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        sharingType = .none                // intenta excluirla de la captura
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary,
                              .stationary, .ignoresCycle]
        self.contentView = contentView
    }

    override var canBecomeKey: Bool { true }   // necesario para editar texto

    // Evita que macOS empuje la ventana debajo de la barra de menú
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }

    func place(width: CGFloat, height: CGFloat) {
        guard let screen = NSScreen.screens.first else { return }
        let f = screen.frame
        setFrame(NSRect(x: f.midX - width / 2,
                        y: f.maxY - height,
                        width: width,
                        height: height),
                 display: true)
    }
}
```

### 5.2 Forma del notch
Rectángulo negro con las **esquinas inferiores redondeadas** (en SwiftUI, `UnevenRoundedRectangle`). Opcional: pequeñas curvas invertidas arriba para imitar el notch real.

### 5.3 Texto línea a línea
- Dividir el guion en líneas según el ancho disponible.
- Definir la velocidad en **palabras por minuto** y convertirla en el tiempo que dura cada línea (según cuántas palabras tiene).
- Animar el cambio de línea con una curva suave (ease in-out), no a saltos.
- Resaltar la línea actual y atenuar las siguientes.

### 5.4 Detección de voz (nivel fácil)
- `AVAudioEngine` con un *tap* en el micrófono.
- Calcular el nivel (RMS → dB) por cada bloque de audio.
- Usar un **umbral con histéresis**: se considera "hablando" si supera el umbral un instante, y se considera "silencio" solo si baja del umbral durante un tiempo (por ejemplo, medio segundo). Así no se corta en las pausas naturales.
- Requiere el permiso de micrófono (`NSMicrophoneUsageDescription` en el Info.plist).
- Mientras `hablando == true` y no está en pausa, el motor avanza.

### 5.5 Seguimiento palabra por palabra (después)
- Transcribir en el propio equipo con `SFSpeechRecognizer` (`requiresOnDeviceRecognition = true`) o con `SpeechAnalyzer` en las versiones nuevas de macOS (verificar disponibilidad).
- Comparar de forma flexible lo que dices con el guion (tolerando palabras saltadas, repetidas o improvisadas) y mover la línea actual al punto donde vas.
- Es la parte más compleja del proyecto.

### 5.6 Atajos globales (ejemplos)
| Acción | Atajo sugerido |
|---|---|
| Pausar / reanudar | `⌥ + Espacio` |
| Ocultar / mostrar el notch | `⌥ + H` |
| Desplegar / colapsar el panel | `⌥ + D` |
| Subir / bajar velocidad | `⌥ + ↑` / `⌥ + ↓` |

Todos configurables por el usuario.

### 5.7 App sin ícono en el Dock
En el Info.plist, `LSUIElement = YES`. La app vive en la barra de menú y en el notch.

---

## 6. Ocultarlo al compartir o grabar: límites reales

`NSWindow.sharingType = .none` es el mecanismo estándar para pedirle a macOS que excluya una ventana de la captura. Pero **no es una garantía total**.

| Situación | Resultado esperado |
|---|---|
| Compartir pantalla en Zoom, Meet o Teams | Normalmente **se oculta**. Hay que probarlo en tu versión de macOS y en cada app |
| Grabadores basados en ScreenCaptureKit (QuickTime, OBS) en macOS 15 o superior | **Puede aparecer** igual; no hay una forma pública de evitarlo |
| Capturas de pantalla en tu propio Mac | **Probablemente aparezca** (comportamiento normal de macOS). Sin verificar en tu equipo |

### Cómo reducir el riesgo
1. **Atajo para ocultarlo al instante** antes de compartir o grabar.
2. **Modo seguro**: colapsa a un notch negro sin texto, que sobre el marco oscuro pasa casi desapercibido.
3. **Probar siempre** antes de usarlo en una situación importante.

### Matriz de pruebas (hacer en la fase 6)
- [ ] Zoom: compartir pantalla completa
- [ ] Zoom: compartir una sola ventana
- [ ] Google Meet (Chrome): compartir pantalla completa y pestaña
- [ ] Microsoft Teams: compartir pantalla completa
- [ ] QuickTime: grabación de pantalla
- [ ] OBS: captura de pantalla
- [ ] `⌘ + ⇧ + 3`, `⌘ + ⇧ + 4` y `⌘ + ⇧ + 5`

---

## 7. Plan de desarrollo en 7 fases

### Fase 1: Proyecto base y notch estático
**Objetivo:** tener el notch negro pegado debajo de la cámara.
- Crear el proyecto en Xcode (SwiftUI, macOS 14+).
- Configurar `LSUIElement` y el `MenuBarExtra`.
- Crear `NotchPanel` y posicionarlo en el centro superior de la pantalla.
- Dibujar la forma del notch con esquinas inferiores redondeadas.
- Probar que se mantiene por encima de la barra de menú y en todos los espacios.

**Criterio de éxito:** el notch aparece centrado, pegado al borde superior y no roba el foco al hacer clic en otras apps.
**Esfuerzo:** bajo.

---

### Fase 2: Teleprompter básico
**Objetivo:** que el guion se muestre y avance en el notch.
- Cargar un guion de prueba.
- Mostrar 1 o 2 líneas, con la actual resaltada.
- Avance línea a línea con animación suave y velocidad fija.
- Botón de **pausa/play** junto al texto.

**Criterio de éxito:** el texto se lee bien, avanza sin saltos y se puede pausar.
**Esfuerzo:** medio.

---

### Fase 3: Panel desplegable y editor de guion
**Objetivo:** poder configurar y editar sin salir de la app.
- Al presionar el notch, expandirlo hacia abajo con animación.
- Editor de texto para pegar o escribir el guion.
- Control de velocidad (palabras por minuto).
- Guardar guion y ajustes con `@AppStorage` y archivos.

**Criterio de éxito:** editas el guion, cambias la velocidad, colapsas el panel y todo se conserva al cerrar y abrir la app.
**Esfuerzo:** medio.

---

### Fase 4: Personalización visual
**Objetivo:** que el texto sea cómodo de leer para cada persona.
- Tamaño de letra.
- **Grosor** de letra.
- **Color** del texto y de las líneas atenuadas.
- Ancho del notch y número de líneas visibles.
- Vista previa en vivo dentro del panel.

**Criterio de éxito:** cada cambio se ve al instante en el notch y se guarda.
**Esfuerzo:** bajo a medio.

---

### Fase 5: Detección de voz
**Objetivo:** que el texto avance solo mientras hablas.
- Pedir permiso de micrófono.
- Implementar `VoiceActivityDetector` con `AVAudioEngine` y umbral con histéresis.
- Conectarlo al motor: avanza si hablas y no está en pausa.
- Ajuste de **sensibilidad** en el panel.
- Indicador discreto de "te escucho".

**Criterio de éxito:** el texto avanza al hablar, se detiene en silencio sin cortarse en pausas cortas y la pausa manual tiene prioridad.
**Esfuerzo:** medio.

---

### Fase 6: Atajos, modo oculto y pruebas de captura
**Objetivo:** controlarlo sin tocar el mouse y reducir el riesgo al compartir.
- Atajos globales (pausa, ocultar, desplegar, velocidad).
- Activar `sharingType = .none`.
- Modo seguro: colapsar a notch negro sin texto.
- Ejecutar la **matriz de pruebas** de la sección 6 y documentar qué funciona y qué no.

**Criterio de éxito:** sabes con certeza en qué apps se oculta y en cuáles no, y el atajo funciona al instante.
**Esfuerzo:** medio.

---

### Fase 7: Pulido, empaquetado y mejoras
**Objetivo:** dejarlo listo para usar a diario (y, si quieres, compartir).
- Revisar rendimiento, consumo de batería y errores.
- Icono de la app, nombre y pantalla de bienvenida con los permisos.
- Varios guiones guardados.
- Empaquetado: para uso personal basta ejecutarlo desde Xcode; para distribuirlo hay que firmarlo y notarizarlo con una cuenta de desarrollador de Apple.
- **Opcional:** seguimiento palabra por palabra con reconocimiento de voz.

**Criterio de éxito:** la app es estable durante una sesión larga y está lista para usarse en una presentación real.
**Esfuerzo:** medio a alto.

---

## 8. Riesgos y cómo manejarlos

| Riesgo | Mitigación |
|---|---|
| El notch aparece en una captura o grabación | Atajo de ocultar, modo seguro y pruebas previas |
| macOS cambia el comportamiento de `sharingType` | Probar después de cada actualización importante |
| La detección de voz corta el texto en pausas cortas | Histéresis y ajuste de sensibilidad |
| Ruido de fondo activa el avance | Umbral configurable |
| Seguimiento por palabras impreciso | Dejarlo para después y mantener siempre el modo simple como respaldo |
| La ventana queda debajo de la barra de menú | Sobrescribir `constrainFrameRect` y usar un nivel de ventana alto |

---

## 9. Uso responsable

Guino está pensado para **presentaciones, clases, videos y reuniones**, donde quien habla tiene su propio guion. Presentarlo como una herramienta para esconder ayuda en entrevistas o exámenes sería un problema ético y de reputación, y puede romper las reglas de esos contextos. Conviene posicionarlo desde el principio como una herramienta de **comunicación**.

---

## 10. Próximos pasos

1. Crear el proyecto en Xcode y completar la **Fase 1**.
2. Probar `sharingType = .none` lo antes posible en Zoom, Meet y Teams, para saber si la idea de ocultarlo funciona en tu equipo.
3. Avanzar por las fases en orden.
