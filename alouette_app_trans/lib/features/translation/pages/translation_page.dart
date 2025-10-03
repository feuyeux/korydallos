import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import '../controllers/translation_controller.dart';

class TranslationPage extends StatefulWidget {
  final AppTranslationController controller;

  const TranslationPage({super.key, required this.controller});

  @override
  State<TranslationPage> createState() => _TranslationPageState();
}

class _TranslationPageState extends State<TranslationPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 1.0, 8.0, 0.5),
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, child) {
                return TranslationInputWidget(
                  textController: widget.controller.textController,
                  selectedLanguages: widget.controller.selectedLanguages,
                  onLanguagesChanged: widget.controller.updateSelectedLanguages,
                  onLanguageToggle: widget.controller.toggleLanguage,
                  onTranslate: _translateText,
                  isTranslating: widget.controller.isTranslating,
                  isConfigured: widget.controller.isConfigured,
                );
              },
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Card(
            margin: const EdgeInsets.fromLTRB(8.0, 0.5, 8.0, 1.0),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: TranslationResultWidget(
                translationService: widget.controller.translationService,
                isCompactMode: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _translateText() async {
    final error = await widget.controller.translateText();

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

  void _showConfigDialog() async {
    final result = await widget.controller.showConfigDialog(context);

    // The controller already handles saving the configuration
    // No need to call updateLLMConfig again
    if (result != null) {
      // Configuration was saved successfully
    }
  }
}
