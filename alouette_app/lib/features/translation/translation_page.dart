import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 4,
          child: Padding(
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
                        // 先清除所有选择，然后选择新的语言列表
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
                stream: _controller.translationStream,
                builder: (context, translationSnapshot) {
                  final translations = translationSnapshot.data ?? {};
                  
                  if (translations.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.translate,
                            size: 32,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Translation results will appear here',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: translations.length,
                    itemBuilder: (context, index) {
                      final language = translations.keys.elementAt(index);
                      final translatedText = translations[language] ?? '';
                      return _buildTranslationItem(language, translatedText);
                    },
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

  Widget _buildTranslationItem(String language, String translatedText) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language title bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                Text(
                  language,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.green.shade800,
                  ),
                ),
                const Spacer(),
                // TTS play button
                IconButton(
                  icon: Icon(
                    Icons.volume_up,
                    size: 16,
                    color: Colors.blue,
                  ),
                  tooltip: 'Play with TTS',
                  onPressed: () => _playTTS(language, translatedText),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                // Copy button
                IconButton(
                  icon: Icon(
                    Icons.copy,
                    size: 16,
                    color: Colors.green.shade700,
                  ),
                  tooltip: 'Copy translation',
                  onPressed: () => _copyTranslation(language, translatedText),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Translation text
          Padding(
            padding: const EdgeInsets.all(6),
            child: SelectableText(
              translatedText,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _playTTS(String language, String text) async {
    try {
      // Check if TTS service is available
      if (!ServiceLocator.isRegistered<ITTSService>()) {
        throw Exception('TTS service not available');
      }

      final ttsService = ServiceLocator.get<ITTSService>();
      
      // Check if TTS service is initialized
      if (!ttsService.isInitialized) {
        // Try to initialize TTS service
        final initialized = await ttsService.initialize();
        if (!initialized) {
          throw Exception('Failed to initialize TTS service');
        }
      }

      // Use the TTS service's language-aware voice selection
      await ttsService.speakInLanguage(text, language);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playing $language audio'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TTS not available: ${e.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }



  void _copyTranslation(String language, String translatedText) {
    Clipboard.setData(ClipboardData(text: translatedText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$language translation copied'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
