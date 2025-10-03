import 'package:flutter/material.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'package:alouette_lib_tts/alouette_tts.dart' as tts_lib;
import 'package:alouette_ui/alouette_ui.dart';

class TranslationPage extends StatefulWidget {
  const TranslationPage({super.key});

  @override
  State<TranslationPage> createState() => _TranslationPageState();
}

class _TranslationPageState extends State<TranslationPage>
    with AutoControllerDisposal {
  late final ITranslationController _controller;
  late final ISelectionController<String> _languageController;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = createTranslationController();
    _languageController = createLanguageSelectionController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 直接在build中获取服务 - 确保总是最新状态
    final translationService = ServiceLocator.get<TranslationService>();
    final ttsService = ServiceLocator.isRegistered<tts_lib.TTSService>() 
        ? ServiceLocator.get<tts_lib.TTSService>() 
        : null;
    final isTTSInitialized = ttsService?.isInitialized ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Input area
        Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 1.0, 8.0, 0.5),
          child: StreamBuilder<bool>(
            stream: _controller.loadingStream,
            builder: (context, loadingSnapshot) {
              final isTranslating = loadingSnapshot.data ?? false;
              return StreamBuilder<List<String>>(
                stream: _languageController.selectionStream,
                builder: (context, selectionSnapshot) {
                  final selectedLanguages = selectionSnapshot.data ?? [];
                  return TranslationInputWidget(
                    textController: _textController,
                    selectedLanguages: selectedLanguages,
                    onLanguagesChanged: (languages) {
                      _languageController.clearSelection();
                      if (languages.isNotEmpty) {
                        _languageController.selectMultiple(languages);
                      }
                    },
                    onLanguageToggle: (language, selected) {
                      if (selected) {
                        _languageController.select(language);
                      } else {
                        _languageController.deselect(language);
                      }
                    },
                    onTranslate: _translateText,
                    onClearResults: () {
                      _controller.clearTranslations();
                    },
                    isTranslating: isTranslating,
                    isConfigured: true,
                  );
                },
              );
            },
          ),
        ),
        // Results area - with TTS support (get services directly in build)
        Expanded(
          child: Card(
            margin: const EdgeInsets.fromLTRB(8.0, 0.5, 8.0, 1.0),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: TranslationResultWidget(
                translationService: translationService,
                ttsService: ttsService,
                isTTSInitialized: isTTSInitialized,
                isCompactMode: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _translateText() async {
    final inputText = _textController.text.trim();
    final selectedLanguages = _languageController.selectedItems;

    if (inputText.isEmpty) {
      context.showErrorMessage('Please enter text to translate');
      return;
    }

    if (selectedLanguages.isEmpty) {
      context.showErrorMessage('Please select target languages');
      return;
    }

    try {
      _controller.inputText = inputText;
      _controller.setTargetLanguages(selectedLanguages);
      await _controller.translate();

      // Check for errors
      if (_controller.errorMessage != null) {
        await _handleTranslationError(_controller.errorMessage!);
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

    final translationService = ServiceLocator.get<TranslationService>();
    final result = await showDialog<LLMConfig>(
      context: context,
      builder: (context) => LLMConfigDialog(
        initialConfig: const LLMConfig(
          provider: 'ollama',
          serverUrl: 'http://localhost:11434',
          selectedModel: '',
        ),
        translationService: translationService,
      ),
    );

    if (result != null && mounted) {
      // Configuration is handled by the UI library controller internally
      context.showSuccessMessage('Configuration updated successfully');
    }
  }
}
