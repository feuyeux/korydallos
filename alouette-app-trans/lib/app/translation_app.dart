import 'package:flutter/material.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';
import '../features/translation/pages/translation_home_page.dart';

class TranslationApp extends StatelessWidget {
  const TranslationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alouette Translator',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const TranslationHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}