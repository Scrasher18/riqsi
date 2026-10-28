import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_constants.dart';
import 'presentation/screens/reader_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bloquear orientación en vertical para facilitar el uso con una sola mano por personas ciegas
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Configurar barra de estado de ultra alto contraste
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const LectorVisionApp());
}

/// Aplicación principal Riqsi configurada con temas y directrices de accesibilidad (WCAG AAA)
class LectorVisionApp extends StatelessWidget {
  const LectorVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.nombreApp,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppConstants.colorFondo,
        primaryColor: AppConstants.colorTextoPrincipal,
        colorScheme: const ColorScheme.dark(
          primary: AppConstants.colorTextoPrincipal,
          secondary: AppConstants.colorAcento,
          surface: Colors.black,
          error: AppConstants.colorAlerta,
        ),
        fontFamily: 'sans-serif',
      ),
      home: const ReaderScreen(),
    );
  }
}
