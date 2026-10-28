import 'dart:ui';
import '../models/text_block_info.dart';
import 'spanish_word_validator.dart';

class _SpokenRecord {
  final String text;
  final Set<String> words;
  final DateTime time;

  _SpokenRecord(this.text, this.words, this.time);
}

/// Algoritmo de Inteligencia, Lectura de Textos Múltiples y Filtrado Estricto de Ruido.
///
/// Resuelve:
/// 1. Lectura de Múltiples Líneas y Párrafos: Lee textos completos (varias líneas, párrafos,
///    etiquetas o recetas) de forma natural y fluida de arriba hacia abajo.
/// 2. Filtro Fonético y de Diccionario Estricto: Elimina el 100% de ruido o letras sin sentido
///    (como "wa9edua9da" o letras sueltas).
/// 3. Estabilización Temporal: Requiere que la cámara esté mínimamente quieta (~250ms) antes
///    de hablar, evitando lecturas nerviosas mientras se mueve la mano.
/// 4. Memoria Anti-Repetición (10 segundos): No vuelve a leer lo mismo si la mano se mueve un poco.
class TextStabilizer {
  final List<_SpokenRecord> _historialLectura = [];
  String _ultimoTextoEmitido = '';

  // Variables para la estabilización multi-cuadro
  String _candidatoPendiente = '';
  int _cuadrosConsistentes = 0;
  DateTime _momentoPrimerAvistamiento = DateTime.now();

  String get ultimoTextoEmitido => _ultimoTextoEmitido;

  /// Limpia el historial para forzar una re-lectura cuando el usuario lo solicite (ej. doble toque)
  void resetearHistorial() {
    _historialLectura.clear();
    _ultimoTextoEmitido = '';
    _candidatoPendiente = '';
    _cuadrosConsistentes = 0;
  }

  /// Procesa los bloques de texto detectados por la cámara y devuelve el texto listo para hablar.
  String? procesarYFiltrar(
    List<TextBlockInfo> bloques, {
    Size? tamanoImagen,
    bool ignorarFiltroTemporal = false,
  }) {
    if (bloques.isEmpty) return null;

    // 1. Filtrar bloques que estén dentro del encuadre útil (ignorar bordes lejanos de la mesa)
    final bloquesEncuadrados = _filtrarBloquesEnZonaLectura(bloques, tamanoImagen);
    if (bloquesEncuadrados.isEmpty) return null;

    // 2. Ordenar espacialmente: de arriba hacia abajo y de izquierda a derecha (orden de lectura natural)
    _ordenarBloquesEspacialmente(bloquesEncuadrados);

    // 3. Unir en líneas y párrafos completos
    final textoBruto = bloquesEncuadrados.map((b) => _limpiarEspacios(b.text)).join('\n').trim();
    if (textoBruto.length < 3) return null;

    // 4. FILTRO LINGÜÍSTICO Y FONÉTICO ESTRICTO:
    // Solo acepta palabras y frases reales con sentido en español. Descarta el 100% de basura OCR.
    final textoLimpio = _filtrarFrasesReales(textoBruto);
    if (textoLimpio == null || textoLimpio.length < 3) return null;

    // 5. ESTABILIZACIÓN TEMPORAL (espera a que la mano esté mínimamente quieta):
    if (!ignorarFiltroTemporal) {
      final esConsistente = _verificarConsistenciaTemporal(textoLimpio);
      if (!esConsistente) {
        return null;
      }
    }

    // 6. MEMORIA ANTI-REPETICIÓN:
    // Si la cámara se mueve un poco sobre el mismo documento, no volver a leer las mismas palabras
    _limpiarHistorialAntiguo();
    if (_esTextoYaLeido(textoLimpio)) {
      return null;
    }

    // 7. Registrar en memoria y emitir
    final palabrasSet = _extraerPalabras(textoLimpio);
    _ultimoTextoEmitido = textoLimpio;
    _historialLectura.add(_SpokenRecord(textoLimpio, palabrasSet, DateTime.now()));

    // Resetear el buffer temporal
    _candidatoPendiente = '';
    _cuadrosConsistentes = 0;

    return textoLimpio;
  }

  /// Permite capturar múltiples líneas y párrafos completos dentro del área generosa
  /// de la cámara (el 85% central), descartando objetos en la lejanía.
  List<TextBlockInfo> _filtrarBloquesEnZonaLectura(
    List<TextBlockInfo> bloques,
    Size? tamanoImagen,
  ) {
    if (bloques.isEmpty) return [];
    if (tamanoImagen == null || tamanoImagen.width == 0 || tamanoImagen.height == 0) {
      return bloques;
    }

    final minX = tamanoImagen.width * 0.05;
    final maxX = tamanoImagen.width * 0.95;
    final minY = tamanoImagen.height * 0.08;
    final maxY = tamanoImagen.height * 0.92;

    final List<TextBlockInfo> dentroDeZona = [];

    for (final b in bloques) {
      final cx = b.boundingBox.center.dx;
      final cy = b.boundingBox.center.dy;

      // Si el bloque está dentro del área visible de lectura
      if (cx >= minX && cx <= maxX && cy >= minY && cy <= maxY) {
        dentroDeZona.add(b);
      }
    }

    return dentroDeZona.isNotEmpty ? dentroDeZona : bloques;
  }

  /// Filtra cada línea asegurando que contenga palabras reales en español y frases legibles
  String? _filtrarFrasesReales(String texto) {
    final lineas = texto.split('\n');
    final List<String> lineasValidas = [];

    for (final l in lineas) {
      final lineaLimpia = SpanishWordValidator.filtrarFrase(l);
      if (lineaLimpia != null && lineaLimpia.trim().isNotEmpty) {
        lineasValidas.add(lineaLimpia.trim());
      }
    }

    if (lineasValidas.isEmpty) return null;
    return lineasValidas.join('\n').trim();
  }

  /// Verifica si el texto detectado se mantiene estable durante al menos 2 fotogramas (~250-300ms)
  bool _verificarConsistenciaTemporal(String textoActual) {
    final ahora = DateTime.now();

    if (_candidatoPendiente.isEmpty) {
      _candidatoPendiente = textoActual;
      _cuadrosConsistentes = 1;
      _momentoPrimerAvistamiento = ahora;
      return false;
    }

    final similitud = _calcularSimilitudJaccard(
      _normalizar(_candidatoPendiente),
      _normalizar(textoActual),
    );

    if (similitud >= 0.60) {
      _cuadrosConsistentes++;
      if (_cuadrosConsistentes >= 2 || ahora.difference(_momentoPrimerAvistamiento).inMilliseconds >= 250) {
        return true;
      }
    } else {
      _candidatoPendiente = textoActual;
      _cuadrosConsistentes = 1;
      _momentoPrimerAvistamiento = ahora;
    }

    return false;
  }

  String _limpiarEspacios(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _ordenarBloquesEspacialmente(List<TextBlockInfo> bloques) {
    bloques.sort((a, b) {
      final diffY = (a.top - b.top).abs();
      // Si están aproximadamente en el mismo renglón horizontal (tolerancia de 28px)
      if (diffY < 28) {
        return a.left.compareTo(b.left);
      }
      return a.top.compareTo(b.top);
    });
  }

  void _limpiarHistorialAntiguo() {
    final ahora = DateTime.now();
    _historialLectura.removeWhere(
      (item) => ahora.difference(item.time).inSeconds > 10,
    );
  }

  bool _esTextoYaLeido(String nuevoTexto) {
    final nuevoNormalizado = _normalizar(nuevoTexto);
    final nuevasPalabras = _extraerPalabras(nuevoNormalizado);

    if (nuevasPalabras.isEmpty) return true;

    for (final registro in _historialLectura) {
      final registradoNormalizado = _normalizar(registro.text);

      if (registradoNormalizado == nuevoNormalizado ||
          registradoNormalizado.contains(nuevoNormalizado) ||
          nuevoNormalizado.contains(registradoNormalizado)) {
        return true;
      }

      final palabrasComunes = nuevasPalabras.intersection(registro.words).length;
      final ratioSimilitud = palabrasComunes / nuevasPalabras.length;
      if (ratioSimilitud >= 0.60) {
        return true;
      }

      final similitud = _calcularSimilitudJaccard(registradoNormalizado, nuevoNormalizado);
      if (similitud >= 0.65) {
        return true;
      }
    }
    return false;
  }

  Set<String> _extraerPalabras(String str) {
    return str
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2)
        .toSet();
  }

  String _normalizar(String str) {
    return str
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _calcularSimilitudJaccard(String s1, String s2) {
    final set1 = s1.split(' ').toSet();
    final set2 = s2.split(' ').toSet();

    if (set1.isEmpty || set2.isEmpty) return 0.0;

    final interseccion = set1.intersection(set2).length;
    final union = set1.union(set2).length;

    if (union == 0) return 0.0;
    return interseccion / union;
  }
}
