import 'package:flutter/material.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';
import 'translation_page.dart';

/// 应用主页面
class AppHomePage extends StatelessWidget {
  const AppHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(title: 'Alouette App', showLogo: true),
      body: const TranslationPage(),
    );
  }
}
