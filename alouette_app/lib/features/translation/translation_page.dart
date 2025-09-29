import 'package:flutter/material.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'package:alouette_ui/alouette_ui.dart';
import 'translation_controller.dart' as app_controllers;

class TranslationPage extends StatefulWidget {
  const TranslationPage({super.key});

  @override
  State<TranslationPage> createState() => _TranslationPageState();
}

class _TranslationPageState extends State<TranslationPage> {
  late final app_controllers.AppTranslationController _controller;
  final TextEditingController _textController = TextEditingController();
  final List<String> _selectedLanguages = [];

  @override
  void initState() {
    super.initState();
    _controller = app_controllers.AppTranslationController();
    _controller.initialize();
  }

  @override
  void dispose() {
    _textController.dispose();
    _controller.dispose();
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
            child: ValueListenableBuilder<bool>(
              valueListenable: _controller.isTranslatingNotifier,
              builder: (context, isTranslating, child) {
                return ValueListenableBuilder<bool>(
                  valueListenable: _controller.isConfiguredNotifier,
                  builder: (context, isConfigured, child) {
                    return TranslationInputWidget(
                      textController: _textController,
                      selectedLanguages: _selectedLanguages,
                      onLanguagesChanged: (languages) {
                        setState(() {
                          _selectedLanguages.clear();
                          _selectedLanguages.addAll(languages);
                        });
                      },
                      onLanguageToggle: (language, selected) {
                        setState(() {
                          if (selected) {
                            _selectedLanguages.add(language);
                          } else {
                            _selectedLanguages.remove(language);
                          }
                        });
                      },
                      onTranslate: _translateText,
                      isTranslating: isTranslating,
                      isConfigured: isConfigured,
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
              child: ValueListenableBuilder<bool>(
                valueListenable: _controller.isTTSInitializedNotifier,
                builder: (context, isTTSInitialized, child) {
                  return TranslationResultWidget(
                    translationService: _controller.translationService,
                    isCompactMode: true,
                    ttsService: _controller.ttsService,
                    isTTSInitialized: isTTSInitialized,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showConfigDialog() async {
    final result = await showDialog<LLMConfig>(
      context: context,
      builder: (context) => LLMConfigDialog(
        initialConfig: _controller.llmConfigNotifier.value,
        llmConfigService: _controller.llmConfigService,
      ),
    );

    if (result != null) {
      _controller.updateLLMConfig(result);
    }
  }

  void _translateText() async {
    if (_textController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter text to translate');
      return;
    }

    if (_selectedLanguages.isEmpty) {
      _showErrorSnackBar('Please select target languages');
      return;
    }

    if (!_controller.isConfiguredNotifier.value) {
      _showErrorSnackBar('Please configure LLM settings first');
      _showConfigDialog();
      return;
    }

    try {
      await _controller.translateText(
        _textController.text,
        _selectedLanguages,
      );
    } catch (error) {
      _showErrorSnackBar(error.toString());
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}