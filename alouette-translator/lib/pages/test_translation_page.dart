import 'package:flutter/material.dart';
import '../models/translation_models.dart';
import '../services/llm_config_service.dart';
import '../services/translation_service.dart';
import '../services/auto_config_service.dart';

class TestTranslationPage extends StatefulWidget {
  const TestTranslationPage({super.key});

  @override
  State<TestTranslationPage> createState() => _TestTranslationPageState();
}

class _TestTranslationPageState extends State<TestTranslationPage> {
  final LLMConfigService _llmService = LLMConfigService();
  final TranslationService _translationService = TranslationService();
  final AutoConfigService _autoConfigService = AutoConfigService();
  final TextEditingController _textController = TextEditingController();

  String _status = 'Ready';
  String _result = '';
  LLMConfig? _currentConfig;

  @override
  void initState() {
    super.initState();
    _performAutoSetup();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Translation Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Enter text to translate',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _testConnection,
              child: const Text('Test Ollama Connection'),
            ),
            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: _translateText,
              child: const Text('Translate to Chinese'),
            ),
            const SizedBox(height: 16),

            Text('Status: $_status'),
            const SizedBox(height: 8),

            Expanded(child: SingleChildScrollView(child: Text(_result))),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _status = 'Testing connection...';
    });

    try {
      final autoConfig = await _autoConfigService.autoConfigureLLM();

      if (autoConfig != null) {
        _currentConfig = autoConfig;
        setState(() {
          _status = 'Connected successfully';
          _result =
              'Model: ${autoConfig.selectedModel}\nAvailable models: ${_llmService.availableModels.join(', ')}';
        });
      } else {
        setState(() {
          _status = 'Connection failed';
          _result = 'Could not connect to Ollama or no models available';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _result = '';
      });
    }
  }

  Future<void> _translateText() async {
    if (_textController.text.trim().isEmpty) {
      setState(() {
        _status = 'Please enter text to translate';
      });
      return;
    }

    if (_currentConfig == null) {
      setState(() {
        _status = 'LLM not configured. Please test connection first.';
      });
      return;
    }

    setState(() {
      _status = 'Translating...';
    });

    try {
      final result = await _translationService.translateText(
        _textController.text,
        ['Chinese'],
        _currentConfig!,
      );

      setState(() {
        _status = 'Translation completed';
        _result =
            'Original: ${result.original}\n\n'
            'Chinese: ${result.translations['Chinese'] ?? 'No translation'}';
      });
    } catch (e) {
      setState(() {
        _status = 'Translation failed: $e';
        _result = '';
      });
    }
  }

  /// 执行自动设置
  Future<void> _performAutoSetup() async {
    setState(() {
      _status = 'Auto-configuring...';
    });

    try {
      final autoConfig = await _autoConfigService.autoConfigureLLM();

      if (autoConfig != null) {
        setState(() {
          _currentConfig = autoConfig;
          _status = 'Auto-configured with model: ${autoConfig.selectedModel}';
          _result = 'Ready for translation';
        });
      } else {
        setState(() {
          _status =
              'Auto-configuration failed. Please test connection manually.';
          _result = '';
        });
      }
    } catch (error) {
      setState(() {
        _status = 'Auto-configuration error: $error';
        _result = '';
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
