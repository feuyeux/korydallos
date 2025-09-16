import 'package:flutter/material.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';
import '../../services/auto_config_service.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';

class TranslationPage extends StatefulWidget {
  const TranslationPage({super.key});

  @override
  State<TranslationPage> createState() => _TranslationPageState();
}

class _TranslationPageState extends State<TranslationPage> {
  final LLMConfigService _llmConfigService = LLMConfigService();
  final TranslationService _translationService = TranslationService();
  final AutoConfigService _autoConfigService = AutoConfigService();
  TTSService? _ttsService;

  LLMConfig _llmConfig = const LLMConfig(
    provider: 'ollama',
    serverUrl: 'http://localhost:11434',
    selectedModel: '',
  );

  final TextEditingController _textController = TextEditingController();
  final List<String> _selectedLanguages = [];
  bool _isConfigured = false;
  bool _isAutoConfiguring = false;
  String _autoConfigStatus = '';
  bool _isTTSInitialized = false;

  @override
  void initState() {
    super.initState();
    _performAutoConfiguration();
    _initializeTTS();
  }

  @override
  void dispose() {
    _textController.dispose();
    SharedTTSManager.dispose();
    super.dispose();
  }

  Future<void> _initializeTTS() async {
    if (_isTTSInitialized) {
      debugPrint('TTS: Already initialized, skipping...');
      return;
    }

    try {
      debugPrint('TTS: Starting initialization...');

      _ttsService = await SharedTTSManager.getService().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('TTS initialization timeout after 10 seconds');
        },
      );

      setState(() {
        _isTTSInitialized = true;
      });
      debugPrint(
        'TTS: Successfully initialized with ${_ttsService?.currentEngine}',
      );
    } catch (error) {
      debugPrint('Failed to initialize TTS: $error');
      setState(() {
        _isTTSInitialized = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TTS initialization failed: $error'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          ConfigStatusWidget(
            isAutoConfiguring: _isAutoConfiguring,
            isConfigured: _isConfigured,
            autoConfigStatus: _autoConfigStatus,
            llmConfig: _llmConfig,
            onConfigurePressed: _showConfigDialog,
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 3,
            child: TranslationInputWidget(
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
              isTranslating: _translationService.isTranslating,
              isConfigured: _isConfigured,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            flex: 3,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TranslationResultWidget(
                  translationService: _translationService,
                  isCompactMode: true,
                  ttsService: _ttsService,
                  isTTSInitialized: _isTTSInitialized,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfigDialog() async {
    final result = await showDialog<LLMConfig>(
      context: context,
      builder: (context) => LLMConfigDialog(
        initialConfig: _llmConfig,
        llmConfigService: _llmConfigService,
      ),
    );

    if (result != null) {
      setState(() {
        _llmConfig = result;
        _isConfigured = result.selectedModel.isNotEmpty;
      });
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

    if (!_isConfigured) {
      _showErrorSnackBar('Please configure LLM settings first');
      _showConfigDialog();
      return;
    }

    try {
      setState(() {});
      await _translationService.translateText(
        _textController.text,
        _selectedLanguages,
        _llmConfig,
      );
      setState(() {});
    } catch (error) {
      setState(() {});
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

  Future<void> _performAutoConfiguration() async {
    if (mounted) {
      setState(() {
        _isAutoConfiguring = true;
        _autoConfigStatus = 'Connecting to local AI service...';
      });
    }

    try {
      final autoConfig = await _autoConfigService.attemptAutoConfiguration();
      if (mounted) {
        if (autoConfig != null) {
          setState(() {
            _llmConfig = autoConfig;
            _isConfigured = true;
            _isAutoConfiguring = false;
            _autoConfigStatus = '';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Auto-connected to Ollama with model: ${autoConfig.selectedModel}',
              ),
              backgroundColor: Colors.green.shade600,
            ),
          );
        } else {
          setState(() {
            _isAutoConfiguring = false;
            _autoConfigStatus = '';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Auto-configuration failed. Please configure manually.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isAutoConfiguring = false;
          _autoConfigStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-configuration error: $error'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }
}
