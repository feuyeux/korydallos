import 'dart:async';
import 'package:alouette_lib_trans/src/providers/base_translation_provider.dart';
import 'package:alouette_lib_trans/src/models/llm_config.dart';
import 'package:alouette_lib_trans/src/models/connection_status.dart';
import 'package:alouette_lib_trans/src/exceptions/translation_exceptions.dart';

/// Mock translation provider for testing purposes
class MockTranslationProvider implements TranslationProvider {
  String? _mockTranslation;
  Map<String, String>? _mockTranslations;
  dynamic _mockError;
  ConnectionStatus? _mockConnectionStatus;
  List<String>? _mockModels;
  bool _failFirstAttempt = false;
  String? _failForLanguage;
  int _attemptCount = 0;

  int get attemptCount => _attemptCount;

  void setMockTranslation(String translation) {
    _mockTranslation = translation;
    _mockTranslations = null;
    _mockError = null;
  }

  void setMockTranslations(Map<String, String> translations) {
    _mockTranslations = translations;
    _mockTranslation = null;
    _mockError = null;
  }

  void setMockError(dynamic error) {
    _mockError = error;
    _mockTranslation = null;
    _mockTranslations = null;
  }

  void setMockConnectionStatus(ConnectionStatus status) {
    _mockConnectionStatus = status;
  }

  void setMockModels(List<String> models) {
    _mockModels = models;
  }

  void setFailFirstAttempt(bool fail) {
    _failFirstAttempt = fail;
    _attemptCount = 0;
  }

  void setFailForLanguage(String language) {
    _failForLanguage = language;
  }

  void reset() {
    _mockTranslation = null;
    _mockTranslations = null;
    _mockError = null;
    _mockConnectionStatus = null;
    _mockModels = null;
    _failFirstAttempt = false;
    _failForLanguage = null;
    _attemptCount = 0;
  }

  @override
  Future<String> translateText({
    required String text,
    required String targetLanguage,
    required LLMConfig config,
    Map<String, dynamic>? additionalParams,
  }) async {
    _attemptCount++;

    // Simulate first attempt failure if configured
    if (_failFirstAttempt && _attemptCount == 1) {
      throw TranslationException('First attempt failed (mock)');
    }

    // Simulate language-specific failure if configured
    if (_failForLanguage == targetLanguage) {
      throw TranslationException('Mock error for language: $targetLanguage');
    }

    // Throw mock error if configured
    if (_mockError != null) {
      throw _mockError!;
    }

    // Return mock translation for specific language
    if (_mockTranslations != null) {
      final translation = _mockTranslations![targetLanguage];
      if (translation == null) {
        throw TranslationException('No mock translation for language: $targetLanguage');
      }
      if (translation == 'ERROR') {
        throw TranslationException('Mock translation error for: $targetLanguage');
      }
      return translation;
    }

    // Return general mock translation
    if (_mockTranslation != null) {
      return _mockTranslation!;
    }

    // Default behavior
    return 'Mock translation of "$text" to $targetLanguage';
  }

  @override
  Future<ConnectionStatus> testConnection(LLMConfig config) async {
    if (_mockConnectionStatus != null) {
      return _mockConnectionStatus!;
    }

    return ConnectionStatus.success(
      message: 'Mock connection successful',
      responseTimeMs: 50,
    );
  }

  @override
  Future<List<String>> getAvailableModels(LLMConfig config) async {
    if (_mockModels != null) {
      return _mockModels!;
    }

    return ['mock-model-1', 'mock-model-2', 'mock-model-3'];
  }

  @override
  String get providerName => 'mock';

  @override
  String get displayName => 'Mock Provider';

  @override
  String get description => 'Mock provider for testing';

  @override
  Map<String, dynamic> get defaultConfig => {
    'serverUrl': 'http://localhost:11434',
    'apiKey': '',
  };

  @override
  bool get requiresApiKey => false;

  @override
  bool get supportsStreaming => false;

  @override
  List<String> get supportedLanguages => [
    'en', 'es', 'fr', 'de', 'it', 'pt', 'ru', 'ja', 'ko', 'zh'
  ];

  @override
  bool supportsConfig(LLMConfig config) {
    return config.provider == 'mock';
  }

  @override
  LLMConfig getDefaultConfig() {
    return LLMConfig(
      provider: 'mock',
      serverUrl: 'http://localhost:11434',
      selectedModel: 'mock-model',
    );
  }

  @override
  String getSystemPrompt(String targetLanguage) {
    return 'Mock system prompt for $targetLanguage';
  }

  @override
  String getExplicitLanguageSpec(String targetLang) {
    return 'Mock language spec for $targetLang';
  }
}