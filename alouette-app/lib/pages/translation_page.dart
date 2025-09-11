import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';
import '../services/tts_manager.dart';

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
  List<String> _selectedLanguages = const [];
  bool _isConfigured = false;
  bool _isAutoConfiguring = false;
  String _autoConfigStatus = '';
  bool _isTTSInitialized = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguages =
        List.unmodifiable([LanguageConstants.defaultLanguage.code]);
    _performAutoConfiguration();
    _initializeTTS();
  }

  @override
  void dispose() {
    _textController.dispose();
    TTSManager.dispose();
    super.dispose();
  }

  Future<void> _initializeTTS() async {
    if (_isTTSInitialized) {
      debugPrint('TTS: Already initialized, skipping...');
      return;
    }

    try {
      debugPrint('TTS: Starting initialization...');
      
      _ttsService = await TTSManager.getService().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('TTS initialization timeout after 10 seconds');
        },
      );

      setState(() {
        _isTTSInitialized = true;
      });
      debugPrint('TTS: Successfully initialized with ${_ttsService?.currentEngine}');
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

  Future<void> _performAutoConfiguration() async {
    if (mounted) {
      setState(() {
        _isAutoConfiguring = true;
        _autoConfigStatus = 'Connecting to local AI service...';
      });
    }

    try {
      final autoConfig = await _autoConfigService.autoConfigureLLM();
      if (mounted) {
        if (autoConfig != null) {
          setState(() {
            _llmConfig = autoConfig;
            _isConfigured = true;
            _isAutoConfiguring = false;
            _autoConfigStatus =
                'Successfully connected to ${autoConfig.selectedModel}';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Auto-configured with model: ${autoConfig.selectedModel}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          setState(() {
            _isAutoConfiguring = false;
            _autoConfigStatus =
                'Auto-configuration failed. Please configure manually.';
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isAutoConfiguring = false;
          _autoConfigStatus = 'Auto-configuration error: $error';
        });
      }
    }
  }

  Future<void> _showConfigDialog() async {
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

  Future<void> _showTTSConfigDialog() async {
    await showDialog(
      context: context,
      builder: (context) => TTSConfigDialog(
        ttsService: _ttsService,
      ),
    );
  }

  Future<void> _performTranslation() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter text to translate'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one target language'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please configure LLM settings first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _translationService.translateText(
        _textController.text,
        _selectedLanguages,
        _llmConfig,
      );

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Translation completed'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Translation failed: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: _isConfigured ? Colors.green.shade50 : Colors.orange.shade50,
            border: Border(
              bottom: BorderSide(
                color: _isConfigured
                    ? Colors.green.shade200
                    : Colors.orange.shade200,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isConfigured ? Icons.check_circle : Icons.warning,
                color: _isConfigured
                    ? Colors.green.shade600
                    : Colors.orange.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isAutoConfiguring
                      ? _autoConfigStatus
                      : _isConfigured
                          ? 'Model: ${_llmConfig.selectedModel} (${_llmConfig.provider})'
                          : 'LLM not configured. Please click the settings button.',
                  style: TextStyle(
                    color: _isConfigured
                        ? Colors.green.shade800
                        : Colors.orange.shade800,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(
                width: 20,
                height: 16,
                child: _isAutoConfiguring
                    ? Center(
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.orange.shade600,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  height: 250,
                  child: TranslationInputWidget(
                    textController: _textController,
                    selectedLanguages: _selectedLanguages,
                    onTranslate: _performTranslation,
                    translationService: _translationService,
                    onLanguageToggle: (language, selected) {
                      setState(() {
                        if (selected) {
                          _selectedLanguages = List.unmodifiable([
                            ..._selectedLanguages,
                            language,
                          ]);
                        } else {
                          _selectedLanguages = List.unmodifiable(
                            _selectedLanguages
                                .where((l) => l != language)
                                .toList(),
                          );
                        }
                      });
                    },
                    onReset: () {
                      setState(() {
                        _selectedLanguages = List.unmodifiable(
                            [LanguageConstants.defaultLanguage.code]);
                      });
                    },
                    onSelectAll: () {
                      setState(() {
                        _selectedLanguages = List.unmodifiable(LanguageConstants
                            .supportedLanguages
                            .map((lang) => lang.code)
                            .toList());
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TranslationResultWidget(
                    translationService: _translationService,
                    ttsService: _ttsService,
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: _showTTSConfigDialog,
                icon: const Icon(Icons.record_voice_over, size: 18),
                label: const Text('TTS Settings'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  backgroundColor:
                      _isTTSInitialized ? null : Colors.grey.shade300,
                  foregroundColor:
                      _isTTSInitialized ? null : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _showConfigDialog,
                icon: const Icon(Icons.settings, size: 18),
                label: const Text('LLM Settings'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
