import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:lector_vision/core/constants/app_constants.dart';
import 'package:lector_vision/domain/models/text_block_info.dart';
import 'package:lector_vision/domain/text_filter/text_stabilizer.dart';
import 'package:lector_vision/domain/text_filter/framing_guidance.dart';
import 'package:lector_vision/domain/text_filter/spanish_word_validator.dart';

void main() {
  group('SpanishWordValidator - Filtro Estricto de Palabras Reales', () {
    test('Descarta basura OCR con números incrustados como wa9edua9da', () {
      expect(SpanishWordValidator.esPalabraValida('wa9edua9da'), isFalse);
      expect(SpanishWordValidator.esPalabraValida('k2_9dfa'), isFalse);
      expect(SpanishWordValidator.esPalabraValida('bcdfgh'), isFalse); // Sin vocales
      expect(SpanishWordValidator.esPalabraValida('zzzzzzz'), isFalse); // Caracteres repetidos
      expect(SpanishWordValidator.esPalabraValida('x'), isFalse); // Consonante suelta
      expect(SpanishWordValidator.esPalabraValida('b'), isFalse); // Consonante suelta
    });

    test('Acepta palabras reales, números y montos válidos', () {
      expect(SpanishWordValidator.esPalabraValida('Paracetamol'), isTrue);
      expect(SpanishWordValidator.esPalabraValida('Aspirina'), isTrue);
      expect(SpanishWordValidator.esPalabraValida('Total'), isTrue);
      expect(SpanishWordValidator.esPalabraValida('500'), isTrue);
      expect(SpanishWordValidator.esPalabraValida('500mg'), isTrue);
      expect(SpanishWordValidator.esPalabraValida('100ml'), isTrue);
      expect(SpanishWordValidator.esPalabraValida('\$45.50'), isTrue);
      expect(SpanishWordValidator.esPalabraValida('farmacia'), isTrue);
      expect(SpanishWordValidator.esPalabraValida('leche'), isTrue);
      expect(SpanishWordValidator.esPalabraValida('exit'), isTrue);
      expect(SpanishWordValidator.esPalabraValida('warning'), isTrue);
      expect(SpanishWordValidator.esPalabraValida('coffee'), isTrue);
    });

    test('Descarta frases completas si solo contienen ruido sin palabras reales', () {
      final filtrada = SpanishWordValidator.filtrarFrase('wa9edua9da k2_9dfa x zzz');
      expect(filtrada, isNull);
    });

    test('Acepta frases reales en español', () {
      final filtrada = SpanishWordValidator.filtrarFrase('Paracetamol 500 mg cada 8 horas');
      expect(filtrada, isNotNull);
      expect(filtrada!.contains('Paracetamol'), isTrue);
    });

    test('Acepta frases reales y letreros en inglés', () {
      final f1 = SpanishWordValidator.filtrarFrase('EMERGENCY EXIT ONLY');
      expect(f1, isNotNull);
      expect(f1!.contains('EXIT'), isTrue);

      final f2 = SpanishWordValidator.filtrarFrase('Warning keep out of reach of children');
      expect(f2, isNotNull);
      expect(f2!.contains('Warning'), isTrue);

      final f3 = SpanishWordValidator.filtrarFrase('Coffee shop open 24 hours');
      expect(f3, isNotNull);
      expect(f3!.contains('Coffee'), isTrue);
    });
  });

  group('TextStabilizer - Lectura de Múltiples Líneas y Párrafos', () {
    late TextStabilizer stabilizer;

    setUp(() {
      stabilizer = TextStabilizer();
    });

    test('Lee múltiples líneas y párrafos completos en orden natural', () {
      final bloques = [
        TextBlockInfo(
          text: 'Farmacia San Juan',
          boundingBox: const Rect.fromLTWH(10, 20, 200, 30),
        ),
        TextBlockInfo(
          text: 'Paracetamol 500 mg comprimidos',
          boundingBox: const Rect.fromLTWH(10, 60, 250, 30),
        ),
        TextBlockInfo(
          text: 'Tomar 1 cada 8 horas',
          boundingBox: const Rect.fromLTWH(10, 100, 200, 30),
        ),
      ];

      final resultado = stabilizer.procesarYFiltrar(
        bloques,
        ignorarFiltroTemporal: true,
      );
      expect(resultado, isNotNull);
      expect(resultado!.contains('Farmacia San Juan'), isTrue);
      expect(resultado.contains('Paracetamol 500 mg comprimidos'), isTrue);
      expect(resultado.contains('Tomar 1 cada 8 horas'), isTrue);
    });

    test('Anti-Jitter: No repite la lectura cuando la cámara se mueve un poco sobre el mismo texto', () {
      final bloques1 = [
        TextBlockInfo(
          text: 'Paracetamol 500 mg comprimidos',
          boundingBox: const Rect.fromLTWH(10, 60, 200, 30),
        ),
      ];

      // Cuadro 1: Lectura inicial
      final r1 = stabilizer.procesarYFiltrar(bloques1, ignorarFiltroTemporal: true);
      expect(r1, isNotNull);

      // Cuadro 2: Pequeño movimiento de la mano (mismas palabras)
      final bloques2 = [
        TextBlockInfo(
          text: 'Paracetamol 500 mg',
          boundingBox: const Rect.fromLTWH(12, 62, 180, 30),
        ),
      ];

      final r2 = stabilizer.procesarYFiltrar(bloques2, ignorarFiltroTemporal: true);
      // Debe ser suprimido silenciosamente para no aturdir al usuario
      expect(r2, isNull);
    });
  });

  group('FramingGuidance - Asistente de Encuadre y Alineación', () {
    late FramingGuidance guidance;

    setUp(() {
      guidance = FramingGuidance();
    });

    test('Detecta texto cortado o desbordando los límites de la pantalla', () {
      final bloques = [
        TextBlockInfo(
          text: 'Documento gigante desbordando',
          boundingBox: const Rect.fromLTWH(5, 5, 390, 780),
        ),
      ];

      final sugerencia = guidance.analizarEncuadre(
        bloques: bloques,
        vistaAncho: 400,
        vistaAlto: 800,
        forzar: true,
      );

      expect(sugerencia, equals(AppConstants.guiaAlejarCelular));
    });

    test('Detecta texto ubicado demasiado arriba en el visor', () {
      final bloques = [
        TextBlockInfo(
          text: 'Texto en el borde superior',
          boundingBox: const Rect.fromLTWH(50, 20, 200, 40),
        ),
      ];

      final sugerencia = guidance.analizarEncuadre(
        bloques: bloques,
        vistaAncho: 400,
        vistaAlto: 800,
        forzar: true,
      );

      expect(sugerencia, equals(AppConstants.guiaMoverArriba));
    });
  });
}
