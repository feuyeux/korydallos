import 'package:flutter/material.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'package:alouette_ui/alouette_ui.dart';

class TranslationStatusWidget extends StatelessWidget {
  const TranslationStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ConfigStatusWidget(
      isAutoConfiguring: false,
      isConfigured: true,
      autoConfigStatus: 'Ready',
      llmConfig: const LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        selectedModel: '',
      ),
      onConfigurePressed: () => _showConfigDialog(context),
    );
  }

  void _showConfigDialog(BuildContext context) async {
    final llmConfigService = LLMConfigService();
    await showDialog<LLMConfig>(
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
  }
}


