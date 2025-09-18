import 'package:flutter/material.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';
import '../features/tts/pages/tts_home_page.dart';

/// TTS Application - Specialized text-to-speech functionality
/// 
/// Now uses the enhanced design token system with theme management
class TTSApp extends StatefulWidget {
  const TTSApp({super.key});

  @override
  State<TTSApp> createState() => _TTSAppState();
}

class _TTSAppState extends State<TTSApp> {
  late final ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    _themeService = ThemeService();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeService,
      builder: (context, child) {
        return MaterialApp(
          title: 'Alouette TTS',
          theme: _themeService.getLightTheme(),
          darkTheme: _themeService.getDarkTheme(),
          themeMode: _getThemeMode(),
          home: const TTSHomePage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }

  ThemeMode _getThemeMode() {
    switch (_themeService.themeMode) {
      case AlouetteThemeMode.light:
        return ThemeMode.light;
      case AlouetteThemeMode.dark:
        return ThemeMode.dark;
      case AlouetteThemeMode.system:
        return ThemeMode.system;
    }
  }
}