import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import 'package:alouette_app_trans/alouette_app_trans.dart';
import '../widgets/app_translation_status_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutoControllerDisposal {
  late final AppTranslationController _controller;

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
      appBar: CustomAppBar(
        title: 'Alouette Translator',
        showLogo: true,
        statusWidget: AppTranslationStatusWidget(controller: _controller),
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

    // The controller already handles saving the configuration
    // No need to call updateLLMConfig again
    if (result != null && mounted) {
      // Configuration was saved successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration updated successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
