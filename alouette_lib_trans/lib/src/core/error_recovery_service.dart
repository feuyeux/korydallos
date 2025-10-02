import 'dart:async';
import 'dart:math';
import '../exceptions/translation_exceptions.dart';

/// Service for handling error recovery strategies in translation operations
class TranslationErrorRecoveryService {
  static const int _maxRetryAttempts = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 1);
  static const Duration _maxRetryDelay = Duration(seconds: 30);

  /// Retry a translation operation with exponential backoff
  static Future<T> retryWithBackoff<T>(
    Future<T> Function() operation, {
    int maxAttempts = _maxRetryAttempts,
    Duration baseDelay = _baseRetryDelay,
    Duration maxDelay = _maxRetryDelay,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempt = 0;
    dynamic lastError;

    while (attempt < maxAttempts) {
      try {
        return await operation();
      } catch (error) {
        lastError = error;
        attempt++;

        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(error)) {
          rethrow;
        }

        // Check if this is a recoverable Alouette error
        if (error is AlouetteTranslationError && !error.isRecoverable) {
          rethrow;
        }

        // If this was the last attempt, rethrow the error
        if (attempt >= maxAttempts) {
          rethrow;
        }

        // Calculate delay with exponential backoff and jitter
        final delay = _calculateDelay(attempt, baseDelay, maxDelay);
        await Future.delayed(delay);
      }
    }

    // This should never be reached, but just in case
    throw lastError ?? Exception('Unknown error during retry operation');
  }

  /// Calculate delay with exponential backoff and jitter
  static Duration _calculateDelay(
    int attempt,
    Duration baseDelay,
    Duration maxDelay,
  ) {
    // Exponential backoff: baseDelay * 2^(attempt-1)
    final exponentialDelay = baseDelay * pow(2, attempt - 1);

    // Add jitter (random factor between 0.5 and 1.5)
    final jitter = 0.5 + Random().nextDouble();
    final delayWithJitter = Duration(
      milliseconds: (exponentialDelay.inMilliseconds * jitter).round(),
    );

    // Cap at maximum delay
    return delayWithJitter > maxDelay ? maxDelay : delayWithJitter;
  }

  /// Determine if an error should be retried
  static bool shouldRetryError(dynamic error) {
    if (error is AlouetteTranslationError) {
      return error.isRecoverable;
    }

    // For non-Alouette errors, check common patterns
    if (error is TimeoutException) return true;

    final errorString = error.toString().toLowerCase();

    // Network-related errors that might be temporary
    if (errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('dns')) {
      return true;
    }

    // Server errors that might be temporary (5xx status codes)
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504')) {
      return true;
    }

    return false;
  }

  /// Create a circuit breaker for translation operations
  static CircuitBreaker createCircuitBreaker({
    int failureThreshold = 5,
    Duration timeout = const Duration(seconds: 30),
    Duration resetTimeout = const Duration(minutes: 1),
  }) {
    return CircuitBreaker(
      failureThreshold: failureThreshold,
      timeout: timeout,
      resetTimeout: resetTimeout,
    );
  }

  /// Recover from specific translation errors
  static Future<T> recoverFromError<T>(
    dynamic error,
    Future<T> Function() fallbackOperation,
  ) async {
    if (error is AlouetteTranslationError) {
      switch (error.code) {
        case TranslationErrorCodes.connectionFailed:
        case TranslationErrorCodes.requestTimeout:
        case TranslationErrorCodes.networkError:
          // For network errors, try the fallback after a short delay
          await Future.delayed(const Duration(seconds: 2));
          return await fallbackOperation();

        case TranslationErrorCodes.modelNotFound:
          // For model errors, the fallback should use a different model
          return await fallbackOperation();

        case TranslationErrorCodes.rateLimitExceeded:
          // For rate limits, wait longer before fallback
          await Future.delayed(const Duration(seconds: 10));
          return await fallbackOperation();

        default:
          throw error;
      }
    }

    throw error;
  }
}

/// Circuit breaker pattern implementation for translation services
class CircuitBreaker {
  final int failureThreshold;
  final Duration timeout;
  final Duration resetTimeout;

  int _failureCount = 0;
  DateTime? _lastFailureTime;
  CircuitBreakerState _state = CircuitBreakerState.closed;

  CircuitBreaker({
    required this.failureThreshold,
    required this.timeout,
    required this.resetTimeout,
  });

  /// Execute an operation through the circuit breaker
  Future<T> execute<T>(Future<T> Function() operation) async {
    if (_state == CircuitBreakerState.open) {
      if (_shouldAttemptReset()) {
        _state = CircuitBreakerState.halfOpen;
      } else {
        throw CircuitBreakerOpenException(
          'Circuit breaker is open. Last failure: $_lastFailureTime',
        );
      }
    }

    try {
      final result = await operation().timeout(timeout);
      _onSuccess();
      return result;
    } catch (error) {
      _onFailure();
      rethrow;
    }
  }

  bool _shouldAttemptReset() {
    if (_lastFailureTime == null) return false;
    return DateTime.now().difference(_lastFailureTime!) > resetTimeout;
  }

  void _onSuccess() {
    _failureCount = 0;
    _state = CircuitBreakerState.closed;
  }

  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= failureThreshold) {
      _state = CircuitBreakerState.open;
    }
  }

  /// Get current circuit breaker state
  CircuitBreakerState get state => _state;

  /// Get current failure count
  int get failureCount => _failureCount;

  /// Reset the circuit breaker
  void reset() {
    _failureCount = 0;
    _lastFailureTime = null;
    _state = CircuitBreakerState.closed;
  }
}

/// Circuit breaker states
enum CircuitBreakerState {
  closed, // Normal operation
  open, // Failing fast
  halfOpen, // Testing if service is back
}

/// Exception thrown when circuit breaker is open
class CircuitBreakerOpenException extends AlouetteTranslationError {
  CircuitBreakerOpenException(String message)
    : super(message, 'CIRCUIT_BREAKER_OPEN');
}

/// Fallback provider interface for translation operations
abstract class TranslationFallbackProvider {
  Future<String> translateText(String text, String targetLanguage);
  bool get isAvailable;
  String get providerName;
}

/// Cached translation fallback provider
class CachedTranslationFallbackProvider implements TranslationFallbackProvider {
  final Map<String, String> _cache = {};

  @override
  Future<String> translateText(String text, String targetLanguage) async {
    final key = '${text.hashCode}_$targetLanguage';
    return _cache[key] ?? '[No cached translation available]';
  }

  @override
  bool get isAvailable => _cache.isNotEmpty;

  @override
  String get providerName => 'Cache';

  /// Add a translation to the cache
  void addToCache(String text, String targetLanguage, String translation) {
    final key = '${text.hashCode}_$targetLanguage';
    _cache[key] = translation;
  }

  /// Clear the cache
  void clearCache() {
    _cache.clear();
  }
}
