import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import '../controllers/translation_controller.dart';
import 'translation_settings_page.dart';

class TranslationHomePage extends StatefulWidget {
  const TranslationHomePage({super.key});

  @override
  State<TranslationHomePage> createState() => _TranslationHomePageState();
}

class _TranslationHomePageState extends State<TranslationHomePage> {
  late AppTranslationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppTranslationController();
    _controller.addListener(_onControllerChanged);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Alouette Translator',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsPage,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Configuration status indicator
            ConfigStatusWidget(
              isAutoConfiguring: _controller.isAutoConfiguring,
              isConfigured: _controller.isConfigured,
              autoConfigStatus: _controller.autoConfigStatus,
              llmConfig: _controller.llmConfig,
              onConfigurePressed: _showConfigDialog,
            ),
            const SizedBox(height: 8),

            // Translation input area
            Expanded(
              flex: 4,
              child: TranslationInputWidget(
                textController: _controller.textController,
                selectedLanguages: _controller.selectedLanguages,
                onLanguagesChanged: _controller.updateSelectedLanguages,
                onLanguageToggle: _controller.toggleLanguage,
                onTranslate: _translateText,
                isTranslating: _controller.isTranslating,
                isConfigured: _controller.isConfigured,
              ),
            ),

            const SizedBox(height: 12),

            // Translation result area
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TranslationResultWidget(
                    translationService: _controller.translationService,
                    isCompactMode: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TranslationSettingsPage(
          controller: _controller,
        ),
      ),
    );
  }

  void _showConfigDialog() async {
    final result = await _controller.showConfigDialog(context);

    if (result != null) {
      _controller.updateLLMConfig(result);
    }
  }

  void _translateText() async {
    final error = await _controller.translateText();

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 4),
        ),
      );

      // Show config dialog if not configured
      if (error.contains('configure LLM settings')) {
        _showConfigDialog();
      }
    }
  }
}