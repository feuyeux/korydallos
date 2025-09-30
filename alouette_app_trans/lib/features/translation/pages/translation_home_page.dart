import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'translation_page.dart';

class TranslationHomePage extends StatefulWidget {
  const TranslationHomePage({super.key});

  @override
  State<TranslationHomePage> createState() => _TranslationHomePageState();
}

class _TranslationHomePageState extends State<TranslationHomePage>
    with AutoControllerDisposal {
  late ITranslationController _controller;
  late ISelectionController<String> _languageController;

  @override
  void initState() {
    super.initState();
    _controller = createTranslationController();
    _languageController = createLanguageSelectionController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Alouette Translator',
        showLogo: true,
        statusWidget: StreamBuilder<bool>(
          stream: _controller.loadingStream,
          builder: (context, loadingSnapshot) {
            final isTranslating = loadingSnapshot.data ?? false;
            return StreamBuilder<String?>(
              stream: _controller.errorStream,
              builder: (context, errorSnapshot) {
                final hasError = errorSnapshot.data != null;
                final defaultConfig = const LLMConfig(
                  provider: 'ollama',
                  serverUrl: 'http://localhost:11434',
                  selectedModel: '',
                );

                return ConfigStatusWidget(
                  isAutoConfiguring: isTranslating,
                  isConfigured: !hasError,
                  autoConfigStatus: isTranslating
                      ? 'Translating...'
                      : (hasError ? 'Configuration needed' : ''),
                  llmConfig: defaultConfig,
                  onConfigurePressed: _showConfigDialog,
                );
              },
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showConfigDialog,
              tooltip: 'Settings',
            ),
          ),
        ],
      ),
      body: TranslationPage(
        controller: _controller,
        languageController: _languageController,
      ),
    );
  }

  void _showConfigDialog() async {
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
