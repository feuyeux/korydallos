import 'package:flutter/material.dart';
// Import specific components instead of the entire alouette_ui_shared package
import 'package:alouette_ui_shared/src/themes/app_theme.dart';
import 'presentation/pages/translation_page.dart';

void main() {
  runApp(const AlouetteAppTrans());
}

class AlouetteAppTrans extends StatelessWidget {
  const AlouetteAppTrans({super.key});

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
