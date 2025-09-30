import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import 'app_router.dart';

class TranslationApp extends StatelessWidget {
  const TranslationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alouette Translator',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const AppRouter(),
      debugShowCheckedModeBanner: false,
    );
  }
}
