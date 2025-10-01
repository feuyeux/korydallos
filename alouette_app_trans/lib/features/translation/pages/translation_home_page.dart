import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import '../controllers/translation_controller.dart';
import '../../../config/translation_app_config.dart';
import 'translation_page.dart';
import '../../../widgets/translation_status_widget.dart';

class TranslationHomePage extends StatefulWidget {
  const TranslationHomePage({super.key});

  @override
  State<TranslationHomePage> createState() => _TranslationHomePageState();
}

class _TranslationHomePageState extends State<TranslationHomePage> {
  late AppTranslationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppTranslationController();
    _controller.addListener(_onControllerChanged);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: TranslationAppConfig.appName,
        showLogo: true,
        statusWidget: const TranslationStatusWidget(),
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
      body: TranslationPage(controller: _controller),
    );
  }

  void _showConfigDialog() async {
    final result = await _controller.showConfigDialog(context);

    if (result != null) {
      _controller.updateLLMConfig(result);
    }
  }
}
