import 'package:flutter/material.dart';
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TranslationPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
