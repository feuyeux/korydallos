import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import 'package:alouette_ui/alouette_ui.dart';

class AppTranslationController {
  // Services accessed through ServiceLocator
  late final LLMConfigService llmConfigService;
  late final TranslationService translationService;
  UnifiedTTSService? ttsService;

  // State notifiers
  final ValueNotifier<LLMConfig> llmConfigNotifier = ValueNotifier(
    const LLMConfig(
      provider: 'ollama',
      serverUrl: 'http://localhost:11434',
      selectedModel: '',
    ),
  );
  final ValueNotifier<bool> isConfiguredNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isAutoConfiguringNotifier = ValueNotifier(false);
  final ValueNotifier<String> autoConfigStatusNotifier = ValueNotifier('');
  final ValueNotifier<bool> isTranslatingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isTTSInitializedNotifier = ValueNotifier(false);

  AppTranslationController() {
    // Get services from ServiceLocator
    llmConfigService = ServiceLocator.get<LLMConfigService>();
    translationService = ServiceLocator.get<TranslationService>();
  }

  Future<void> initialize() async {
    await _performAutoConfiguration();
    await _initializeTTS();
  }

  Future<void> _initializeTTS() async {
    if (isTTSInitializedNotifier.value) {
      debugPrint('TTS: Already initialized, skipping...');
      return;
    }

    try {
      debugPrint('TTS: Starting initialization...');

      ttsService = ServiceLocator.get<UnifiedTTSService>();

      isTTSInitializedNotifier.value = true;
      debugPrint(
        'TTS: Successfully initialized with ${ttsService?.currentEngine}',
      );
    } catch (error) {
      debugPrint('Failed to initialize TTS: $error');
      isTTSInitializedNotifier.value = false;
    }
  }

  Future<void> _performAutoConfiguration() async {
    isAutoConfiguringNotifier.value = true;
    autoConfigStatusNotifier.value = 'Connecting to local AI service...';

    try {
      final autoConfig = await translationService.attemptAutoConfiguration();
      if (autoConfig != null) {
        llmConfigNotifier.value = autoConfig;
        isConfiguredNotifier.value = true;
        isAutoConfiguringNotifier.value = false;
        autoConfigStatusNotifier.value = '';
      } else {
        isAutoConfiguringNotifier.value = false;
        autoConfigStatusNotifier.value = '';
      }
    } catch (error) {
      isAutoConfiguringNotifier.value = false;
      autoConfigStatusNotifier.value = '';
      debugPrint('Auto-configuration error: $error');
    }
  }

  void updateLLMConfig(LLMConfig config) {
    llmConfigNotifier.value = config;
    isConfiguredNotifier.value = config.selectedModel.isNotEmpty;
  }

  Future<void> translateText(String text, List<String> targetLanguages) async {
    isTranslatingNotifier.value = true;
    try {
      await translationService.translateText(
        text,
        targetLanguages,
        llmConfigNotifier.value,
      );
    } finally {
      isTranslatingNotifier.value = false;
    }
  }

  void dispose() {
    llmConfigNotifier.dispose();
    isConfiguredNotifier.dispose();
    isAutoConfiguringNotifier.dispose();
    autoConfigStatusNotifier.dispose();
    isTranslatingNotifier.dispose();
    isTTSInitializedNotifier.dispose();
    // Services are managed by ServiceLocator, no need to dispose manually
  }
}