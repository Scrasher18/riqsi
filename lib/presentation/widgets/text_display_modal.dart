import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../core/tts/tts_service.dart';
import '../../core/audio/sound_service.dart';
import 'accessible_button.dart';
import 'glass_container.dart';
import 'audio_wave_indicator.dart';

/// Modal de lectura detallada con estética Glassmorphic contemporánea y ultra-alto contraste.
/// Diseñado bajo principios de diseño universal (WCAG AAA) para personas ciegas y con visión normal.
class TextDisplayModal extends StatelessWidget {
  final String text;
  final VoidCallback onClose;
  final bool isAiDescription;

  const TextDisplayModal({
    super.key,
    required this.text,
    required this.onClose,
    this.isAiDescription = false,
  });

  Future<void> _copiarTexto() async {
    await Clipboard.setData(ClipboardData(text: text));
    await SoundService.instance.vibrarExito();
    await TtsService.instance.speak(AppConstants.mensajeTextoCopiado, interrupt: true);
  }

  Future<void> _compartirTexto() async {
    await SoundService.instance.vibrarSeleccion();
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Texto leído con Riqsi',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palabras = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    final colorTema = isAiDescription
        ? AppConstants.colorAcento
        : AppConstants.colorTextoPrincipal;

    final iconoTema = isAiDescription
        ? Icons.auto_awesome
        : Icons.description_outlined;

    final tituloTema = isAiDescription
        ? 'Riqsi • LECTURA CON IA'
        : 'Riqsi • TEXTO COMPLETO';

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera Glassmorphic con título, conteo y ecualizador animado
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: 20,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              borderColor: colorTema.withValues(alpha: 0.6),
              borderWidth: 2.0,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorTema.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconoTema,
                      color: colorTema,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tituloTema,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          isAiDescription
                              ? '$palabras palabras transcritas con IA'
                              : '$palabras palabras detectadas',
                          style: TextStyle(
                            color: colorTema.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Ecualizador de audio animado si está hablando
                  ValueListenableBuilder<bool>(
                    valueListenable: TtsService.instance.isSpeakingNotifier,
                    builder: (context, isSpeaking, _) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AudioWaveIndicator(
                          isSpeaking: isSpeaking,
                          color: colorTema,
                        ),
                      );
                    },
                  ),
                  // Botón Cerrar accesible
                  Semantics(
                    button: true,
                    label: 'Cerrar reporte y volver a la cámara en vivo',
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () {
                        TtsService.instance.stop();
                        onClose();
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Contenedor de Texto Principal con efecto Frosted Glass
            Expanded(
              child: GlassContainer(
                padding: const EdgeInsets.all(18),
                borderRadius: 24,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                borderColor: AppConstants.colorTextoPrincipal.withValues(alpha: 0.35),
                child: Scrollbar(
                  thumbVisibility: true,
                  radius: const Radius.circular(8),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: SelectableText(
                      text,
                      style: const TextStyle(
                        color: AppConstants.colorTextoPrincipal,
                        fontSize: 24,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Botón Hero Principal: REPETIR LECTURA EN VOZ ALTA
            AccessibleButton(
              label: 'REPETIR LECTURA',
              semanticHint: 'Vuelve a leer el texto completo desde el principio',
              icon: Icons.replay,
              isActive: true,
              isHeroAction: true,
              onPressed: () {
                TtsService.instance.speak(text, interrupt: true);
              },
            ),

            const SizedBox(height: 10),

            // Fila de Controles Secundarios: Copiar, Compartir y Volver
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: AccessibleButton(
                    label: 'Copiar',
                    semanticHint: 'Copia el texto al portapapeles',
                    icon: Icons.copy,
                    isActive: false,
                    onPressed: _copiarTexto,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: AccessibleButton(
                    label: 'Compartir',
                    semanticHint: 'Comparte el texto mediante WhatsApp u otra aplicación',
                    icon: Icons.share,
                    isActive: false,
                    textColor: AppConstants.colorAcento,
                    onPressed: _compartirTexto,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: AccessibleButton(
                    label: 'Cámara',
                    semanticHint: 'Cierra el lector y regresa a la cámara en vivo',
                    icon: Icons.camera_alt,
                    isActive: true,
                    activeColor: Colors.white,
                    textColor: Colors.black,
                    onPressed: () {
                      TtsService.instance.stop();
                      onClose();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
