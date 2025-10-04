import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';

class TranslationApp extends StatelessWidget {
  const TranslationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alouette Trans',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const _TranslationHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _TranslationHomeScreen extends StatelessWidget {
  const _TranslationHomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Alouette Trans',
        showLogo: true,
        statusWidget: const TranslationStatusWidget(),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => _openConfigDialog(context),
          ),
        ],
      ),
      body: const TranslationPageView(),
    );
  }

  Future<void> _openConfigDialog(BuildContext context) async {
    final result = await showTranslationConfigDialog(context);
    if (result != null && context.mounted) {
      context.showSuccessMessage('Configuration updated successfully');
    }
  }
}
