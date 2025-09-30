import 'dart:async';
import '../exceptions/translation_exceptions.dart';
import '../models/translation_request.dart';
import '../models/translation_result.dart';
import '../models/llm_config.dart';
import 'error_recovery_service.dart';

/// Enhanced translation service with comprehensive error handling
class TranslationServiceWithErrorHandling {
  final TranslationService _baseService;
  final CircuitBreaker _circuitBreaker;
  final CachedTranslationFallbackProvider _fallbackProvider;

  TranslationServiceWithErrorHandling(this._baseService)
    : _circuitBreaker = TranslationErrorRecoveryService.createCircuitBreaker(),
      _fallbackProvider = CachedTranslationFallbackProvider();

  /// Translate text with comprehensive error handling and recovery
  Future<TranslationResult> translateText(TranslationRequest request) async {
    try {
      // Execute through circuit breaker with retry logic
      return await TranslationErrorRecoveryService.retryWithBackoff(
        () =>
            _circuitBreaker.execute(() => _baseService.translateText(request)),
        shouldRetry: TranslationErrorRecoveryService.shouldRetryError,
      );
    } catch (error) {
      // Attempt error recovery
      try {
        return await TranslationErrorRecoveryService.recoverFromError(
          error,
          () => _fallbackTranslation(request),
        );
      } catch (recoveryError) {
        // If recovery fails, enhance the original error with context
        if (error is AlouetteTranslationError) {
          throw error;
        } else {
          throw TranslationException(
            'Translation failed: ${error.toString()}',
            details: {
              'originalRequest': request.toJson(),
              'recoveryAttempted': true,
              'recoveryError': recoveryError.toString(),
            },
            originalError: error,
          );
        }
      }
    }
  }

  /// Translate to multiple languages with error handling per language
  Future<Map<String, TranslationResult>> translateToMultipleLanguages(
    String text,
    List<String> targetLanguages,
  ) async {
    final results = <String, TranslationResult>{};
    final errors = <String, dynamic>{};

    // Process each language independently
    await Future.wait(
      targetLanguages.map((language) async {
        try {
          final request = TranslationRequest(
            text: text,
            targetLanguages: [language],
            provider: 'ollama',
            serverUrl: 'http://localhost:11434',
            modelName: 'llama2',
            sourceLanguage: 'auto',
          );

          final result = await translateText(request);
          results[language] = result;
        } catch (error) {
          errors[language] = error;

          // Try to get cached translation as fallback
          try {
            final cachedTranslation = await _fallbackProvider.translateText(
              text,
              language,
            );
            results[language] = TranslationResult(
              original: text,
              translations: {language: cachedTranslation},
              languages: [language],
              timestamp: DateTime.now(),
              config: LLMConfig(
                provider: 'cache',
                serverUrl: '',
                selectedModel: 'fallback',
              ),
              isSuccessful: false,
              metadata: {'source': 'cache', 'error': error.toString()},
            );
          } catch (cacheError) {
            // Create error result
            results[language] = TranslationResult(
              original: text,
              translations: {language: '[Translation failed]'},
              languages: [language],
              timestamp: DateTime.now(),
              config: LLMConfig(
                provider: 'error',
                serverUrl: '',
                selectedModel: 'fallback',
              ),
              isSuccessful: false,
              metadata: {'error': error.toString()},
            );
          }
        }
      }),
    );

    // If all translations failed, throw a comprehensive error
    if (results.isEmpty || results.values.every((r) => !r.isSuccessful)) {
      throw TranslationException(
        'All translations failed',
        code: TranslationErrorCodes.invalidTranslation,
        details: {'targetLanguages': targetLanguages, 'errors': errors},
      );
    }

    return results;
  }

  /// Get available models with error handling
  Future<List<String>> getAvailableModels() async {
    try {
      return await TranslationErrorRecoveryService.retryWithBackoff(
        () => _circuitBreaker.execute(() => _baseService.getAvailableModels()),
        shouldRetry: TranslationErrorRecoveryService.shouldRetryError,
      );
    } catch (error) {
      // Return cached models if available
      final cachedModels = _getCachedModels();
      if (cachedModels.isNotEmpty) {
        return cachedModels;
      }

      // Enhance error with context
      if (error is AlouetteTranslationError) {
        throw error;
      } else {
        throw LLMConnectionException(
          'Failed to get available models: ${error.toString()}',
          originalError: error,
        );
      }
    }
  }

  /// Test connection with comprehensive error reporting
  Future<bool> testConnection() async {
    try {
      await _circuitBreaker.execute(() => _baseService.testConnection());
      return true;
    } catch (error) {
      // Log the specific connection error
      if (error is LLMConnectionException) {
        throw error;
      } else if (error is TimeoutException) {
        throw TranslationTimeoutException(
          'Connection test timed out',
          timeout: const Duration(seconds: 10),
          originalError: error,
        );
      } else {
        throw LLMConnectionException(
          'Connection test failed: ${error.toString()}',
          originalError: error,
        );
      }
    }
  }

  /// Add translation to cache for fallback purposes
  void cacheTranslation(
    String text,
    String targetLanguage,
    String translation,
  ) {
    _fallbackProvider.addToCache(text, targetLanguage, translation);
  }

  /// Get circuit breaker status for monitoring
  CircuitBreakerState get circuitBreakerState => _circuitBreaker.state;

  /// Get failure count for monitoring
  int get failureCount => _circuitBreaker.failureCount;

  /// Reset circuit breaker
  void resetCircuitBreaker() {
    _circuitBreaker.reset();
  }

  /// Dispose resources
  void dispose() {
    _fallbackProvider.clearCache();
    _circuitBreaker.reset();
  }

  Future<TranslationResult> _fallbackTranslation(
    TranslationRequest request,
  ) async {
    final fallbackTranslations = <String, String>{};

    for (final language in request.targetLanguages) {
      final fallbackText = await _fallbackProvider.translateText(
        request.text,
        language,
      );
      fallbackTranslations[language] = fallbackText;
    }

    return TranslationResult(
      original: request.text,
      translations: fallbackTranslations,
      languages: request.targetLanguages,
      timestamp: DateTime.now(),
      config: LLMConfig(
        provider: request.provider,
        serverUrl: request.serverUrl,
        selectedModel: request.modelName,
      ),
      isSuccessful: false,
      metadata: {'source': 'fallback'},
    );
  }

  List<String> _getCachedModels() {
    // Return a basic set of commonly available models
    return ['llama2', 'mistral', 'codellama'];
  }
}

/// Mock base translation service interface for the example
abstract class TranslationService {
  Future<TranslationResult> translateText(TranslationRequest request);
  Future<List<String>> getAvailableModels();
  Future<void> testConnection();
}
