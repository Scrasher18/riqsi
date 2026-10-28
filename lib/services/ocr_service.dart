import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../domain/models/text_block_info.dart';

/// Servicio de Reconocimiento Óptico de Caracteres (OCR) 100% OFFLINE.
/// Ejecuta el modelo de Red Neuronal On-Device de Google ML Kit para el script Latino.
/// No realiza ninguna petición a internet ni consume datos móviles.
class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  TextRecognizer? _textRecognizer;
  bool _isDisposed = false;

  /// Inicializa el reconocedor con soporte para español y caracteres latinos
  void initialize() {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    _isDisposed = false;
  }

  /// Procesa un cuadro de la cámara en tiempo real
  Future<List<TextBlockInfo>> procesarCuadroCamara({
    required CameraImage cameraImage,
    required CameraDescription cameraDescription,
  }) async {
    if (_isDisposed) return [];
    initialize();

    final inputImage = _convertirCameraImageAInputImage(
      cameraImage: cameraImage,
      cameraDescription: cameraDescription,
    );

    if (inputImage == null) return [];

    try {
      final RecognizedText recognizedText = await _textRecognizer!.processImage(inputImage);
      return _extraerBloques(recognizedText);
    } catch (e) {
      debugPrint('Error en OCR en vivo: $e');
      return [];
    }
  }

  /// Procesa una imagen estática en alta resolución (para capturas de documentos completos)
  Future<List<TextBlockInfo>> procesarArchivoImagen(String filePath) async {
    if (_isDisposed) return [];
    initialize();

    final file = File(filePath);
    if (!file.existsSync()) return [];

    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final RecognizedText recognizedText = await _textRecognizer!.processImage(inputImage);
      return _extraerBloques(recognizedText);
    } catch (e) {
      debugPrint('Error en OCR de alta resolución: $e');
      return [];
    }
  }

  /// Convierte el resultado de ML Kit a nuestra lista de [TextBlockInfo] a nivel de línea.
  /// Extraer a nivel de línea permite leer con máxima fidelidad tanto superficies planas
  /// (documentos, libros, recibos) como superficies curvas o 3D (botellas, frascos de medicina, latas, cajas y empaques).
  List<TextBlockInfo> _extraerBloques(RecognizedText recognizedText) {
    final List<TextBlockInfo> resultado = [];

    for (final textBlock in recognizedText.blocks) {
      if (textBlock.lines.isNotEmpty) {
        for (final line in textBlock.lines) {
          final lineText = line.text.trim();
          if (lineText.isNotEmpty) {
            resultado.add(
              TextBlockInfo(
                text: lineText,
                boundingBox: line.boundingBox,
              ),
            );
          }
        }
      } else {
        final text = textBlock.text.trim();
        if (text.isNotEmpty) {
          resultado.add(
            TextBlockInfo(
              text: text,
              boundingBox: textBlock.boundingBox,
            ),
          );
        }
      }
    }

    return resultado;
  }

  /// Convierte los bytes nativos de [CameraImage] de Android al formato [InputImage] de ML Kit
  InputImage? _convertirCameraImageAInputImage({
    required CameraImage cameraImage,
    required CameraDescription cameraDescription,
  }) {
    final sensorOrientation = cameraDescription.sensorOrientation;
    final rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(cameraImage.format.raw);
    if (format == null) return null;

    if (cameraImage.planes.isEmpty) return null;

    // Concatenar los planos de bytes (YUV_420_888 o NV21 nativo en Android)
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in cameraImage.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: cameraImage.planes.first.bytesPerRow,
      ),
    );
  }

  /// Libera los recursos nativos del reconocedor
  void dispose() {
    _isDisposed = true;
    _textRecognizer?.close();
    _textRecognizer = null;
  }
}
