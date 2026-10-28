import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/text_block_info.dart';

/// Visor HUD minimalista de alto contraste que enmarca el área de lectura
/// y dibuja sutiles recuadros sobre las palabras detectadas.
class FramingRadarOverlay extends StatelessWidget {
  final List<TextBlockInfo> bloques;
  final Size previewSize;
  final Size screenSize;

  const FramingRadarOverlay({
    super.key,
    required this.bloques,
    required this.previewSize,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: screenSize,
      painter: _RadarPainter(
        bloques: bloques,
        previewSize: previewSize,
        screenSize: screenSize,
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<TextBlockInfo> bloques;
  final Size previewSize;
  final Size screenSize;

  _RadarPainter({
    required this.bloques,
    required this.previewSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bloques.isEmpty || previewSize.width == 0 || previewSize.height == 0) return;

    final scaleX = size.width / previewSize.height;
    final scaleY = size.height / previewSize.width;

    final paintBox = Paint()
      ..color = AppConstants.colorAcento.withValues(alpha: 0.80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final paintFill = Paint()
      ..color = AppConstants.colorTextoPrincipal.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    for (final b in bloques) {
      final rect = Rect.fromLTRB(
        b.left * scaleX,
        b.top * scaleY,
        b.right * scaleX,
        b.bottom * scaleY,
      );

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      canvas.drawRRect(rrect, paintFill);
      canvas.drawRRect(rrect, paintBox);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => true;
}
