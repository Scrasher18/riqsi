import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Servicio de Síntesis de Voz (Text-To-Speech) 100% OFFLINE.
/// Utiliza el motor nativo de síntesis de voz de Android sin requerir internet.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  final ValueNotifier<bool> isSpeakingNotifier = ValueNotifier<bool>(false);
  
  // Velocidades de lectura accesibles: 0.45 (Lenta), 0.55 (Normal), 0.72 (Rápida), 0.90 (Ultra rápida)
  final List<double> _velocidades = [0.55, 0.75, 0.95, 0.45];
  final List<String> _nombresVelocidad = ['normal', 'rápida', 'ultra rápida', 'lenta'];
  int _indiceVelocidad = 0;

  bool get isSpeaking => _isSpeaking;
  String get velocidadActualNombre => _nombresVelocidad[_indiceVelocidad];
  double get velocidadActualValor => _velocidades[_indiceVelocidad];

  void _setSpeaking(bool speaking) {
    _isSpeaking = speaking;
    isSpeakingNotifier.value = speaking;
  }

  String _idiomaEspanol = 'es-ES';
  static const String _idiomaIngles = 'en-US';

  bool _detectarSiEsIngles(String texto) {
    // Si tiene tildes o eñes, es inequívocamente español
    if (RegExp(r'[áéíóúüñÁÉÍÓÚÜÑ]').hasMatch(texto)) return false;

    final palabras = texto.toLowerCase().split(RegExp(r'\s+'));
    int puntosIngles = 0;
    int puntosEspanol = 0;

    const marcadoresIngles = {
      'the', 'is', 'are', 'was', 'were', 'and', 'or', 'to', 'for', 'with', 'on', 'at',
      'exit', 'push', 'pull', 'open', 'closed', 'warning', 'caution', 'danger', 'keep',
      'out', 'reach', 'children', 'nutrition', 'facts', 'made', 'in', 'usa', 'ingredients',
      'store', 'cool', 'dry', 'place', 'daily', 'dosage', 'tablet', 'tablets', 'capsule',
      'free', 'sugar', 'water', 'coffee', 'tea', 'milk', 'bread', 'apple', 'welcome', 'thank', 'you'
    };

    const marcadoresEspanol = {
      'el', 'la', 'los', 'las', 'un', 'una', 'de', 'del', 'en', 'con', 'por', 'para',
      'sin', 'sobre', 'que', 'pero', 'mas', 'como', 'donde', 'cuando', 'salida', 'entrada',
      'abierto', 'cerrado', 'empuje', 'jale', 'cuidado', 'peligro', 'mantener', 'conservar',
      'lugar', 'fresco', 'dosis', 'diaria', 'comprimidos', 'jarabe', 'gracias'
    };

    for (final p in palabras) {
      final limpia = p.replaceAll(RegExp(r'[^\w]'), '');
      if (marcadoresIngles.contains(limpia)) puntosIngles++;
      if (marcadoresEspanol.contains(limpia)) puntosEspanol++;
    }

    return puntosIngles > puntosEspanol;
  }

  /// Inicializa el motor de voz con idioma español y configuraciones óptimas
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configurar idioma español por defecto
      final dynamic languages = await _flutterTts.getLanguages;
      _idiomaEspanol = 'es-ES';

      if (languages is List) {
        final List<String> langs = languages.map((e) => e.toString()).toList();
        if (langs.any((l) => l.startsWith('es_ES') || l.startsWith('es-ES'))) {
          _idiomaEspanol = 'es-ES';
        } else if (langs.any((l) => l.startsWith('es_US') || l.startsWith('es-US'))) {
          _idiomaEspanol = 'es-US';
        } else if (langs.any((l) => l.startsWith('es_MX') || l.startsWith('es-MX'))) {
          _idiomaEspanol = 'es-MX';
        } else if (langs.any((l) => l.startsWith('es'))) {
          _idiomaEspanol = langs.firstWhere((l) => l.startsWith('es'));
        }
      }

      await _flutterTts.setLanguage(_idiomaEspanol);
      await _flutterTts.setSpeechRate(_velocidades[_indiceVelocidad]);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _setSpeaking(true);
      });

      _flutterTts.setCompletionHandler(() {
        _setSpeaking(false);
      });

      _flutterTts.setCancelHandler(() {
        _setSpeaking(false);
      });

      _flutterTts.setErrorHandler((dynamic msg) {
        _setSpeaking(false);
        debugPrint('Error en TTS: $msg');
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error al inicializar TTS: $e');
    }
  }

  /// Lee un texto en voz alta con detección bilingüe automática (Español / Inglés).
  /// Si [interrupt] es true, detiene cualquier lectura previa antes de iniciar.
  Future<void> speak(String text, {bool interrupt = true}) async {
    if (text.trim().isEmpty) return;
    if (!_isInitialized) await initialize();

    try {
      if (interrupt) {
        await _flutterTts.stop();
      }

      // Conmutación automática de voz según el idioma predominante
      final esIngles = _detectarSiEsIngles(text);
      if (esIngles) {
        await _flutterTts.setLanguage(_idiomaIngles);
      } else {
        await _flutterTts.setLanguage(_idiomaEspanol);
      }

      _setSpeaking(true);
      await _flutterTts.speak(text);
    } catch (e) {
      _setSpeaking(false);
      debugPrint('Error al emitir voz: $e');
    }
  }

  /// Detiene inmediatamente cualquier lectura en curso
  Future<void> stop() async {
    try {
      _setSpeaking(false);
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('Error al detener TTS: $e');
    }
  }

  /// Alterna entre velocidades de lectura (Normal -> Rápida -> Ultra Rápida -> Lenta)
  Future<String> alternarVelocidad() async {
    _indiceVelocidad = (_indiceVelocidad + 1) % _velocidades.length;
    final nuevaVelocidad = _velocidades[_indiceVelocidad];
    final nombre = _nombresVelocidad[_indiceVelocidad];

    await _flutterTts.setSpeechRate(nuevaVelocidad);
    await speak('Velocidad de voz $nombre', interrupt: true);
    return nombre;
  }
}
