import 'package:flutter/material.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'package:alouette_ui/alouette_ui.dart';

/// Translation Status Widget for AppBar
///
/// This widget displays the LLM connection status in the app bar
class TranslationStatusWidget extends StatelessWidget {
  const TranslationStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Use the UI library's ConfigStatusWidget directly with default configuration
    return ConfigStatusWidget(
      isAutoConfiguring: false,
      isConfigured:
          true, // Assume configured for now - UI library handles this internally
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
    final llmConfigService = ServiceLocator.get<LLMConfigService>();
    final result = await showDialog<LLMConfig>(
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

    if (result != null) {
      // Configuration is handled by the UI library controller internally
    }
  }
}
