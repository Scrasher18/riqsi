import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/tts/tts_service.dart';
import 'accessible_button.dart';

/// Diálogo modal con narración por voz completa de todos los gestos y funciones.
class HelpDialog extends StatefulWidget {
  const HelpDialog({super.key});

  @override
  State<HelpDialog> createState() => _HelpDialogState();
}

class _HelpDialogState extends State<HelpDialog> {
  @override
  void initState() {
    super.initState();
    _reproducirTutorial();
  }

  Future<void> _reproducirTutorial() async {
    await TtsService.instance.speak(AppConstants.tutorialAyudaCompleto, interrupt: true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppConstants.colorAcento, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.help_outline, color: AppConstants.colorAcento, size: 36),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'GUÍA DE USO AUDITIVA',
                    style: TextStyle(
                      color: AppConstants.colorAcento,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 24, thickness: 2),
            const SizedBox(height: 8),
            const Text(
              'Escuche las instrucciones que se están reproduciendo en voz alta.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '• 1 Toque: Pausar / Reanudar\n'
              '• 2 Toques: Repetir último texto\n'
              '• Mantener presionado: Foto y lectura completa\n'
              '• Deslizar horizontal: Cambiar 1x y 0.5x Gran Angular\n'
              '• Deslizar vertical: Cambiar velocidad de voz\n'
              '• Botón Linterna: Encender / Apagar luz',
              style: TextStyle(
                color: AppConstants.colorTextoPrincipal,
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AccessibleButton(
                    label: 'Repetir Guía',
                    semanticHint: 'Vuelve a narrar las instrucciones',
                    icon: Icons.volume_up,
                    isActive: false,
                    onPressed: _reproducirTutorial,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AccessibleButton(
                    label: 'Entendido',
                    semanticHint: 'Cierra la ayuda y vuelve a la cámara',
                    icon: Icons.check,
                    isActive: true,
                    activeColor: AppConstants.colorExito,
                    textColor: Colors.black,
                    onPressed: () {
                      TtsService.instance.stop();
                      Navigator.of(context).pop();
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
