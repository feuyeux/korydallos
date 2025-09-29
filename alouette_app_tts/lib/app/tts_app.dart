import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import 'app_router.dart';

/// TTS Application - Specialized text-to-speech functionality
/// 
/// Now uses the enhanced design token system with theme management
class TTSApp extends StatelessWidget {
  const TTSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alouette TTS',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const AppRouter(),
      debugShowCheckedModeBanner: false,
    );
  }
}