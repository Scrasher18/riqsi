import 'dart:ui';

/// Modelo de datos que encapsula un bloque de texto reconocido y sus coordenadas espaciales.
class TextBlockInfo {
  final String text;
  final Rect boundingBox;
  final DateTime timestamp;

  TextBlockInfo({
    required this.text,
    required this.boundingBox,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  double get top => boundingBox.top;
  double get left => boundingBox.left;
  double get bottom => boundingBox.bottom;
  double get right => boundingBox.right;
}
