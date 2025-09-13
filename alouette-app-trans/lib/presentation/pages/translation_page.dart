import 'package:flutter/material.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';

class TranslationPage extends StatefulWidget {
  const TranslationPage({super.key});

  @override
  State<TranslationPage> createState() => _TranslationPageState();
}

class _TranslationPageState extends State<TranslationPage> {
  final LLMConfigService _llmConfigService = LLMConfigService();
  final TranslationService _translationService = TranslationService();
  final AutoConfigService _autoConfigService = AutoConfigService();

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

  @override
  void initState() {
    super.initState();
    _performAutoConfiguration();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Alouette Translator',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showConfigDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Configuration status indicator
            ConfigStatusWidget(
              isAutoConfiguring: _isAutoConfiguring,
              isConfigured: _isConfigured,
              autoConfigStatus: _autoConfigStatus,
              llmConfig: _llmConfig,
              onConfigurePressed: _showConfigDialog,
            ),
            const SizedBox(height: 2),

            // Translation input area
            Expanded(
              flex: 2,
              child: TranslationInputWidget(
                textController: _textController,
                selectedLanguages: _selectedLanguages,
                onLanguagesChanged: (languages) {
                  setState(() {
                    _selectedLanguages.clear();
                    _selectedLanguages.addAll(languages);
                  });
                },
                onTranslate: _translateText,
                isTranslating: _translationService.isTranslating,
                isConfigured: _isConfigured,
              ),
            ),

            const SizedBox(height: 8),

            // Translation result area
            Expanded(
              flex: 3,
              child: TranslationResultWidget(
                translationService: _translationService,
                isCompactMode: true,
              ),
            ),
          ],
        ),
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

  /// 执行自动配置
  Future<void> _performAutoConfiguration() async {
    setState(() {
      _isAutoConfiguring = true;
      _autoConfigStatus = 'Testing connection to ollama...';
    });

    try {
      // 尝试自动配置
      final autoConfig = await _autoConfigService.autoConfigureLLM();

      if (autoConfig != null) {
        setState(() {
          _llmConfig = autoConfig;
          _isConfigured = true;
          _isAutoConfiguring = false;
          _autoConfigStatus = '';
        });

        // 显示成功消息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Auto-connected to Ollama with model: ${autoConfig.selectedModel}',
              ),
              backgroundColor: Colors.green.shade600,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        setState(() {
          _isAutoConfiguring = false;
          _autoConfigStatus = '';
        });

        // 显示需要手动配置的消息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Auto-configuration failed. Please configure manually.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (error) {
      setState(() {
        _isAutoConfiguring = false;
        _autoConfigStatus = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-configuration error: $error'),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
