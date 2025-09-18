import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'mocks/mock_translation_provider.dart';

void main() {
  group('TranslationService', () {
    late TranslationService service;
    late MockTranslationProvider mockProvider;

    setUp(() {
      mockProvider = MockTranslationProvider();
      service = TranslationService(providers: {
        'mock': mockProvider,
        'ollama': MockTranslationProvider(),
        'lmstudio': MockTranslationProvider(),
      });
    });

    test('should initialize with default providers', () {
      expect(service.availableProviders, contains('ollama'));
      expect(service.availableProviders, contains('lmstudio'));
      expect(service.availableProviders, contains('mock'));
    });

    test('should support provider checking', () {
      expect(service.isProviderSupported('ollama'), isTrue);
      expect(service.isProviderSupported('lmstudio'), isTrue);
      expect(service.isProviderSupported('mock'), isTrue);
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

    test('should translate text successfully with mocked provider', () async {
      // Arrange
      final config = LLMConfig(
        provider: 'mock',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      mockProvider.setMockTranslation('Hola mundo');

      // Act
      final result = await service.translateText(
        'Hello world',
        ['es'],
        config,
      );

      // Assert
      expect(result.original, equals('Hello world'));
      expect(result.translations['es'], equals('Hola mundo'));
      expect(result.isComplete, isTrue);
      expect(service.currentTranslation, equals(result));
    });

    test('should handle multiple target languages', () async {
      // Arrange
      final config = LLMConfig(
        provider: 'mock',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      mockProvider.setMockTranslations({
        'es': 'Hola mundo',
        'fr': 'Bonjour le monde',
        'de': 'Hallo Welt',
      });

      // Act
      final result = await service.translateText(
        'Hello world',
        ['es', 'fr', 'de'],
        config,
      );

      // Assert
      expect(result.translations.length, equals(3));
      expect(result.translations['es'], equals('Hola mundo'));
      expect(result.translations['fr'], equals('Bonjour le monde'));
      expect(result.translations['de'], equals('Hallo Welt'));
    });

    test('should handle translation errors gracefully', () async {
      // Arrange
      final config = LLMConfig(
        provider: 'mock',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      mockProvider.setMockError(TranslationException('Mock error'));

      // Act & Assert
      expect(
        () async => await service.translateText('Hello', ['es'], config),
        throwsA(isA<TranslationException>()),
      );
    });

    test('should handle connection test successfully', () async {
      // Arrange
      final config = LLMConfig(
        provider: 'mock',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      mockProvider.setMockConnectionStatus(ConnectionStatus.success(
        message: 'Connected successfully',
        responseTimeMs: 100,
      ));
      mockProvider.setMockModels(['model1', 'model2', 'model3']);

      // Act
      final status = await service.testConnection(config);

      // Assert
      expect(status.success, isTrue);
      expect(status.message, equals('Connected successfully'));
      expect(service.availableModels, equals(['model1', 'model2', 'model3']));
    });

    test('should handle connection test failure', () async {
      // Arrange
      final config = LLMConfig(
        provider: 'mock',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      mockProvider.setMockConnectionStatus(ConnectionStatus.failure(
        message: 'Connection failed',
      ));

      // Act
      final status = await service.testConnection(config);

      // Assert
      expect(status.success, isFalse);
      expect(status.message, equals('Connection failed'));
      expect(service.availableModels, isEmpty);
    });

    test('should handle unsupported provider error', () async {
      // Arrange
      final config = LLMConfig(
        provider: 'unsupported',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      // Act & Assert
      expect(
        () async => await service.translateText('Hello', ['es'], config),
        throwsA(isA<UnsupportedProviderException>()),
      );
    });

    test('should validate translation request parameters', () async {
      // Arrange
      final config = LLMConfig(
        provider: 'mock',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      // Act & Assert - Empty text
      expect(
        () async => await service.translateText('', ['es'], config),
        throwsA(isA<TranslationException>()),
      );

      // Act & Assert - Empty target languages
      expect(
        () async => await service.translateText('Hello', [], config),
        throwsA(isA<TranslationException>()),
      );
    });

    test('should clear translation and connection state', () {
      // Arrange
      service.clearTranslation();
      service.clearConnection();

      // Assert
      expect(service.currentTranslation, isNull);
      expect(service.availableModels, isEmpty);
      expect(service.connectionStatus, isNull);
    });

    test('should provide translation state information', () async {
      // Arrange
      final config = LLMConfig(
        provider: 'mock',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      mockProvider.setMockTranslation('Hola mundo');

      // Act
      await service.translateText('Hello world', ['es'], config);
      final state = service.getTranslationState();

      // Assert
      expect(state['isTranslating'], isFalse);
      expect(state['hasTranslation'], isTrue);
      expect(state['currentTranslation'], isNotNull);
    });

    test('should provide translation statistics', () async {
      // Arrange
      final config = LLMConfig(
        provider: 'mock',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      mockProvider.setMockTranslations({
        'es': 'Hola mundo',
        'fr': 'Bonjour le monde',
      });

      // Act
      await service.translateText('Hello world', ['es', 'fr'], config);
      final stats = service.getTranslationStats();

      // Assert
      expect(stats['totalTranslations'], equals(2));
      expect(stats['completedTranslations'], equals(2));
      expect(stats['completionRate'], equals(1.0));
    });

    test('should register custom provider', () {
      // Arrange
      final customProvider = MockTranslationProvider();

      // Act
      service.registerProvider('custom', customProvider);

      // Assert
      expect(service.isProviderSupported('custom'), isTrue);
      expect(service.availableProviders, contains('custom'));
    });

    test('should handle retry logic on translation failure', () async {
      // Arrange
      final config = LLMConfig(
        provider: 'mock',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      // Set up provider to fail first attempt, succeed on retry
      mockProvider.setFailFirstAttempt(true);
      mockProvider.setMockTranslation('Hola mundo');

      // Act
      final result = await service.translateText(
        'Hello world',
        ['es'],
        config,
        enableRetry: true,
      );

      // Assert
      expect(result.translations['es'], equals('Hola mundo'));
      expect(mockProvider.attemptCount, equals(2)); // Failed once, succeeded on retry
    });

    test('should handle partial translation failures', () async {
      // Arrange
      final config = LLMConfig(
        provider: 'mock',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      // Set up provider to fail for one language but succeed for others
      mockProvider.setMockTranslations({
        'es': 'Hola mundo',
        'fr': 'ERROR', // This will trigger an error
        'de': 'Hallo Welt',
      });
      mockProvider.setFailForLanguage('fr');

      // Act
      final result = await service.translateText(
        'Hello world',
        ['es', 'fr', 'de'],
        config,
      );

      // Assert
      expect(result.translations.length, equals(2)); // Only successful translations
      expect(result.translations['es'], equals('Hola mundo'));
      expect(result.translations['de'], equals('Hallo Welt'));
      expect(result.translations.containsKey('fr'), isFalse);
    });
  });

  group('LLMConfigService', () {
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

  group('TextProcessor', () {
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
  });
}