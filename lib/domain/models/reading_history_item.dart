import 'dart:convert';
import '../../core/constants/app_constants.dart';

/// Modelo de datos para almacenar el historial de lecturas recientes en almacenamiento local.
class ReadingHistoryItem {
  final String id;
  final String text;
  final DateTime timestamp;
  final ReadingMode mode;

  ReadingHistoryItem({
    required this.id,
    required this.text,
    required this.timestamp,
    this.mode = ReadingMode.general,
  });

  int get wordCount => text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'mode': mode.index,
    };
  }

  factory ReadingHistoryItem.fromMap(Map<String, dynamic> map) {
    return ReadingHistoryItem(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      mode: ReadingMode.values[(map['mode'] ?? 0).clamp(0, ReadingMode.values.length - 1)],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ReadingHistoryItem.fromJson(String source) =>
      ReadingHistoryItem.fromMap(jsonDecode(source));
}
