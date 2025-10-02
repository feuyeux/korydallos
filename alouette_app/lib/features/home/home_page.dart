import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'home_controller.dart';
import '../translation/translation_page.dart';
import '../../widgets/translation_status_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutoControllerDisposal {
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Alouette Translator',
        showLogo: true,
        statusWidget: const TranslationStatusWidget(), // 新增状态组件
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0), // 向左移动按钮
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showConfigDialog,
              tooltip: 'Settings',
            ),
          ),
        ],
      ),
      body: const TranslationPage(),
    );
  }

  void _showConfigDialog() async {
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
