import '../models/text_block_info.dart';
import '../../core/constants/app_constants.dart';

/// Asistente Inteligente de Encuadre y Alineación de Documentos para Personas Ciegas.
///
/// Analiza las coordenadas espaciales del texto detectado respecto a las dimensiones
/// de la pantalla y genera recomendaciones de movimiento auditivas y hápticas.
class FramingGuidance {
  DateTime _ultimaRecomendacion = DateTime.now().subtract(const Duration(seconds: 10));
  String _ultimoMensaje = '';

  String? analizarEncuadre({
    required List<TextBlockInfo> bloques,
    required double vistaAncho,
    required double vistaAlto,
    bool forzar = false,
  }) {
    if (bloques.isEmpty) return null;

    final ahora = DateTime.now();
    // Limitar las sugerencias de voz a intervalos de al menos 7 segundos para no saturar al usuario
    if (!forzar && ahora.difference(_ultimaRecomendacion).inSeconds < 7) {
      return null;
    }

    // Calcular la envolvente total (Bounding Box) de todos los textos juntos
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final b in bloques) {
      if (b.left < minX) minX = b.left;
      if (b.top < minY) minY = b.top;
      if (b.right > maxX) maxX = b.right;
      if (b.bottom > maxY) maxY = b.bottom;
    }

    final anchoTexto = maxX - minX;
    final altoTexto = maxY - minY;
    final centroX = minX + (anchoTexto / 2);
    final centroY = minY + (altoTexto / 2);

    String? sugerencia;

    // 1. Verificar si el texto desborda la pantalla (muy cerca o cortado)
    if (anchoTexto > (vistaAncho * 0.90) || altoTexto > (vistaAlto * 0.90)) {
      sugerencia = AppConstants.guiaAlejarCelular;
    }
    // 2. Verificar desalineación vertical
    else if (centroY < (vistaAlto * 0.25)) {
      sugerencia = AppConstants.guiaMoverArriba;
    } else if (centroY > (vistaAlto * 0.75)) {
      sugerencia = AppConstants.guiaMoverAbajo;
    }
    // 3. Verificar desalineación horizontal
    else if (centroX < (vistaAncho * 0.20)) {
      sugerencia = AppConstants.guiaMoverIzquierda;
    } else if (centroX > (vistaAncho * 0.80)) {
      sugerencia = AppConstants.guiaMoverDerecha;
    } else {
      // Si está bien centrado
      sugerencia = null; // No molestar con voz si ya está centrado, salvo que se consulte
    }

    if (sugerencia != null && sugerencia != _ultimoMensaje) {
      _ultimaRecomendacion = ahora;
      _ultimoMensaje = sugerencia;
      return sugerencia;
    }

    return null;
  }
}
