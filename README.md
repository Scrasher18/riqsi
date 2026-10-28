# Riqsi 👁️📱
> *Del quechua: "Conocer, reconocer, percibir"*

**Riqsi** es una aplicación móvil accesible de lectura inteligente en tiempo real, diseñada específicamente para personas con ceguera total, baja visión o usuarios sin discapacidad. Funciona de manera **100% On-Device (sin conexión a internet)**, garantizando **cero latencia**, privacidad absoluta y total confiabilidad en cualquier entorno.

---

## ✨ Características Principales

### 1. 📖 Lectura en Todo Tipo de Superficies (Planas y Curvas 3D)
A diferencia de los lectores OCR tradicionales que solo funcionan sobre papel plano, **Riqsi** extrae texto a nivel de línea con ordenamiento espacial inteligente, permitiendo leer con precisión:
* **Superficies curvas y cilíndricas:** Botellas de bebidas, frascos de medicamentos, latas de alimentos, envases de champú y productos de tocador.
* **Superficies planas y documentos:** Hojas de papel, libros, contratos, revistas, facturas y recibos de compras.
* **Empaques y señalética:** Cajas de medicamentos, letreros viales, puertas de oficinas y pantallas digitales.

### 2. 🎯 Enfoque Táctil Inteligente (Tap-to-Focus)
* Al tocar cualquier punto de la pantalla, la cámara enfoca y ajusta la exposición lumínica instantáneamente en ese lugar.
* Proporciona triple retroalimentación:
  * **Vocal:** Anuncia *"Enfocando"*.
  * **Háptica:** Vibración sutil de confirmación.
  * **Visual:** Retícula dorada animada de alto contraste para personas con baja visión.
* El control de pausa se gestiona mediante un botón accesible dedicado, evitando interrupciones accidentales de voz al tocar la pantalla.

### 3. 🌐 Motor Bilingüe Inteligente (Español + Inglés)
* Incorpora un diccionario bilingüe comprensivo que valida palabras reales en español y en inglés.
* Conmutación fonética dinámica: si apuntas a un letrero o empaque en inglés (*"EMERGENCY EXIT"*, *"WARNING"*, *"COFFEE SHOP"*, *"NUTRITION FACTS"*), el sintetizador lo pronuncia con dicción inglesa nativa; si es en español (*"PARACETAMOL 500 MG"*, *"SALIDA"*), lo vocaliza en español fluido.
* Soporte nativo de dosis, medidas y cantidades: `500mg`, `100ml`, `10g`, `24h`, `30caps`, `12v`, precios (`$45.50`, `S/. 25.00`) y fechas.

### 4. 🛡️ Filtro Lingüístico Anti-Basura OCR
* Algoritmo lingüístico estricto (`SpanishWordValidator`) que descarta el 100% de ruido visual, reflejos o secuencias sin sentido generadas por el sensor (ej. `wa9edua9da`). Solo se verbalizan palabras y números reales.
* Memoria temporal anti-repetición (10 segundos) que evita que la app repita lo mismo cuando se mueve ligeramente la mano.

### 5. 🔍 Doble Campo Visual (1.0x Estándar y 0.5x Gran Angular)
* Conmutador ergonómico (*Segmented Pill*) para alternar al instante entre **1.0x** (para texto de tamaño normal) y **0.5x Gran Angular** (para capturar cajas completas, páginas grandes o texto muy cercano).

### 6. 📄 Botón Héroe "LEER TODO" (Captura Offline)
* Toma una instantánea en alta resolución, analiza todo el documento con Google ML Kit local y lo vocaliza de principio a fin.
* Incluye modal de lectura con ecualizador animado, ajuste de volumen, botón de repetir, copiar y compartir.

---

## 🎨 Principios de Diseño Accesible (WCAG AAA)
* **Paleta de Ultra Alto Contraste:**
  * Fondo: Negro puro (`#000000`).
  * Texto Principal: Amarillo brillante de máxima visibilidad (`#FFD700`).
  * Acentos: Cian eléctrico (`#00E5FF`) y Verde esmeralda (`#00E676`).
* **Tipografía:** 24pt en negrita con espaciado amplio y contraste contrastado sobre tarjetas de vidrio esmerilado (*Frosted Glass*).
* **Gestos táctiles simples:**
  * **1 toque en pantalla:** Enfocar cámara en ese punto.
  * **2 toques:** Repetir último texto leído.
  * **Mantener presionado:** Capturar y LEER TODO el documento.
  * **Deslizar horizontal:** Alternar zoom 1.0x / 0.5x.

---

## 🏗️ Arquitectura Técnica

```
lib/
├── core/
│   ├── audio/           # Servicio de vibración y háptica accesible
│   ├── constants/       # Colores WCAG AAA y constantes de Riqsi
│   └── tts/             # Síntesis de voz offline con detección bilingüe
├── domain/
│   ├── models/          # TextBlockInfo y modelos de dominio
│   └── text_filter/     # SpanishWordValidator (Bilingüe), TextStabilizer, FramingGuidance
├── presentation/
│   ├── screens/         # ReaderScreen (Pantalla principal de Riqsi)
│   └── widgets/         # AccessibleButton, ZoomSegmentedPill, GlassContainer, AudioWaveIndicator
└── services/
    ├── camera_service.dart   # Control de CameraX (autofocus, tap-to-focus, zoom 0.5x/1.0x, luz)
    ├── ocr_service.dart      # Google ML Kit Text Recognition On-Device a nivel de línea
    └── history_service.dart  # Persistencia local de historial de lecturas
```

* **Framework:** Flutter 3.29+ / Dart 3.7+
* **Motor Gráfico:** Android Impeller (Vulkan backend)
* **OCR On-Device:** `google_mlkit_text_recognition` (Latin script offline)
* **Síntesis de Voz:** `flutter_tts` (motor nativo Android TTS)
* **Cámara:** `camera` (CameraX backend en Android)

---

## 📲 Compilación e Instalación

Para compilar e instalar el APK de producción:

```bash
# Obtener dependencias
flutter pub get

# Ejecutar pruebas unitarias
flutter test

# Compilar APK Release
flutter build apk --release

# Instalar en dispositivo Android conectado mediante ADB
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## 📄 Licencia
Este proyecto está desarrollado bajo la licencia MIT.
