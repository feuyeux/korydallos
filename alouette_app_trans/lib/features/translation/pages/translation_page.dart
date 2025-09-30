import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';

class TranslationPage extends StatefulWidget {
  final ITranslationController controller;
  final ISelectionController<String> languageController;

  const TranslationPage({
    super.key,
    required this.controller,
    required this.languageController,
  });

  @override
  State<TranslationPage> createState() => _TranslationPageState();
}

class _TranslationPageState extends State<TranslationPage> {
  final TextEditingController _textController = TextEditingController();
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

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
            child: StreamBuilder<bool>(
              stream: widget.controller.loadingStream,
              builder: (context, loadingSnapshot) {
                final isTranslating = loadingSnapshot.data ?? false;
                return StreamBuilder<List<String>>(
                  stream: widget.languageController.selectionStream,
                  builder: (context, selectionSnapshot) {
                    final selectedLanguages = selectionSnapshot.data ?? [];
                    return TranslationInputWidget(
                      textController: _textController,
                      selectedLanguages: selectedLanguages,
                      onLanguagesChanged: (languages) {
                        widget.languageController.selectMultiple(languages);
                      },
                      onLanguageToggle: (language, selected) {
                        if (selected) {
                          widget.languageController.select(language);
                        } else {
                          widget.languageController.deselect(language);
                        }
                      },
                      onTranslate: _translateText,
                      isTranslating: isTranslating,
                      isConfigured:
                          true, // UI library controller handles configuration internally
                    );
                  },
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
              child: StreamBuilder<Map<String, String>>(
                stream: widget.controller.translationStream,
                builder: (context, translationSnapshot) {
                  return TranslationResultWidget(
                    translationService:
                        ServiceLocator.get<TranslationService>(),
                    isCompactMode: true,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _translateText() async {
    final inputText = _textController.text.trim();
    final selectedLanguages = widget.languageController.selectedItems;

    if (inputText.isEmpty) {
      context.showErrorMessage('Please enter text to translate');
      return;
    }

    if (selectedLanguages.isEmpty) {
      context.showErrorMessage('Please select target languages');
      return;
    }

    try {
      widget.controller.inputText = inputText;
      widget.controller.setTargetLanguages(selectedLanguages);
      await widget.controller.translate();

      // Check for errors
      if (widget.controller.errorMessage != null) {
        await _handleTranslationError(widget.controller.errorMessage!);
      }
    } catch (error) {
      if (mounted) {
        await ErrorUtils.handleError(context, error, onRetry: _translateText);
      }
    }
  }

  Future<void> _handleTranslationError(String errorMessage) async {
    if (!mounted) return;

    // Check if it's a configuration error and show config dialog
    if (errorMessage.contains('configure') ||
        errorMessage.contains('configuration')) {
      await _showConfigDialog();
    } else {
      await ErrorUtils.handleError(
        context,
        errorMessage,
        customMessage: errorMessage,
        onRetry: _translateText,
      );
    }
  }

  Future<void> _showConfigDialog() async {
    if (!mounted) return;

    final llmConfigService = ServiceLocator.get<LLMConfigService>();
    final result = await showDialog<LLMConfig>(
      context: context,
      builder: (context) => LLMConfigDialog(
        initialConfig: const LLMConfig(
          provider: 'ollama',
          serverUrl: 'http://localhost:11434',
          selectedModel: '',
        ),
        llmConfigService: llmConfigService,
      ),
    );

    if (result != null && mounted) {
      // Configuration is handled by the UI library controller internally
      context.showSuccessMessage('Configuration updated successfully');
    }
  }
}
