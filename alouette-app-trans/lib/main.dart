import 'package:flutter/material.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';
import 'pages/translation_page.dart';

void main() {
  runApp(const AlouetteTranslatorApp());
}

class AlouetteTranslatorApp extends StatelessWidget {
  const AlouetteTranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alouette Translator',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const TranslationPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
