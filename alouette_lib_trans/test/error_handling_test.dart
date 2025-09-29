import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'mocks/mock_translation_provider.dart';
import 'dart:io';
import 'dart:async';

void main() {
  group('Translation Error Handling Tests', () {
    late TranslationService service;
    late MockTranslationProvider mockProvider;

    setUp(() {
      mockProvider = MockTranslationProvider();
      service = TranslationService(providers: {
        'mock': mockProvider,
      });
    });

    test('should handle network connection errors', () async {
      // Arrange
      final config = LLMConfig(
        provider: 'mock',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      mockProvider.setMockError(
        SocketException('Connection refused'),
      );

      // Act & Assert
      expect(
        () async => await service.translateText('Hello', ['es'], config),
        throwsA(isA<LLMConnectionException>()),
      );
    });

    test('should handle timeout errors', () async {
      // Arrange
      final config = LLMConfig(
        provider: 'mock',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      mockProvider.setMockError(
        TimeoutException('Request timeout', Duration(seconds: 30)),
      );

      // Act & Assert
      expect(
        () async => await service.translateText('Hello', ['es'], config),
        throwsA(isA<TranslationTimeoutException>()),
      );
    });

    test('should handle authentication errors', () async {
      // Arrange
      final config = LLMConfig(
        provider: 'mock',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      mockProvider.setMockError(
        LLMAuthenticationException('Invalid API key'),
      );

      // Act & Assert
      expect(
        () async => await service.translateText('Hello', ['es'], config),
        throwsA(isA<LLMAuthenticationException>()),
      );
    });

    test('should handle model not found errors', () async {
      // Arrange
      final config = LLMConfig(
        provider: 'mock',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'nonexistent-model',
      );

      mockProvider.setMockError(
        LLMModelNotFoundException('Model not found', 'nonexistent-model'),
      );

      // Act & Assert
      expect(
        () async => await service.translateText('Hello', ['es'], config),
        throwsA(isA<LLMModelNotFoundException>()),
      );
    });

    test('should handle rate limit errors', () async {
      // Arrange
      final config = LLMConfig(
        provider: 'mock',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      mockProvider.setMockError(
        RateLimitException('Rate limit exceeded'),
      );

      // Act & Assert
      expect(
        () async => await service.translateText('Hello', ['es'], config),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('should handle invalid translation results', () async {
      // Arrange
      final config = LLMConfig(
        provider: 'mock',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      mockProvider.setMockTranslation(''); // Empty translation

      // Act & Assert
      expect(
        () async => await service.translateText('Hello', ['es'], config),
        throwsA(isA<InvalidTranslationException>()),
      );
    });

    test('should handle configuration validation errors', () async {
      // Arrange
      final invalidConfig = LLMConfig(
        provider: 'mock',
        serverUrl: '', // Invalid empty URL
        selectedModel: 'test-model',
      );

      // Act & Assert
      expect(
        () async => await service.translateText('Hello', ['es'], invalidConfig),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('should retry on transient failures', () async {
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

    test('should not retry when retry is disabled', () async {
      // Arrange
      final config = LLMConfig(
        provider: 'mock',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      mockProvider.setMockError(TranslationException('Transient error'));

      // Act & Assert
      expect(
        () async => await service.translateText(
          'Hello world',
          ['es'],
          config,
          enableRetry: false,
        ),
        throwsA(isA<TranslationException>()),
      );
      expect(mockProvider.attemptCount, equals(1)); // Only one attempt
    });

    test('should handle partial failures in multi-language translation', () async {
      // Arrange
      final config = LLMConfig(
        provider: 'mock',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      // Set up provider to fail for French but succeed for Spanish and German
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
      
      // Check metadata for error information
      expect(result.metadata?['failedLanguages'], contains('fr'));
      expect(result.metadata?['errors'], isA<Map>());
    });

    test('should fail completely when all languages fail', () async {
      // Arrange
      final config = LLMConfig(
        provider: 'mock',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      // Set up provider to fail for all languages
      mockProvider.setMockError(TranslationException('All translations failed'));

      // Act & Assert
      expect(
        () async => await service.translateText(
          'Hello world',
          ['es', 'fr', 'de'],
          config,
        ),
        throwsA(isA<TranslationException>()),
      );
    });

    test('should handle connection test failures gracefully', () async {
      // Arrange
      final config = LLMConfig(
        provider: 'mock',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      mockProvider.setMockError(SocketException('Connection refused'));

      // Act
      final status = await service.testConnection(config);

      // Assert
      expect(status.success, isFalse);
      expect(status.message, contains('Connection test failed'));
      expect(service.availableModels, isEmpty);
    });

    test('should handle model fetching failures during connection test', () async {
      // Arrange
      final config = LLMConfig(
        provider: 'mock',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      // Connection succeeds but model fetching fails
      mockProvider.setMockConnectionStatus(ConnectionStatus.success(
        message: 'Connected successfully',
      ));
      mockProvider.setMockError(TranslationException('Failed to fetch models'));

      // Act
      final status = await service.testConnection(config);

      // Assert
      expect(status.success, isTrue); // Connection test should still succeed
      expect(service.availableModels, isEmpty); // But models should be empty
    });

    test('should provide detailed error information', () async {
      // Arrange
      final config = LLMConfig(
        provider: 'mock',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'test-model',
      );

      final originalError = SocketException('Connection refused');
      mockProvider.setMockError(originalError);

      // Act & Assert
      try {
        await service.translateText('Hello', ['es'], config);
        fail('Expected exception to be thrown');
      } catch (e) {
        expect(e, isA<LLMConnectionException>());
        final connectionError = e as LLMConnectionException;
        expect(connectionError.code, equals('CONNECTION_REFUSED'));
        expect(connectionError.details?['provider'], equals('mock'));
        expect(connectionError.details?['serverUrl'], equals('http://localhost:11434'));
      }
    });

    test('should handle auto-configuration failures', () async {
      // Arrange - No working configurations available
      mockProvider.setMockConnectionStatus(ConnectionStatus.failure(
        message: 'No server available',
      ));

      // Act
      final config = await service.autoConfigureLLM();

      // Assert
      expect(config, isNull);
    });

    test('should handle auto-configuration with retry', () async {
      // Arrange - Fail first attempts, succeed on retry
      var attemptCount = 0;
      mockProvider.setMockConnectionStatus(ConnectionStatus.failure(
        message: 'Server temporarily unavailable',
      ));

      // Override the connection test to succeed after 2 attempts
      service.registerProvider('mock', MockTranslationProviderWithRetry());

      // Act
      final config = await service.autoConfigureLLM(
        enableRetry: true,
        maxRetries: 3,
        retryDelay: Duration(milliseconds: 10),
      );

      // Assert - Should eventually succeed
      expect(config, isNotNull);
    });
  });

  group('Exception Handling Utility Tests', () {
    late TranslationService service;

    setUp(() {
      service = TranslationService();
    });

    test('should convert SocketException to LLMConnectionException', () {
      // Arrange
      final socketError = SocketException('Connection refused');

      // Act
      final convertedException = service.handleException(
        socketError,
        'ollama',
        'http://localhost:11434',
      );

      // Assert
      expect(convertedException, isA<LLMConnectionException>());
      final connectionError = convertedException as LLMConnectionException;
      expect(connectionError.message, contains('Cannot connect to ollama server'));
      expect(connectionError.code, equals('CONNECTION_REFUSED'));
    });

    test('should convert TimeoutException to TranslationTimeoutException', () {
      // Arrange
      final timeoutError = TimeoutException('Request timeout', Duration(seconds: 30));

      // Act
      final convertedException = service.handleException(
        timeoutError,
        'ollama',
        'http://localhost:11434',
      );

      // Assert
      expect(convertedException, isA<TranslationTimeoutException>());
      final timeoutException = convertedException as TranslationTimeoutException;
      expect(timeoutException.timeout, equals(Duration(seconds: 30)));
    });

    test('should convert FormatException to TranslationException', () {
      // Arrange
      final formatError = FormatException('Invalid JSON');

      // Act
      final convertedException = service.handleException(
        formatError,
        'ollama',
        'http://localhost:11434',
      );

      // Assert
      expect(convertedException, isA<TranslationException>());
      final translationError = convertedException as TranslationException;
      expect(translationError.code, equals('INVALID_RESPONSE_FORMAT'));
    });

    test('should create HTTP-specific exceptions', () {
      // Test 401 Unauthorized
      var httpException = service.createHttpException(
        401,
        'Unauthorized',
        'ollama',
      );
      expect(httpException, isA<LLMAuthenticationException>());

      // Test 404 Not Found
      httpException = service.createHttpException(
        404,
        'Model not found',
        'ollama',
      );
      expect(httpException, isA<LLMModelNotFoundException>());

      // Test 429 Rate Limited
      httpException = service.createHttpException(
        429,
        'Rate limit exceeded',
        'ollama',
      );
      expect(httpException, isA<RateLimitException>());

      // Test 500 Server Error
      httpException = service.createHttpException(
        500,
        'Internal server error',
        'ollama',
      );
      expect(httpException, isA<TranslationException>());
      final serverError = httpException as TranslationException;
      expect(serverError.code, equals('SERVER_ERROR'));
    });
  });
}

/// Mock provider that succeeds after a few attempts (for retry testing)
class MockTranslationProviderWithRetry extends MockTranslationProvider {
  int _connectionAttempts = 0;

  @override
  Future<ConnectionStatus> testConnection(LLMConfig config) async {
    _connectionAttempts++;
    
    if (_connectionAttempts < 3) {
      return ConnectionStatus.failure(
        message: 'Server temporarily unavailable (attempt $_connectionAttempts)',
      );
    }
    
    return ConnectionStatus.success(
      message: 'Connected successfully after $_connectionAttempts attempts',
      responseTimeMs: 100,
    );
  }

  @override
  Future<List<String>> getAvailableModels(LLMConfig config) async {
    return ['qwen2.5:latest', 'llama3.2:latest'];
  }
}