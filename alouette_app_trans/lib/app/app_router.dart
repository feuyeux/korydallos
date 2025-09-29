import 'package:flutter/material.dart';
import '../features/translation/pages/translation_home_page.dart';

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return const TranslationHomePage();
  }
}