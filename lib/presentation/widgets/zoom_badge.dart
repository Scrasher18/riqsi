import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/camera_service.dart';

/// Distintivo de alto contraste que indica visiblemente el modo de zoom actual (1x o 0.5x).
class ZoomBadge extends StatelessWidget {
  final ZoomMode mode;
  final double appliedZoom;
  final VoidCallback onTap;

  const ZoomBadge({
    super.key,
    required this.mode,
    required this.appliedZoom,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final esGranAngular = mode == ZoomMode.zoom05x;
    final textoPrincipal = esGranAngular ? '0.5x' : '1.0x';
    final descripcion = esGranAngular ? 'GRAN ANGULAR' : 'ESTÁNDAR';
    final colorBorde = esGranAngular ? AppConstants.colorAcento : AppConstants.colorTextoPrincipal;

    return Semantics(
      button: true,
      label: 'Modo de cámara actual: $descripcion, aumento $textoPrincipal. Toque para cambiar.',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorBorde, width: 2.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                esGranAngular ? Icons.zoom_out_map : Icons.center_focus_strong,
                color: colorBorde,
                size: 24,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    textoPrincipal,
                    style: TextStyle(
                      color: colorBorde,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    descripcion,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
