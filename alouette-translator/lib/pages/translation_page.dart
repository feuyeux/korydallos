import 'package:flutter/material.dart';
import '../models/translation_models.dart';
import '../services/llm_config_service.dart';
import '../services/translation_service.dart';
import '../services/auto_config_service.dart';
import '../widgets/llm_config_dialog.dart';
import '../widgets/translation_input_widget.dart';
import '../widgets/translation_result_widget.dart';

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
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.translate,
              size: 24,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            const Text('Alouette Translator'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false, // 移除返回按钮
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
            // 配置状态指示器
            _buildConfigStatus(),
            const SizedBox(height: 2),

            // 翻译输入区域
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

            // 翻译结果区域
            Expanded(
              flex: 3,
              child: TranslationResultWidget(
                translationService: _translationService,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigStatus() {
    // 如果正在自动配置，显示进度状态
    if (_isAutoConfiguring) {
      return Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _autoConfigStatus.isEmpty
                      ? 'Auto-configuring LLM connection...'
                      : _autoConfigStatus,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 如果已配置成功，显示成功状态
    if (_isConfigured) {
      return Card(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Connected to Ollama',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade800,
                      ),
                    ),
                    if (_llmConfig.selectedModel.isNotEmpty)
                      Text(
                        'Model: ${_llmConfig.selectedModel}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 如果配置失败，显示错误状态
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Auto-configuration failed. Click the settings button to configure manually.',
              ),
            ),
            TextButton(
              onPressed: _showConfigDialog,
              child: const Text('Configure'),
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
