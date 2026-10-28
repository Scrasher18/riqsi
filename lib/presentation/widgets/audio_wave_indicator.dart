import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Indicador visual animado de onda de audio (Soundwave Equalizer).
/// Informa visualmente a personas videntes o con baja visión residual
/// cuándo la Inteligencia Artificial está vocalizando texto en tiempo real.
class AudioWaveIndicator extends StatefulWidget {
  final bool isSpeaking;
  final Color? color;

  const AudioWaveIndicator({
    super.key,
    required this.isSpeaking,
    this.color,
  });

  @override
  State<AudioWaveIndicator> createState() => _AudioWaveIndicatorState();
}

class _AudioWaveIndicatorState extends State<AudioWaveIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    if (widget.isSpeaking) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AudioWaveIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isSpeaking && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waveColor = widget.color ?? AppConstants.colorTextoPrincipal;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(4, (index) {
            final t = _controller.value;
            // Desfasar la altura de cada barra para simular un ecualizador natural
            final alturas = [
              widget.isSpeaking ? 6.0 + 14.0 * ((t + 0.2) % 1.0) : 4.0,
              widget.isSpeaking ? 8.0 + 18.0 * ((t + 0.5) % 1.0) : 4.0,
              widget.isSpeaking ? 6.0 + 16.0 * ((t + 0.8) % 1.0) : 4.0,
              widget.isSpeaking ? 5.0 + 12.0 * ((t + 0.3) % 1.0) : 4.0,
            ];

            return Container(
              width: 3.5,
              height: alturas[index],
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: widget.isSpeaking ? waveColor : Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }
}
