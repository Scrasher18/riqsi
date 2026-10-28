import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_constants.dart';
import '../../core/audio/sound_service.dart';
import '../../core/tts/tts_service.dart';
import '../../domain/models/text_block_info.dart';
import '../../domain/text_filter/text_stabilizer.dart';
import '../../domain/text_filter/framing_guidance.dart';
import '../../services/camera_service.dart';
import '../../services/ocr_service.dart';
import '../widgets/accessible_button.dart';
import '../widgets/zoom_segmented_pill.dart';
import '../widgets/glass_container.dart';
import '../widgets/audio_wave_indicator.dart';
import '../widgets/text_display_modal.dart';
import '../widgets/framing_radar_overlay.dart';

/// Pantalla principal de Riqsi: Lectura accesible, 100% offline, bilingüe y robusta.
/// Lee textos con precisión tanto en superficies planas (hojas, libros, recibos)
/// como en superficies curvas o 3D (botellas, frascos de medicamentos, latas, empaques y pantallas).
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService.instance;
  final OcrService _ocrService = OcrService.instance;
  final TtsService _ttsService = TtsService.instance;
  final TextStabilizer _textStabilizer = TextStabilizer();
  final FramingGuidance _framingGuidance = FramingGuidance();

  bool _isCameraReady = false;
  bool _hasPermission = false;
  bool _isPaused = false;
  bool _isProcessingSnapshot = false;
  bool _isInitializingApp = false;

  String _currentRecognizedText = '';
  String? _documentCapturedText;
  List<TextBlockInfo> _detectedBlocks = [];
  Size _previewSize = Size.zero;

  // Estado del indicador visual y háptico de autoenfoque
  Offset? _focusTapPosition;
  Timer? _focusRingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _iniciarApp();
  }

  @override
  void dispose() {
    _focusRingTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    _ocrService.dispose();
    _ttsService.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraService.stopImageStream();
      _ttsService.stop();
    } else if (state == AppLifecycleState.resumed && _hasPermission && !_isInitializingApp) {
      _reanudarCamara();
    }
  }

  /// Inicialización de permisos, síntesis de voz, cámara y bienvenida auditiva
  Future<void> _iniciarApp() async {
    if (_isInitializingApp) return;
    _isInitializingApp = true;

    try {
      await _ttsService.initialize();

      final status = await Permission.camera.request();
      if (status.isGranted) {
        if (mounted) setState(() => _hasPermission = true);
        final camOk = await _cameraService.initialize();
        if (camOk && mounted) {
          final controller = _cameraService.controller;
          if (controller != null && controller.value.previewSize != null) {
            _previewSize = Size(
              controller.value.previewSize!.width,
              controller.value.previewSize!.height,
            );
          }
          if (mounted) setState(() => _isCameraReady = true);
          _iniciarFlujoLecturaEnVivo();

          // Anuncio vocal de bienvenida con guía de uso concisa
          await _ttsService.speak(
            'Bienvenido a Riqsi. Lector de texto activado. '
            'Apunte la cámara a cualquier texto, botella, empaque o letrero en español o inglés. '
            'Toque la pantalla en cualquier lugar para enfocar la cámara. '
            'Use el botón inferior para pausar la lectura.',
            interrupt: true,
          );
        }
      } else {
        if (mounted) setState(() => _hasPermission = false);
        await _ttsService.speak(AppConstants.mensajePermisoCamara, interrupt: true);
      }
    } finally {
      _isInitializingApp = false;
    }
  }

  /// Inicia el bucle de procesamiento continuo en tiempo real (100% Offline On-Device a 60 FPS)
  void _iniciarFlujoLecturaEnVivo() {
    if (!_cameraService.isInitialized) return;

    _cameraService.startImageStream((CameraImage image) async {
      if (_isPaused || _isProcessingSnapshot || !mounted) return;

      // 1. Verificación automática de luz tenue para sugerir linterna
      await _cameraService.verificarIluminacion(image);

      final cameraDesc = _cameraService.currentCamera;
      if (cameraDesc == null) return;

      // 2. Reconocimiento de texto On-Device (Google ML Kit offline instantáneo a nivel de línea)
      final bloques = await _ocrService.procesarCuadroCamara(
        cameraImage: image,
        cameraDescription: cameraDesc,
      );

      if (mounted) {
        setState(() {
          _detectedBlocks = bloques;
        });
      }

      // 3. Guía de encuadre auditiva inteligente (no bloquea la lectura)
      if (!mounted) return;
      final guiaEncuadre = _framingGuidance.analizarEncuadre(
        bloques: bloques,
        vistaAncho: _previewSize.width > 0 ? _previewSize.width : 720,
        vistaAlto: _previewSize.height > 0 ? _previewSize.height : 1280,
      );

      if (guiaEncuadre != null && !_ttsService.isSpeaking) {
        await SoundService.instance.vibrarTextoDetectado();
        _ttsService.speak(guiaEncuadre, interrupt: false);
      }

      // 4. Filtro lingüístico bilingüe estricto (Español + Inglés) y ordenamiento espacial 3D
      final textoValido = _textStabilizer.procesarYFiltrar(
        bloques,
        tamanoImagen: _previewSize,
      );

      if (textoValido != null && mounted) {
        setState(() {
          _currentRecognizedText = textoValido;
        });

        // Vibración háptica sutil de confirmación
        await SoundService.instance.vibrarTextoDetectado();

        // 5. Sintetizar en voz alta con detección de idioma automática
        await _ttsService.speak(textoValido, interrupt: false);
      }
    });
  }

  Future<void> _reanudarCamara() async {
    final camOk = await _cameraService.initialize();
    if (camOk && mounted) {
      setState(() => _isCameraReady = true);
      _iniciarFlujoLecturaEnVivo();
    }
  }

  /// Enfoca manualmente la cámara en el punto exacto de la pantalla donde pulsó el usuario
  void _enfocarPunto(Offset localPosition) {
    final screenSize = MediaQuery.of(context).size;
    final normalized = Offset(
      (localPosition.dx / screenSize.width).clamp(0.05, 0.95),
      (localPosition.dy / screenSize.height).clamp(0.05, 0.95),
    );

    // Mostrar anillo animado de enfoque
    setState(() {
      _focusTapPosition = localPosition;
    });

    _focusRingTimer?.cancel();
    _focusRingTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _focusTapPosition = null;
        });
      }
    });

    _cameraService.enfocarEnPunto(normalized);
    _ttsService.speak('Enfocando', interrupt: false);
  }

  /// Alterna entre modo de cámara 1.0x Estándar y 0.5x Gran Angular
  Future<void> _alternarZoom() async {
    await _cameraService.toggleZoom();
    _textStabilizer.resetearHistorial();
    if (mounted) setState(() {});
  }

  /// Pausa o reanuda la lectura por voz mediante el botón accesible dedicado
  Future<void> _alternarPausa() async {
    setState(() {
      _isPaused = !_isPaused;
    });

    await SoundService.instance.vibrarPausaReanudar();

    if (_isPaused) {
      await _ttsService.stop();
      await _ttsService.speak(AppConstants.mensajePausa, interrupt: true);
    } else {
      _textStabilizer.resetearHistorial();
      await _ttsService.speak(AppConstants.mensajeReanudar, interrupt: true);
    }
  }

  /// Repite el último texto registrado
  Future<void> _repetirUltimoTexto() async {
    final ultimo = _textStabilizer.ultimoTextoEmitido;
    if (ultimo.isNotEmpty) {
      await SoundService.instance.vibrarSeleccion();
      await _ttsService.speak('Repitiendo: $ultimo', interrupt: true);
    } else {
      await _ttsService.speak('Aún no se ha detectado ningún texto para repetir.', interrupt: true);
    }
  }

  /// Alterna la linterna con anuncio de voz y vibración
  Future<void> _alternarLinterna() async {
    await _cameraService.toggleTorch();
    if (mounted) setState(() {});
  }

  /// Modo Captura Completa (LEER TODO): Foto en alta resolución para lectura 100% offline
  Future<void> _capturarYLeerTodo() async {
    if (_isProcessingSnapshot) return;

    setState(() {
      _isProcessingSnapshot = true;
    });
    await SoundService.instance.vibrarCapturaFoto();
    await _ttsService.speak('Capturando texto completo. Por favor espere.', interrupt: true);

    try {
      await _cameraService.stopImageStream();

      final fotoPath = await _cameraService.takePicture();
      if (fotoPath == null) {
        await _ttsService.speak('Error al capturar. Intente nuevamente.', interrupt: true);
        setState(() => _isProcessingSnapshot = false);
        _iniciarFlujoLecturaEnVivo();
        return;
      }

      // Procesar imagen completa en alta resolución con ML Kit offline y filtro bilingüe
      final bloques = await _ocrService.procesarArchivoImagen(fotoPath);
      final estabilizadorFoto = TextStabilizer();
      final textoCompleto = estabilizadorFoto.procesarYFiltrar(
        bloques,
        ignorarFiltroTemporal: true,
      );

      if (textoCompleto != null && textoCompleto.trim().isNotEmpty) {
        setState(() {
          _documentCapturedText = textoCompleto;
        });

        final cantPalabras = textoCompleto.split(RegExp(r'\s+')).length;
        await _ttsService.speak(
          'Texto capturado. Leyendo $cantPalabras palabras: $textoCompleto',
          interrupt: true,
        );
      } else {
        await _ttsService.speak(AppConstants.mensajeSinTexto, interrupt: true);
        _iniciarFlujoLecturaEnVivo();
      }
    } catch (e) {
      debugPrint('Error en captura completa: $e');
      await _ttsService.speak('Ocurrió un error al procesar el texto.', interrupt: true);
      _iniciarFlujoLecturaEnVivo();
    } finally {
      if (mounted) setState(() => _isProcessingSnapshot = false);
    }
  }

  /// Cierra el visor de documento y regresa a la cámara en vivo
  void _cerrarVisorDocumento() {
    setState(() {
      _documentCapturedText = null;
    });
    _textStabilizer.resetearHistorial();
    _iniciarFlujoLecturaEnVivo();
    _ttsService.speak('Regresando a cámara en vivo.', interrupt: true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.no_photography, size: 80, color: AppConstants.colorAlerta),
                const SizedBox(height: 20),
                const Text(
                  'SE REQUIERE ACCESO A LA CÁMARA',
                  style: TextStyle(
                    color: AppConstants.colorTextoPrincipal,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                AccessibleButton(
                  label: 'Conceder Permiso',
                  semanticHint: 'Presione para autorizar el uso de la cámara',
                  icon: Icons.check_circle,
                  isActive: true,
                  onPressed: _iniciarApp,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_documentCapturedText != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: TextDisplayModal(
          text: _documentCapturedText!,
          onClose: _cerrarVisorDocumento,
        ),
      );
    }

    final cameraController = _cameraService.controller;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Al tocar la pantalla: Enfoca la cámara exactamente en ese punto
          onTapDown: (details) => _enfocarPunto(details.localPosition),
          // Dos toques: Repetir último texto leído
          onDoubleTap: _repetirUltimoTexto,
          // Mantener presionado: LEER TODO (captura completa en alta resolución)
          onLongPress: _capturarYLeerTodo,
          // Deslizar horizontalmente: Cambiar zoom entre 1.0x y 0.5x Gran Angular
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 100) {
              _alternarZoom();
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Vista previa de la cámara CameraX
              if (_isCameraReady &&
                  cameraController != null &&
                  cameraController.value.isInitialized &&
                  cameraController.value.previewSize != null)
                Center(
                  child: AspectRatio(
                    aspectRatio: cameraController.value.previewSize!.height /
                        cameraController.value.previewSize!.width,
                    child: CameraPreview(cameraController),
                  ),
                )
              else
                const Center(
                  child: CircularProgressIndicator(color: AppConstants.colorTextoPrincipal),
                ),

              // 2. HUD minimalista de recuadros detectados
              if (_previewSize != Size.zero)
                FramingRadarOverlay(
                  bloques: _detectedBlocks,
                  previewSize: _previewSize,
                  screenSize: screenSize,
                ),

              // Oscurecedor de contraste para legibilidad de textos y controles
              Container(color: Colors.black.withValues(alpha: 0.22)),

              // 3. Barra Superior Minimalista: Segmented Zoom Pill y Estado con Ecualizador
              Positioned(
                top: 14,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Segmented Zoom Pill (0.5x Gran Angular / 1.0x Estándar)
                    ZoomSegmentedPill(
                      currentMode: _cameraService.currentZoomMode,
                      onModeChanged: (_) => _alternarZoom(),
                    ),

                    // Indicador de Estado Dinámico con Onda de Audio
                    ValueListenableBuilder<bool>(
                      valueListenable: _ttsService.isSpeakingNotifier,
                      builder: (context, isSpeaking, _) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isPaused
                                ? AppConstants.colorAlerta.withValues(alpha: 0.92)
                                : Colors.black.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: _isPaused ? Colors.white : AppConstants.colorExito,
                              width: 2.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!_isPaused && isSpeaking) ...[
                                const AudioWaveIndicator(
                                  isSpeaking: true,
                                  color: AppConstants.colorExito,
                                ),
                                const SizedBox(width: 8),
                              ] else ...[
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isPaused ? Colors.white : AppConstants.colorExito,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                _isPaused
                                    ? 'EN PAUSA'
                                    : (isSpeaking ? 'LEYENDO' : 'EN VIVO'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 4. Área Central: Visor de Texto Frosted Glass de Ultra-Alto Contraste
              Positioned(
                top: 74,
                left: 16,
                right: 16,
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  borderRadius: 24,
                  backgroundColor: Colors.black.withValues(alpha: 0.88),
                  borderColor: _currentRecognizedText.isNotEmpty
                      ? AppConstants.colorTextoPrincipal
                      : Colors.white.withValues(alpha: 0.25),
                  borderWidth: _currentRecognizedText.isNotEmpty ? 2.5 : 1.5,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_currentRecognizedText.isNotEmpty) ...[
                            Text(
                              _currentRecognizedText,
                              style: const TextStyle(
                                color: AppConstants.colorTextoPrincipal,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                height: 1.35,
                                letterSpacing: 0.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ] else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.center_focus_strong,
                                  color: AppConstants.colorTextoPrincipal,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Riqsi • Texto en Español o Inglés',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Toque la pantalla para enfocar • "LEER TODO" para capturar',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppConstants.colorAcento.withValues(alpha: 0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 5. Retícula visual de autoenfoque cuando el usuario pulsa la pantalla
              if (_focusTapPosition != null)
                Positioned(
                  left: _focusTapPosition!.dx - 35,
                  top: _focusTapPosition!.dy - 35,
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.35, end: 1.0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppConstants.colorTextoPrincipal,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppConstants.colorTextoPrincipal.withValues(alpha: 0.45),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.filter_center_focus,
                                color: AppConstants.colorTextoPrincipal,
                                size: 26,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // 6. Panel Inferior Limpio y Ergonómico: 3 Controles Clave 100% Offline
              Positioned(
                bottom: 20,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    // Botón 1: Linterna
                    Expanded(
                      flex: 3,
                      child: AccessibleButton(
                        label: _cameraService.isTorchOn ? 'Luz ON' : 'Luz OFF',
                        semanticHint: 'Enciende o apaga la linterna',
                        icon: _cameraService.isTorchOn ? Icons.flash_on : Icons.flash_off,
                        isActive: _cameraService.isTorchOn,
                        activeColor: AppConstants.colorTextoPrincipal,
                        onPressed: _alternarLinterna,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Botón 2: Hero Action LEER TODO (Captura de documento / texto completo 100% Offline)
                    Expanded(
                      flex: 4,
                      child: AccessibleButton(
                        label: _isProcessingSnapshot ? 'Leyendo...' : 'LEER TODO',
                        semanticHint: 'Captura y lee la página o empaque completo de corrido sin conexión',
                        icon: Icons.document_scanner,
                        isActive: true,
                        isHeroAction: true,
                        onPressed: _capturarYLeerTodo,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Botón 3: Pausar / Reanudar (Control exclusivo de pausa para evitar toques accidentales)
                    Expanded(
                      flex: 3,
                      child: AccessibleButton(
                        label: _isPaused ? 'Reanudar' : 'Pausar',
                        semanticHint: 'Pausa o reactiva la síntesis de voz',
                        icon: _isPaused ? Icons.play_arrow : Icons.pause,
                        isActive: _isPaused,
                        activeColor: AppConstants.colorAlerta,
                        onPressed: _alternarPausa,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
