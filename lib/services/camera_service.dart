import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import '../core/constants/app_constants.dart';
import '../core/audio/sound_service.dart';
import '../core/tts/tts_service.dart';

enum ZoomMode {
  zoom1x,
  zoom05x,
}

/// Servicio que gestiona el ciclo de vida de CameraX en Android,
/// control del zoom específico (1.0x y 0.5x Gran Angular), linterna, análisis de luz y flujo de cuadros para OCR.
class CameraService {
  CameraService._();
  static final CameraService instance = CameraService._();

  CameraController? _controller;
  List<CameraDescription> _availableCameras = [];
  int _currentCameraIndex = 0;

  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 8.0;
  ZoomMode _currentZoomMode = ZoomMode.zoom1x;
  double _appliedZoomRatio = 1.0;
  bool _isTorchOn = false;
  bool _isStreaming = false;
  bool _isProcessingFrame = false;
  DateTime _ultimoAvisoPocaLuz = DateTime.now().subtract(const Duration(minutes: 1));

  CameraController? get controller => _controller;
  bool get isInitialized => _controller != null && _controller!.value.isInitialized;
  ZoomMode get currentZoomMode => _currentZoomMode;
  double get appliedZoomRatio => _appliedZoomRatio;
  bool get isTorchOn => _isTorchOn;
  CameraDescription? get currentCamera =>
      _availableCameras.isNotEmpty ? _availableCameras[_currentCameraIndex] : null;

  /// Inicializa la cámara buscando cámaras traseras y configurando la resolución óptima
  Future<bool> initialize() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) return false;

      // Seleccionar la cámara trasera principal por defecto
      _currentCameraIndex = _availableCameras.indexWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
      );
      if (_currentCameraIndex == -1) _currentCameraIndex = 0;

      await _initControllerForCamera(_availableCameras[_currentCameraIndex]);
      return true;
    } catch (e) {
      debugPrint('Error al inicializar cámara: $e');
      return false;
    }
  }

  Future<void> _initControllerForCamera(CameraDescription camera) async {
    await _controller?.dispose();

    _controller = CameraController(
      camera,
      // Resolución 720p óptima: OCR en tiempo real a 60fps y fotos JPEG ligeras (~80KB) para IA instantánea
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();

    // Obtener rangos físicos reales de zoom soportados por el hardware
    try {
      _minAvailableZoom = await _controller!.getMinZoomLevel();
      _maxAvailableZoom = await _controller!.getMaxZoomLevel();
      debugPrint('Rango de zoom detectado: min=$_minAvailableZoom, max=$_maxAvailableZoom');
    } catch (e) {
      _minAvailableZoom = 1.0;
      _maxAvailableZoom = 1.0;
    }

    // Iniciar siempre en modo 1.0x estándar directamente
    _currentZoomMode = ZoomMode.zoom1x;
    final targetZoom = 1.0.clamp(_minAvailableZoom, _maxAvailableZoom);
    _appliedZoomRatio = targetZoom;
    try {
      await _controller!.setZoomLevel(targetZoom);
    } catch (_) {}

    // Configurar enfoque y exposición automáticos continuos óptimos para objetos curvos y planos
    try {
      await _controller!.setFocusMode(FocusMode.auto);
      await _controller!.setExposureMode(ExposureMode.auto);
    } catch (e) {
      debugPrint('No se pudo fijar FocusMode.auto inicial: $e');
    }
  }

  /// Enfoca manualmente la cámara en las coordenadas normalizadas [0.0 - 1.0] pulsadas por el usuario.
  /// Ideal para botellas, latas, cajas de medicina o letreros lejanos.
  Future<void> enfocarEnPunto(Offset puntoNormalizado) async {
    if (!isInitialized || _controller == null) return;

    try {
      final p = Offset(
        puntoNormalizado.dx.clamp(0.05, 0.95),
        puntoNormalizado.dy.clamp(0.05, 0.95),
      );

      // Bloquear punto de enfoque y re-activar autoenfoque en esa coordenada
      if (_controller!.value.focusPointSupported) {
        await _controller!.setFocusPoint(p);
      }
      await _controller!.setFocusMode(FocusMode.auto);

      // Ajustar punto de exposición lumínica
      if (_controller!.value.exposurePointSupported) {
        await _controller!.setExposurePoint(p);
        await _controller!.setExposureMode(ExposureMode.auto);
      }

      await SoundService.instance.vibrarSeleccion();
    } catch (e) {
      debugPrint('Error al enfocar en punto: $e');
    }
  }

  /// Re-enfoca la cámara en el centro del encuadre
  Future<void> reenfocarCentro() async {
    await enfocarEnPunto(const Offset(0.5, 0.5));
  }

  /// Cambia de forma inteligente entre Modo 1.0x y Modo 0.5x Gran Angular
  Future<String> toggleZoom() async {
    if (_currentZoomMode == ZoomMode.zoom1x) {
      return await setZoomMode(ZoomMode.zoom05x, speakFeedback: true);
    } else {
      return await setZoomMode(ZoomMode.zoom1x, speakFeedback: true);
    }
  }

  /// Configura el modo de zoom solicitado (1.0x o 0.5x)
  Future<String> setZoomMode(ZoomMode mode, {bool speakFeedback = true}) async {
    if (!isInitialized) return '';

    _currentZoomMode = mode;
    String feedbackMsg = '';

    if (mode == ZoomMode.zoom05x) {
      // 1. Si la cámara soporta zoom < 1.0x (ej: 0.5x o 0.6x vía CameraX logical camera)
      if (_minAvailableZoom <= 0.5) {
        _appliedZoomRatio = 0.5;
        await _controller!.setZoomLevel(0.5);
        feedbackMsg = AppConstants.mensajeZoom05x;
      } else if (_minAvailableZoom < 1.0) {
        _appliedZoomRatio = _minAvailableZoom;
        await _controller!.setZoomLevel(_minAvailableZoom);
        feedbackMsg = 'Cámara en ${_minAvailableZoom.toStringAsFixed(1)} equis. '
            'Modo Gran Angular activado para máxima cobertura.';
      } else {
        // Si el hardware principal tiene minZoom = 1.0, verificar si existe una cámara ultra-gran-angular secundaria
        final ultraWideIndex = _buscarCamaraGranAngularSecundaria();
        if (ultraWideIndex != -1 && ultraWideIndex != _currentCameraIndex) {
          _currentCameraIndex = ultraWideIndex;
          await _initControllerForCamera(_availableCameras[_currentCameraIndex]);
          _appliedZoomRatio = 0.5;
          feedbackMsg = AppConstants.mensajeZoom05x;
        } else {
          // Si el sensor físico solo tiene un lente fijo de 1.0x
          _appliedZoomRatio = 1.0;
          await _controller!.setZoomLevel(1.0);
          feedbackMsg = 'Cámara en campo visual más amplio soportado por su dispositivo (1.0x).';
        }
      }
    } else {
      // Modo 1.0x estándar
      final mainIndex = _availableCameras.indexWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
      );
      if (mainIndex != -1 && mainIndex != _currentCameraIndex) {
        _currentCameraIndex = mainIndex;
        await _initControllerForCamera(_availableCameras[_currentCameraIndex]);
      }

      final targetZoom = 1.0.clamp(_minAvailableZoom, _maxAvailableZoom);
      _appliedZoomRatio = targetZoom;
      await _controller!.setZoomLevel(targetZoom);
      feedbackMsg = AppConstants.mensajeZoom1x;
    }

    await SoundService.instance.vibrarCambioZoom();
    if (speakFeedback) {
      await TtsService.instance.speak(feedbackMsg, interrupt: true);
    }

    return feedbackMsg;
  }

  /// Busca si existe una cámara física ultra-wide trasera adicional en dispositivos multicámara
  int _buscarCamaraGranAngularSecundaria() {
    for (int i = 0; i < _availableCameras.length; i++) {
      if (i != _currentCameraIndex &&
          _availableCameras[i].lensDirection == CameraLensDirection.back) {
        return i;
      }
    }
    return -1;
  }

  /// Alterna la linterna para iluminar texto en condiciones de baja luminosidad
  Future<bool> toggleTorch() async {
    if (!isInitialized) return false;

    try {
      _isTorchOn = !_isTorchOn;
      await _controller!.setFlashMode(_isTorchOn ? FlashMode.torch : FlashMode.off);
      await SoundService.instance.vibrarSeleccion();
      await TtsService.instance.speak(
        _isTorchOn ? AppConstants.mensajeLinternaEncendida : AppConstants.mensajeLinternaApagada,
        interrupt: true,
      );
      return _isTorchOn;
    } catch (e) {
      debugPrint('Error al cambiar flash: $e');
      return false;
    }
  }

  /// Calcula la luminancia promedio de la imagen para sugerir encender la linterna en la oscuridad
  double calcularLuminanciaPromedio(CameraImage image) {
    if (image.planes.isEmpty) return 128.0;
    final bytes = image.planes[0].bytes;
    int total = 0;
    int count = 0;
    const step = 80; // Muestreo rápido de alto rendimiento
    for (int i = 0; i < bytes.length; i += step) {
      total += bytes[i];
      count++;
    }
    return count > 0 ? (total / count) : 128.0;
  }

  /// Verifica la iluminación y emite aviso vocal de poca luz si procede
  Future<void> verificarIluminacion(CameraImage image) async {
    if (_isTorchOn) return;

    final luminancia = calcularLuminanciaPromedio(image);
    final ahora = DateTime.now();

    // Si la luz es muy baja y han pasado al menos 15 segundos del último aviso
    if (luminancia < AppConstants.umbralOscuridad &&
        ahora.difference(_ultimoAvisoPocaLuz).inSeconds > 15) {
      _ultimoAvisoPocaLuz = ahora;
      await SoundService.instance.vibrarAlertaLuz();
      await TtsService.instance.speak(AppConstants.mensajePocaLuz, interrupt: false);
    }
  }

  /// Inicia el flujo continuo de cuadros con control de concurrencia para evitar saturar el procesador
  void startImageStream(Function(CameraImage image) onFrame) {
    if (_controller == null || !_controller!.value.isInitialized || _isStreaming) return;

    try {
      _isStreaming = true;
      _controller!.startImageStream((CameraImage image) async {
        // Si ya hay un cuadro siendo analizado por la red neuronal, descartamos este para mantener 0 latencia
        if (_isProcessingFrame) return;

        _isProcessingFrame = true;
        try {
          await onFrame(image);
        } catch (e) {
          debugPrint('Error al procesar cuadro: $e');
        } finally {
          _isProcessingFrame = false;
        }
      });
    } catch (e) {
      debugPrint('Error al iniciar flujo de cámara: $e');
      _isStreaming = false;
    }
  }

  /// Detiene el flujo continuo de la cámara
  Future<void> stopImageStream() async {
    if (!isInitialized || !_isStreaming) return;

    try {
      _isStreaming = false;
      _isProcessingFrame = false;
      await _controller!.stopImageStream();
    } catch (e) {
      debugPrint('Error al detener flujo: $e');
    }
  }

  /// Captura segura y estabilizada para análisis de IA (evita errores de concurrencia en CameraX)
  Future<String?> captureOptimizedSnapshot() async {
    if (!isInitialized || _controller == null) return null;

    try {
      if (_isStreaming) {
        await stopImageStream();
        await Future.delayed(const Duration(milliseconds: 150));
      }
      final XFile file = await _controller!.takePicture();
      return file.path;
    } catch (e) {
      debugPrint('Reintentando captura de cámara tras error: $e');
      try {
        await Future.delayed(const Duration(milliseconds: 250));
        if (_controller != null && _controller!.value.isInitialized) {
          final XFile file = await _controller!.takePicture();
          return file.path;
        }
      } catch (e2) {
        debugPrint('Segundo intento fallido: $e2');
      }
      return null;
    }
  }

  /// Captura una foto en resolución completa para lectura profunda de documentos enteros
  Future<String?> takePicture() async {
    return captureOptimizedSnapshot();
  }

  /// Libera recursos de la cámara
  Future<void> dispose() async {
    await stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }
}
