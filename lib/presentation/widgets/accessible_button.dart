import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/audio/sound_service.dart';

/// Botón táctil ergonómico de alta gama con soporte universal (Videntes y No Videntes).
/// Cuenta con micro-interacciones táctiles, alto contraste (WCAG AAA) y soporte completo TalkBack.
class AccessibleButton extends StatefulWidget {
  final String label;
  final String semanticHint;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;
  final Color? activeColor;
  final Color? textColor;
  final bool isHeroAction;

  const AccessibleButton({
    super.key,
    required this.label,
    required this.semanticHint,
    required this.icon,
    required this.onPressed,
    this.isActive = false,
    this.activeColor,
    this.textColor,
    this.isHeroAction = false,
  });

  @override
  State<AccessibleButton> createState() => _AccessibleButtonState();
}

class _AccessibleButtonState extends State<AccessibleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final fondo = widget.isActive
        ? (widget.activeColor ?? AppConstants.colorBotonActivo)
        : AppConstants.colorBotonInactivo;

    final colorTexto = widget.isActive
        ? Colors.black
        : (widget.textColor ?? AppConstants.colorTextoPrincipal);

    return Semantics(
      button: true,
      label: widget.label,
      hint: widget.semanticHint,
      enabled: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          SoundService.instance.vibrarSeleccion();
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeInOut,
          child: Container(
            constraints: const BoxConstraints(minHeight: 62),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: BorderRadius.circular(20),
              gradient: widget.isHeroAction
                  ? const LinearGradient(
                      colors: [Color(0xFFFFB300), Color(0xFFFFD600)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              border: Border.all(
                color: widget.isActive
                    ? Colors.white
                    : (widget.textColor ?? AppConstants.colorTextoPrincipal),
                width: widget.isHeroAction ? 3.0 : 2.0,
              ),
              boxShadow: widget.isHeroAction
                  ? [
                      BoxShadow(
                        color: AppConstants.colorTextoPrincipal.withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: widget.isHeroAction ? 30 : 26,
                  color: widget.isHeroAction ? Colors.black : colorTexto,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.isHeroAction ? Colors.black : colorTexto,
                      fontSize: widget.isHeroAction ? 17 : 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
