import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/tts/tts_service.dart';
import '../../core/audio/sound_service.dart';
import '../../services/gemini_vision_service.dart';
import 'accessible_button.dart';
import 'glass_container.dart';

/// Diálogo accesible de alta gama para configurar la clave de API de Google Gemini.
class GeminiApiKeyDialog extends StatefulWidget {
  const GeminiApiKeyDialog({super.key});

  @override
  State<GeminiApiKeyDialog> createState() => _GeminiApiKeyDialogState();
}

class _GeminiApiKeyDialogState extends State<GeminiApiKeyDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isSaving = false;
  String? _currentKey;

  @override
  void initState() {
    super.initState();
    _cargarClaveActual();
  }

  Future<void> _cargarClaveActual() async {
    final key = await GeminiVisionService.instance.getApiKey();
    if (mounted) {
      setState(() {
        _currentKey = key;
        if (key != null) {
          _controller.text = key;
        }
      });
    }
  }

  Future<void> _pegarDelPortapapeles() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      setState(() {
        _controller.text = data.text!.trim();
      });
      await SoundService.instance.vibrarExito();
      await TtsService.instance.speak('Clave pegada del portapapeles', interrupt: true);
    } else {
      await TtsService.instance.speak('El portapapeles está vacío', interrupt: true);
    }
  }

  Future<void> _guardarClave() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      await TtsService.instance.speak('Por favor ingrese una clave de API', interrupt: true);
      return;
    }

    setState(() => _isSaving = true);
    await GeminiVisionService.instance.saveApiKey(key);
    await SoundService.instance.vibrarExito();
    await TtsService.instance.speak('Clave de Gemini guardada correctamente', interrupt: true);

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _eliminarClave() async {
    await GeminiVisionService.instance.clearApiKey();
    setState(() {
      _controller.clear();
      _currentKey = null;
    });
    await SoundService.instance.vibrarSeleccion();
    await TtsService.instance.speak('Clave de API eliminada', interrupt: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        backgroundColor: Colors.black.withValues(alpha: 0.94),
        borderColor: AppConstants.colorAcento,
        borderWidth: 2.0,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.colorAcento.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppConstants.colorAcento,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'IA VISUAL GEMINI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Text(
                'Permite a la aplicación describir qué hay frente a la cámara (dinero, objetos, colores, personas y entorno) usando Google Gemini.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Campo de texto accesible
              Semantics(
                label: 'Campo de texto para clave de API de Gemini',
                hint: 'Pegue o escriba aquí su clave de Google AI Studio',
                child: TextField(
                  controller: _controller,
                  obscureText: true,
                  style: const TextStyle(
                    color: AppConstants.colorTextoPrincipal,
                    fontSize: 16,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    labelText: 'Clave de API de Gemini',
                    labelStyle: const TextStyle(color: AppConstants.colorAcento),
                    hintText: 'AIzaSy...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppConstants.colorTextoPrincipal, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppConstants.colorTextoPrincipal, width: 2.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Botón Pegar Portapapeles
              AccessibleButton(
                label: 'Pegar del Portapapeles',
                semanticHint: 'Pega la clave copiada previamente',
                icon: Icons.paste,
                isActive: false,
                textColor: AppConstants.colorAcento,
                onPressed: _pegarDelPortapapeles,
              ),
              const SizedBox(height: 12),

              // Botón Guardar
              AccessibleButton(
                label: _isSaving ? 'Guardando...' : 'GUARDAR CLAVE',
                semanticHint: 'Guarda la clave de API para usar la IA en la aplicación',
                icon: Icons.check,
                isActive: true,
                isHeroAction: true,
                onPressed: _guardarClave,
              ),

              if (_currentKey != null && _currentKey!.isNotEmpty) ...[
                const SizedBox(height: 10),
                AccessibleButton(
                  label: 'Eliminar Clave',
                  semanticHint: 'Borra la clave de API guardada',
                  icon: Icons.delete_outline,
                  isActive: false,
                  textColor: AppConstants.colorAlerta,
                  onPressed: _eliminarClave,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
