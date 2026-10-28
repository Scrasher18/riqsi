import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../core/tts/tts_service.dart';
import '../../core/audio/sound_service.dart';
import '../../domain/models/reading_history_item.dart';
import '../../services/history_service.dart';
import '../widgets/accessible_button.dart';

/// Pantalla accesible de historial de lecturas recientes guardadas localmente sin internet.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService.instance;
  final TtsService _ttsService = TtsService.instance;
  List<ReadingHistoryItem> _historial = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    final items = await _historyService.obtenerHistorial();
    setState(() {
      _historial = items;
      _isLoading = false;
    });

    final msg = items.isEmpty
        ? 'Historial vacío. Aún no hay lecturas guardadas.'
        : 'Historial de lecturas. Hay ${items.length} lecturas guardadas. Toque cualquier elemento para escucharlo.';
    await _ttsService.speak(msg, interrupt: true);
  }

  Future<void> _eliminarItem(String id) async {
    await _historyService.eliminarLectura(id);
    await SoundService.instance.vibrarSeleccion();
    await _cargarHistorial();
  }

  Future<void> _limpiarTodo() async {
    await _historyService.limpiarHistorial();
    await SoundService.instance.vibrarExito();
    await _ttsService.speak('Historial borrado completamente.', interrupt: true);
    await _cargarHistorial();
  }

  Future<void> _copiarTexto(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    await SoundService.instance.vibrarExito();
    await _ttsService.speak(AppConstants.mensajeTextoCopiado, interrupt: true);
  }

  Future<void> _compartirTexto(String text) async {
    await SoundService.instance.vibrarSeleccion();
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Lectura guardada en Lector Visión',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'HISTORIAL DE LECTURAS',
          style: TextStyle(
            color: AppConstants.colorAcento,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
          onPressed: () {
            _ttsService.stop();
            Navigator.of(context).pop();
          },
          tooltip: 'Volver a la cámara principal',
        ),
        actions: [
          if (_historial.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: AppConstants.colorAlerta, size: 32),
              onPressed: _limpiarTodo,
              tooltip: 'Borrar todo el historial',
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppConstants.colorTextoPrincipal),
              )
            : _historial.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history, color: Colors.white38, size: 80),
                          const SizedBox(height: 16),
                          const Text(
                            'NO HAY LECTURAS EN EL HISTORIAL',
                            style: TextStyle(
                              color: AppConstants.colorTextoPrincipal,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Cada vez que capture o lea un texto, se guardará automáticamente aquí.',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          AccessibleButton(
                            label: 'Volver a Escanear',
                            semanticHint: 'Regresa a la cámara',
                            icon: Icons.camera_alt,
                            isActive: true,
                            activeColor: AppConstants.colorAcento,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _historial.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = _historial[index];
                      final fechaStr =
                          '${item.timestamp.day}/${item.timestamp.month} ${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppConstants.colorSuperficie,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppConstants.colorTextoPrincipal, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  fechaStr,
                                  style: const TextStyle(
                                    color: AppConstants.colorAcento,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${item.wordCount} palabras',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item.text,
                              style: const TextStyle(
                                color: AppConstants.colorTextoPrincipal,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1.35,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: AccessibleButton(
                                    label: 'Escuchar',
                                    semanticHint: 'Lee este texto guardado en voz alta',
                                    icon: Icons.volume_up,
                                    isActive: true,
                                    activeColor: AppConstants.colorTextoPrincipal,
                                    onPressed: () {
                                      _ttsService.speak(item.text, interrupt: true);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.copy, color: Colors.white, size: 28),
                                  onPressed: () => _copiarTexto(item.text),
                                  tooltip: 'Copiar texto',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share, color: AppConstants.colorAcento, size: 28),
                                  onPressed: () => _compartirTexto(item.text),
                                  tooltip: 'Compartir texto',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: AppConstants.colorAlerta, size: 28),
                                  onPressed: () => _eliminarItem(item.id),
                                  tooltip: 'Eliminar este elemento',
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
