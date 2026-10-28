import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/reading_history_item.dart';
import '../core/constants/app_constants.dart';

/// Servicio de almacenamiento local offline del historial de lecturas.
class HistoryService {
  HistoryService._();
  static final HistoryService instance = HistoryService._();

  static const String _keyHistory = 'lector_vision_history_v1';
  static const int _maxItems = 30;

  /// Guarda una lectura en el almacenamiento local persistente
  Future<void> guardarLectura(String text, ReadingMode mode) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || cleanText.length < 5) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final historial = await obtenerHistorial();

      // Evitar guardar duplicados idénticos consecutivos
      if (historial.isNotEmpty && historial.first.text == cleanText) {
        return;
      }

      final nuevo = ReadingHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: cleanText,
        timestamp: DateTime.now(),
        mode: mode,
      );

      historial.insert(0, nuevo);
      if (historial.length > _maxItems) {
        historial.removeLast();
      }

      final jsonList = historial.map((e) => e.toJson()).toList();
      await prefs.setStringList(_keyHistory, jsonList);
    } catch (_) {}
  }

  /// Recupera el historial ordenado desde el más reciente
  Future<List<ReadingHistoryItem>> obtenerHistorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_keyHistory);
      if (rawList == null || rawList.isEmpty) return [];

      return rawList.map((str) => ReadingHistoryItem.fromJson(str)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Elimina un elemento del historial por ID
  Future<void> eliminarLectura(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historial = await obtenerHistorial();
      historial.removeWhere((item) => item.id == id);
      final jsonList = historial.map((e) => e.toJson()).toList();
      await prefs.setStringList(_keyHistory, jsonList);
    } catch (_) {}
  }

  /// Limpia todo el historial
  Future<void> limpiarHistorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyHistory);
    } catch (_) {}
  }
}
