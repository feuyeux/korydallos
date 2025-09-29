import 'package:flutter/material.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'package:alouette_ui/alouette_ui.dart';
import '../features/translation/translation_controller.dart' as app_controllers;

/// Translation Status Widget for AppBar
/// 
/// This widget displays the LLM connection status in the app bar
class TranslationStatusWidget extends StatefulWidget {
  const TranslationStatusWidget({super.key});

  @override
  State<TranslationStatusWidget> createState() => _TranslationStatusWidgetState();
}

class _TranslationStatusWidgetState extends State<TranslationStatusWidget> {
  late final app_controllers.AppTranslationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = app_controllers.AppTranslationController();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LLMConfig>(
      valueListenable: _controller.llmConfigNotifier,
      builder: (context, llmConfig, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: _controller.isAutoConfiguringNotifier,
          builder: (context, isAutoConfiguring, child) {
            return ValueListenableBuilder<bool>(
              valueListenable: _controller.isConfiguredNotifier,
              builder: (context, isConfigured, child) {
                return ValueListenableBuilder<String>(
                  valueListenable: _controller.autoConfigStatusNotifier,
                  builder: (context, autoConfigStatus, child) {
                    return ConfigStatusWidget(
                      isAutoConfiguring: isAutoConfiguring,
                      isConfigured: isConfigured,
                      autoConfigStatus: autoConfigStatus,
                      llmConfig: llmConfig,
                      onConfigurePressed: _showConfigDialog,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _showConfigDialog() async {
    final result = await showDialog<LLMConfig>(
      context: context,
      builder: (context) => LLMConfigDialog(
        initialConfig: _controller.llmConfigNotifier.value,
        llmConfigService: _controller.llmConfigService,
      ),
    );

    if (result != null) {
      _controller.updateLLMConfig(result);
    }
  }
}