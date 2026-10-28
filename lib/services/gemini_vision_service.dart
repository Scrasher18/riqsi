import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

/// Servicio de Inteligencia Artificial para Lectura Asistida (Google Gemini 3.5 Flash).
/// Especializado en transcribir y leer textos complejos, empaques de medicamentos,
/// recibos, letreros y notas manuscritas para personas ciegas y con baja visión.
class GeminiVisionService {
  GeminiVisionService._();
  static final GeminiVisionService instance = GeminiVisionService._();

  static const String _prefApiKey = 'gemini_api_key';
  
  /// Modelos con soporte multimodal y alta cuota en el plan gratuito de Google AI Studio.
  /// Si un modelo se satura o supera cuota temporal, rota automáticamente al siguiente.
  static const List<String> _modelosDisponibles = [
    'gemini-flash-lite-latest',
    'gemini-2.5-flash-lite',
    'gemini-flash-latest',
  ];

  String? _cachedApiKey;

  /// Optimiza y redimensiona la imagen a 720px para una subida ultrarrápida (reduce de 15MB a ~80KB)
  Future<Uint8List> _optimizarImagen(File archivo) async {
    final rawBytes = await archivo.readAsBytes();
    try {
      final codec = await ui.instantiateImageCodec(rawBytes, targetWidth: 720);
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    } catch (e) {
      debugPrint('No se pudo redimensionar imagen, usando original: $e');
    }
    return rawBytes;
  }

  /// Obtiene la clave de API configurada (desde SharedPreferences o AppConstants)
  Future<String?> getApiKey() async {
    if (_cachedApiKey != null && _cachedApiKey!.isNotEmpty) {
      return _cachedApiKey;
    }
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_prefApiKey);
    if (key != null && key.trim().isNotEmpty) {
      _cachedApiKey = key.trim();
      return _cachedApiKey;
    }
    if (AppConstants.defaultGeminiApiKey.isNotEmpty) {
      return AppConstants.defaultGeminiApiKey;
    }
    return null;
  }

  /// Guarda una nueva clave de API
  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    _cachedApiKey = apiKey.trim();
    await prefs.setString(_prefApiKey, _cachedApiKey!);
  }

  /// Elimina la clave de API guardada
  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedApiKey = null;
    await prefs.remove(_prefApiKey);
  }

  /// Verifica si el dispositivo tiene conexión activa a internet
  Future<bool> verificarConexionInternet() async {
    try {
      final resultado = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      return resultado.isNotEmpty && resultado[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Envía una fotografía a Gemini 3.5 Flash para transcribir y leer el texto
  Future<String> analizarImagen({
    required String rutaImagen,
    String? consultaUsuario,
    String? promptPersonalizado,
  }) async {
    // 1. Verificar conectividad a internet
    final hayInternet = await verificarConexionInternet();
    if (!hayInternet) {
      return 'No hay conexión a internet disponible. Puede usar el botón LEER TODO para leer sin conexión con el motor local.';
    }

    // 2. Obtener API Key
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return 'Para usar la lectura con Inteligencia Artificial, configure la clave de API en los ajustes.';
    }

    // 3. Leer y optimizar imagen (reduce tamaño para evitar timeouts)
    final archivo = File(rutaImagen);
    if (!await archivo.exists()) {
      return 'No se pudo acceder a la fotografía capturada.';
    }

    final Uint8List optimizados = await _optimizarImagen(archivo);
    final base64Image = base64Encode(optimizados);

    // 4. Prompt especializado en lectura para personas ciegas y con baja visión
    String promptSistema;
    if (promptPersonalizado != null && promptPersonalizado.isNotEmpty) {
      promptSistema = promptPersonalizado;
    } else if (consultaUsuario != null && consultaUsuario.trim().isNotEmpty) {
      promptSistema =
          'Eres un asistente de lectura para una persona con discapacidad visual. Responde de forma precisa y directa a la siguiente consulta sobre el texto de la imagen: "$consultaUsuario". Responde sin asteriscos ni formato markdown, lista para ser leída por un sintetizador de voz.';
    } else {
      promptSistema =
          'Eres un asistente de lectura especializado para personas con discapacidad visual y ceguera. '
          'Tu misión es transcribir y leer con absoluta fidelidad y claridad todo el texto visible en la fotografía '
          '(documentos, empaques de medicamentos, recibos, letreros, menús, pantallas o notas manuscritas).\n\n'
          'Sigue estrictamente estas instrucciones:\n'
          '1. Lee todo el texto en español de manera ordenada, natural y coherente, respetando títulos, párrafos y listas.\n'
          '2. Si es una caja o frasco de medicina, destaca claramente: Nombre del medicamento, Dosis y Fecha de caducidad si está visible.\n'
          '3. Si es un recibo o cuenta, destaca el Total a pagar y la Fecha.\n'
          '4. NO uses asteriscos (*), almohadillas (#), viñetas ni ningún formato markdown. La respuesta será leída directamente por un sintetizador de voz.\n'
          '5. Si en la imagen no se detecta ningún texto legible, responde únicamente: "No se detectó texto legible en la imagen. Intente enfocar más de cerca o encender la linterna."';
    }

    final cuerpoPeticion = {
      'contents': [
        {
          'parts': [
            {'text': promptSistema},
            {
              'inline_data': {
                'mime_type': 'image/png',
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 600,
      }
    };

    String ultimoError = '';

    for (final modelo in _modelosDisponibles) {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$modelo:generateContent?key=$apiKey');

      try {
        final respuesta = await http
            .post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': apiKey,
              },
              body: jsonEncode(cuerpoPeticion),
            )
            .timeout(const Duration(seconds: 20));

        if (respuesta.statusCode == 200) {
          final data = jsonDecode(respuesta.body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              String texto = parts[0]['text'] as String? ?? '';
              // Limpiar posibles asteriscos, almohadillas o formato markdown
              texto = texto
                  .replaceAll('*', '')
                  .replaceAll('#', '')
                  .replaceAll('`', '')
                  .replaceAll('_', '')
                  .trim();
              if (texto.isNotEmpty) {
                return texto;
              }
            }
          }
          return 'No se pudo transcribir el texto de la imagen.';
        } else if (respuesta.statusCode == 429) {
          debugPrint('Cuota de $modelo alcanzada (429), probando siguiente modelo...');
          ultimoError = 'Límite diario de consultas de Inteligencia Artificial alcanzado. Puede continuar usando el botón LEER TODO para leer sin límites y sin conexión.';
          continue;
        } else if (respuesta.statusCode == 503) {
          debugPrint('Modelo $modelo con alta demanda (503), probando siguiente modelo...');
          ultimoError = 'El servidor de Inteligencia Artificial tiene alta demanda en este momento. Puede usar LEER TODO sin conexión.';
          continue;
        } else if (respuesta.statusCode == 400 || respuesta.statusCode == 403) {
          debugPrint('Error de autenticación Gemini en $modelo: ${respuesta.body}');
          return 'Clave de API de Gemini no autorizada. Revise la clave configurada.';
        } else {
          debugPrint('Error en Gemini API ($modelo - ${respuesta.statusCode}): ${respuesta.body}');
          continue;
        }
      } on TimeoutException catch (_) {
        debugPrint('Timeout al consultar modelo $modelo, probando siguiente...');
        ultimoError = 'El análisis tardó demasiado. Puede usar el botón LEER TODO para lectura instantánea sin conexión.';
        continue;
      } on SocketException catch (_) {
        return 'Se perdió la conexión a internet durante la lectura con Inteligencia Artificial.';
      } catch (e) {
        debugPrint('Excepción en GeminiVisionService ($modelo): $e');
        continue;
      }
    }

    return ultimoError.isNotEmpty
        ? ultimoError
        : 'Hubo una dificultad en el servidor de Inteligencia Artificial. Puede usar el botón LEER TODO para leer sin conexión.';
  }

  /// Transcribe y lee texto complejo con IA (medicamentos, recibos, recetas manuscritas)
  Future<String> transcribirYLeerTextoConIA({required String rutaImagen}) async {
    return analizarImagen(
      rutaImagen: rutaImagen,
    );
  }
}
