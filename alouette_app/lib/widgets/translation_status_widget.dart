import 'package:flutter/material.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'package:alouette_ui/alouette_ui.dart';

/// Translation Status Widget for AppBar
///
/// This widget displays the LLM connection status in the app bar
class TranslationStatusWidget extends StatefulWidget {
  const TranslationStatusWidget({super.key});

  @override
  State<TranslationStatusWidget> createState() => _TranslationStatusWidgetState();
}

class _TranslationStatusWidgetState extends State<TranslationStatusWidget> {
  late TranslationService _translationService;
  bool _isChecking = true;
  bool _isConfigured = false;
  LLMConfig? _currentConfig;

  @override
  void initState() {
    super.initState();
    _translationService = ServiceLocator.get<TranslationService>();
    // Delay check until after first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConfiguration();
    });
  }

  Future<void> _checkConfiguration() async {
    setState(() => _isChecking = true);
    
    try {
      // 尝试获取自动检测的配置
      final autoConfig = _translationService.autoDetectedConfig;
      
      if (autoConfig != null) {
        // 测试连接
        final status = await _translationService.testConnection(autoConfig);
        setState(() {
          _isConfigured = status.success;
          _currentConfig = autoConfig;
          _isChecking = false;
        });
      } else {
        // 没有配置，尝试自动配置
        final success = await _translationService.initialize();
        setState(() {
          _isConfigured = success;
          _currentConfig = _translationService.autoDetectedConfig;
          _isChecking = false;
        });
      }
    } catch (e) {
      setState(() {
        _isConfigured = false;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConfigStatusWidget(
      isAutoConfiguring: _isChecking,
      isConfigured: _isConfigured,
      autoConfigStatus: _isChecking ? 'Checking connection...' : 'Ready',
      llmConfig: _currentConfig ?? const LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        selectedModel: '',
      ),
      onConfigurePressed: () => _showConfigDialog(context),
    );
  }

  void _showConfigDialog(BuildContext context) async {
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

    if (result != null) {
      // Configuration is handled by the UI library controller internally
    }
  }
}
