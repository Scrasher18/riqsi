import 'package:flutter/services.dart';

/// Servicio de retroalimentación háptica (vibración) y sonora para personas con discapacidad visual.
/// Permite al usuario "sentir" las acciones de la cámara y los eventos de lectura sin depender de la vista.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  /// Vibración suave para indicar que se detectó texto en el encuadre
  Future<void> vibrarTextoDetectado() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Vibración media para confirmar cambio de modo de zoom (1x / 0.5x)
  Future<void> vibrarCambioZoom() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Vibración fuerte para confirmar captura de foto / lectura profunda
  Future<void> vibrarCapturaFoto() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Doble vibración para pausar o reanudar
  Future<void> vibrarPausaReanudar() async {
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }

  /// Vibración de selección rápida para cambio de linterna o velocidad
  Future<void> vibrarSeleccion() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Vibración para confirmar encuadre óptimo del documento
  Future<void> vibrarEncuadreCorrecto() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Vibración de éxito al copiar texto o guardar
  Future<void> vibrarExito() async {
    try {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Vibración de alerta cuando hay poca iluminación
  Future<void> vibrarAlertaLuz() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Vibración urgente cuando la IA detecta DETÉNGASE o un obstáculo peligroso
  Future<void> vibrarAlertaObstaculo() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 120));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 120));
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Vibración positiva de camino despejado
  Future<void> vibrarCaminoDespejado() async {
    try {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }
}
