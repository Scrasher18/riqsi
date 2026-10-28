import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/camera_service.dart';
import '../../core/audio/sound_service.dart';

/// Control segmentado de diseño contemporáneo para alternar entre 1.0x y 0.5x Gran Angular.
/// Combina alta estética visual con accesibilidad TalkBack WCAG AAA.
class ZoomSegmentedPill extends StatelessWidget {
  final ZoomMode currentMode;
  final ValueChanged<ZoomMode> onModeChanged;

  const ZoomSegmentedPill({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final is05x = currentMode == ZoomMode.zoom05x;

    return Semantics(
      button: true,
      label: is05x
          ? 'Cámara en 0.5x Gran Angular. Campo visual amplio. Toque para cambiar a 1.0x Estándar.'
          : 'Cámara en 1.0x Estándar. Enfoque normal. Toque para cambiar a 0.5x Gran Angular.',
      child: GestureDetector(
        onTap: () {
          SoundService.instance.vibrarCambioZoom();
          onModeChanged(is05x ? ZoomMode.zoom1x : ZoomMode.zoom05x);
        },
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: is05x ? AppConstants.colorAcento : AppConstants.colorTextoPrincipal,
              width: 2.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSegment(
                label: '0.5x',
                subLabel: 'AMPLIO',
                isSelected: is05x,
                activeColor: AppConstants.colorAcento,
              ),
              _buildSegment(
                label: '1.0x',
                subLabel: 'ESTÁNDAR',
                isSelected: !is05x,
                activeColor: AppConstants.colorTextoPrincipal,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegment({
    required String label,
    required String subLabel,
    required bool isSelected,
    required Color activeColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? activeColor : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 5),
            Text(
              subLabel,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
