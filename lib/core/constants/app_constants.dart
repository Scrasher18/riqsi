import 'package:flutter/material.dart';

/// Modos de lectura especializados con IA
enum ReadingMode {
  general,
  medicamentos,
  preciosYFacturas,
}

/// Constantes globales de la aplicación Riqsi (Lector de Visión Accesible).
/// Diseñada con colores de ultra alto contraste (WCAG AAA) y textos accesibles para personas
/// con discapacidad visual o ceguera total.
class AppConstants {
  static const String nombreApp = 'Riqsi';

  // Paleta de colores de Ultra Alto Contraste (WCAG AAA Compliant)
  static const Color colorFondo = Color(0xFF000000); // Negro puro
  static const Color colorSuperficie = Color(0xFF121318); // Carbón profundo
  static const Color colorTextoPrincipal = Color(0xFFFFD700); // Amarillo brillante de máxima legibilidad
  static const Color colorTextoSecundario = Color(0xFFFFFFFF); // Blanco puro
  static const Color colorAcento = Color(0xFF00E5FF); // Cian eléctrico de alta visibilidad
  static const Color colorExito = Color(0xFF00E676); // Verde esmeralda vivo
  static const Color colorAlerta = Color(0xFFFF3D00); // Naranja/Rojo vivo para alertas
  static const Color colorBotonActivo = Color(0xFFFFD700); // Fondo botón activo
  static const Color colorBotonInactivo = Color(0xFF1E2028); // Fondo botón inactivo

  // Valores de zoom requeridos
  static const double zoomEstandar = 1.0;
  static const double zoomGranAngular = 0.5;

  // Umbral de similitud para filtro de duplicados (0.0 a 1.0)
  static const double umbralSimilitudDuplicado = 0.75;
  
  // Tiempo de enfriamiento en segundos para no repetir el mismo texto
  static const int tiempoEnfriamientoTextoSegundos = 6;

  // Umbral de luminancia promedio para detección de oscuridad (0 a 255)
  static const double umbralOscuridad = 50.0;

  // Configuración de Inteligencia Artificial (Opcional, la app funciona 100% On-Device sin conexión)
  static const String defaultGeminiApiKey = '';

  // Mensajes hablados por el sintetizador (TTS)
  static const String mensajeBienvenida = 
      'Bienvenido a Riqsi. Lector de texto accesible activado. '
      'Apunte la cámara a cualquier texto, empaque, botella o letrero en español o inglés para lectura inmediata. '
      'Toque la pantalla para enfocar la cámara en ese punto. '
      'Use el botón inferior para pausar la lectura.';

  static const String mensajeZoom05x = 
      'Cámara en cero punto cinco equis. Modo Gran Angular activado. '
      'Campo visual amplio para enfocar objetos grandes o cercanos.';

  static const String mensajeZoom1x = 
      'Cámara en una equis. Modo Estándar activado para texto regular.';

  static const String mensajePausa = 'Lectura en pausa.';
  static const String mensajeReanudar = 'Lectura reanudada.';
  static const String mensajeSinTexto = 'No se detecta texto en la imagen. Intente acercar o iluminar el documento.';
  static const String mensajeCapturando = 'Capturando imagen en alta resolución. Por favor espere.';
  static const String mensajeLinternaEncendida = 'Linterna encendida.';
  static const String mensajeLinternaApagada = 'Linterna apagada.';
  static const String mensajePocaLuz = 'Poca luz detectada. Se recomienda encender la linterna con el botón correspondiente.';
  static const String mensajeTextoCopiado = 'Texto copiado al portapapeles exitosamente.';
  static const String mensajeEnfoqueCentral = 'Modo Enfoque Central activado. Apunte hacia el texto específico que desea leer.';
  static const String mensajeEnfoqueTotal = 'Modo Vista Completa activado. Leyendo todo el texto visible.';
  
  // Mensajes de guía de encuadre
  static const String guiaMoverArriba = 'Mueva el celular hacia arriba.';
  static const String guiaMoverAbajo = 'Mueva el celular hacia abajo.';
  static const String guiaMoverIzquierda = 'Mueva el celular hacia la izquierda.';
  static const String guiaMoverDerecha = 'Mueva el celular hacia la derecha.';
  static const String guiaAlejarCelular = 'Texto muy cerca. Aleje un poco el celular o cambie a gran angular cero punto cinco.';
  static const String guiaEncuadreOptimo = 'Documento bien encuadrado.';

  static const String mensajePermisoCamara = 
      'Se requiere permiso de cámara para leer texto. Por favor autorícelo en la pantalla.';

  static const String tutorialAyudaCompleto =
      'Guía rápida de Lector Visión. '
      'Uno: Toque cualquier parte de la pantalla para pausar o reanudar la voz. '
      'Dos: Toque dos veces seguidas para repetir el último texto. '
      'Tres: Mantenga presionada la pantalla para tomar una foto en alta resolución y leer documentos enteros. '
      'Cuatro: Deslice su dedo hacia los lados para alternar entre cámara normal una equis y gran angular cero punto cinco equis. '
      'Cinco: Deslice verticalmente para cambiar la velocidad de lectura. '
      'Seis: Puede encender la linterna con el botón táctil de luz en la parte inferior.';
}
