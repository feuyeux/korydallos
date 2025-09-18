import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';

void main() {
  group('Basic Translation Service Unit Tests', () {
    late TranslationService service;

    setUp(() {
      service = TranslationService();
    });

    test('should initialize with default providers', () {
      expect(service.availableProviders, contains('ollama'));
      expect(service.availableProviders, contains('lmstudio'));
    });

    test('should support provider checking', () {
      expect(service.isProviderSupported('ollama'), isTrue);
      expect(service.isProviderSupported('lmstudio'), isTrue);
      expect(service.isProviderSupported('unknown'), isFalse);
    });

    test('should validate LLM config', () {
      final config = LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      final validation = service.validateConfig(config);
      expect(validation['isValid'], isTrue);
    });

    test('should create translation request', () {
      final config = LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      final request = service.createRequest(
        'Hello world',
        ['es', 'fr'],
        config,
      );

      expect(request.text, equals('Hello world'));
      expect(request.targetLanguages, equals(['es', 'fr']));
      expect(request.provider, equals('ollama'));
    });

    test('should clear translation and connection state', () {
      service.clearTranslation();
      service.clearConnection();

      expect(service.currentTranslation, isNull);
      expect(service.availableModels, isEmpty);
      expect(service.connectionStatus, isNull);
    });

    test('should provide translation state information', () {
      final state = service.getTranslationState();

      expect(state['isTranslating'], isFalse);
      expect(state['hasTranslation'], isFalse);
      expect(state['currentTranslation'], isNull);
    });

    test('should provide translation statistics for empty state', () {
      final stats = service.getTranslationStats();

      expect(stats['totalTranslations'], equals(0));
      expect(stats['completedTranslations'], equals(0));
      expect(stats['completionRate'], equals(0.0));
    });

    test('should get recommended settings for providers', () {
      final ollamaSettings = service.getRecommendedSettings('ollama');
      expect(ollamaSettings['serverUrl'], equals('http://localhost:11434'));
      expect(ollamaSettings['description'], contains('Ollama'));

      final lmStudioSettings = service.getRecommendedSettings('lmstudio');
      expect(lmStudioSettings['serverUrl'], equals('http://localhost:1234'));
      expect(lmStudioSettings['description'], contains('LM Studio'));
    });

    test('should handle Android-specific settings', () {
      final ollamaSettings = service.getRecommendedSettings('ollama', isAndroid: true);
      expect(ollamaSettings['serverUrl'], equals('http://10.0.2.2:11434'));
    });

    test('should provide connection summary', () {
      final summary = service.getConnectionSummary();

      expect(summary['isConnected'], isFalse);
      expect(summary['modelCount'], equals(0));
      expect(summary['availableModels'], isEmpty);
    });

    test('should provide auto-config summary', () {
      final summary = service.getAutoConfigSummary();

      expect(summary['isAutoConfiguring'], isFalse);
      expect(summary['hasAutoConfig'], isFalse);
    });

    test('should check if service is ready', () {
      expect(service.isReady, isFalse);
    });

    test('should get current config', () {
      expect(service.currentConfig, isNull);
    });
  });

  group('LLMConfigService Unit Tests', () {
    test('should validate configuration', () {
      final config = LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      final validation = LLMConfigService.validateConfig(config);
      expect(validation['isValid'], isTrue);
      expect(validation['errors'], isEmpty);
    });

    test('should get recommended settings', () {
      final settings = LLMConfigService.getRecommendedSettings('ollama');
      expect(settings['serverUrl'], equals('http://localhost:11434'));
      expect(settings['description'], contains('Ollama'));
    });

    test('should create default config', () {
      final config = LLMConfigService.createDefaultConfig('ollama');
      expect(config.provider, equals('ollama'));
      expect(config.serverUrl, equals('http://localhost:11434'));
    });
  });

  group('TextProcessor Unit Tests', () {
    test('should clean simple translation text', () {
      final cleaned = TextProcessor.cleanTranslationResult(
        'Translation: Hello world',
        'en',
      );
      expect(cleaned, equals('Hello world'));
    });

    test('should remove thinking tags', () {
      final cleaned = TextProcessor.cleanTranslationResult(
        '<thinking>Let me translate this</thinking>Hello world',
        'en',
      );
      expect(cleaned, equals('Hello world'));
    });

    test('should handle empty input', () {
      final cleaned = TextProcessor.cleanTranslationResult('', 'en');
      expect(cleaned, equals(''));
    });

    test('should handle whitespace', () {
      final cleaned = TextProcessor.cleanTranslationResult('  Hello world  ', 'en');
      expect(cleaned, equals('Hello world'));
    });

    test('should remove common prefixes', () {
      final cleaned = TextProcessor.cleanTranslationResult(
        'Here is the translation: Hello world',
        'en',
      );
      expect(cleaned, equals('Hello world'));
    });
  });
}