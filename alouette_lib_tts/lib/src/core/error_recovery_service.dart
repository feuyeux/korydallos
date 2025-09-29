import 'dart:async';
import 'dart:math';
import '../exceptions/tts_exceptions.dart';
import '../enums/tts_engine_type.dart';

/// Service for handling error recovery strategies in TTS operations
class TTSErrorRecoveryService {
  static const int _maxRetryAttempts = 3;
  static const Duration _baseRetryDelay = Duration(milliseconds: 500);
  static const Duration _maxRetryDelay = Duration(seconds: 10);

  /// Retry a TTS operation with exponential backoff
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

        // Check if this is a recoverable Alouette TTS error
        if (error is AlouetteTTSError && !error.isRecoverable) {
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
    throw lastError ?? Exception('Unknown error during TTS retry operation');
  }

  /// Calculate delay with exponential backoff and jitter
  static Duration _calculateDelay(int attempt, Duration baseDelay, Duration maxDelay) {
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

  /// Determine if a TTS error should be retried
  static bool shouldRetryError(dynamic error) {
    if (error is AlouetteTTSError) {
      return error.isRecoverable;
    }

    // For non-Alouette errors, check common patterns
    if (error is TimeoutException) return true;
    
    final errorString = error.toString().toLowerCase();
    
    // TTS-specific errors that might be temporary
    if (errorString.contains('synthesis') ||
        errorString.contains('audio') ||
        errorString.contains('playback') ||
        errorString.contains('engine') ||
        errorString.contains('voice')) {
      return true;
    }
    
    // Network-related errors for cloud TTS
    if (errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('network')) {
      return true;
    }
    
    return false;
  }

  /// Engine fallback chain for different platforms
  static List<TTSEngineType> getEngineFallbackChain(TTSEngineType primaryEngine) {
    switch (primaryEngine) {
      case TTSEngineType.edge:
        return [TTSEngineType.edge, TTSEngineType.flutter];
      case TTSEngineType.flutter:
        return [TTSEngineType.flutter, TTSEngineType.edge];
      default:
        return [TTSEngineType.flutter, TTSEngineType.edge];
    }
  }

  /// Attempt to recover from TTS errors by switching engines
  static Future<T> recoverWithEngineFallback<T>(
    dynamic error,
    TTSEngineType currentEngine,
    Future<T> Function(TTSEngineType engine) operationWithEngine,
  ) async {
    if (error is AlouetteTTSError) {
      switch (error.code) {
        case TTSErrorCodes.engineNotAvailable:
        case TTSErrorCodes.synthesisFailure:
        case TTSErrorCodes.audioPlaybackError:
          // Try fallback engines
          final fallbackChain = getEngineFallbackChain(currentEngine);
          
          for (int i = 1; i < fallbackChain.length; i++) {
            final fallbackEngine = fallbackChain[i];
            try {
              return await operationWithEngine(fallbackEngine);
            } catch (fallbackError) {
              // Continue to next fallback
              continue;
            }
          }
          
          // If all fallbacks failed, throw original error
          throw error;
          
        case TTSErrorCodes.voiceNotFound:
          // For voice errors, try with default voice
          return await operationWithEngine(currentEngine);
          
        case TTSErrorCodes.networkError:
          // For network errors, wait and retry with same engine
          await Future.delayed(const Duration(seconds: 2));
          return await operationWithEngine(currentEngine);
          
        default:
          throw error;
      }
    }
    
    throw error;
  }

  /// Create a TTS-specific circuit breaker
  static TTSCircuitBreaker createCircuitBreaker({
    int failureThreshold = 3,
    Duration timeout = const Duration(seconds: 15),
    Duration resetTimeout = const Duration(seconds: 30),
  }) {
    return TTSCircuitBreaker(
      failureThreshold: failureThreshold,
      timeout: timeout,
      resetTimeout: resetTimeout,
    );
  }
}

/// TTS-specific circuit breaker implementation
class TTSCircuitBreaker {
  final int failureThreshold;
  final Duration timeout;
  final Duration resetTimeout;
  
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  TTSCircuitBreakerState _state = TTSCircuitBreakerState.closed;
  TTSEngineType? _lastFailedEngine;

  TTSCircuitBreaker({
    required this.failureThreshold,
    required this.timeout,
    required this.resetTimeout,
  });

  /// Execute a TTS operation through the circuit breaker
  Future<T> execute<T>(
    Future<T> Function() operation,
    TTSEngineType engine,
  ) async {
    if (_state == TTSCircuitBreakerState.open) {
      if (_shouldAttemptReset()) {
        _state = TTSCircuitBreakerState.halfOpen;
      } else {
        throw TTSCircuitBreakerOpenException(
          'TTS circuit breaker is open for engine $engine. Last failure: $_lastFailureTime',
          engine,
        );
      }
    }

    try {
      final result = await operation().timeout(timeout);
      _onSuccess();
      return result;
    } catch (error) {
      _onFailure(engine);
      rethrow;
    }
  }

  bool _shouldAttemptReset() {
    if (_lastFailureTime == null) return false;
    return DateTime.now().difference(_lastFailureTime!) > resetTimeout;
  }

  void _onSuccess() {
    _failureCount = 0;
    _state = TTSCircuitBreakerState.closed;
    _lastFailedEngine = null;
  }

  void _onFailure(TTSEngineType engine) {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    _lastFailedEngine = engine;
    
    if (_failureCount >= failureThreshold) {
      _state = TTSCircuitBreakerState.open;
    }
  }

  /// Get current circuit breaker state
  TTSCircuitBreakerState get state => _state;
  
  /// Get current failure count
  int get failureCount => _failureCount;
  
  /// Get last failed engine
  TTSEngineType? get lastFailedEngine => _lastFailedEngine;
  
  /// Reset the circuit breaker
  void reset() {
    _failureCount = 0;
    _lastFailureTime = null;
    _state = TTSCircuitBreakerState.closed;
    _lastFailedEngine = null;
  }
}

/// TTS circuit breaker states
enum TTSCircuitBreakerState {
  closed,   // Normal operation
  open,     // Failing fast
  halfOpen, // Testing if service is back
}

/// Exception thrown when TTS circuit breaker is open
class TTSCircuitBreakerOpenException extends AlouetteTTSError {
  final TTSEngineType engine;

  TTSCircuitBreakerOpenException(String message, this.engine) : super(
    message,
    TTSErrorCodes.engineNotAvailable,
    details: {'engine': engine.toString()},
  );
}

/// Voice fallback strategy for when preferred voice is not available
class VoiceFallbackStrategy {
  /// Get fallback voices for a given language
  static List<String> getFallbackVoices(String languageCode, List<String> availableVoices) {
    final fallbacks = <String>[];
    
    // First, try to find voices that match the exact language code
    final exactMatches = availableVoices.where((voice) => 
      voice.toLowerCase().contains(languageCode.toLowerCase())
    ).toList();
    fallbacks.addAll(exactMatches);
    
    // Then, try to find voices that match the language family (e.g., 'en' for 'en-US')
    if (languageCode.contains('-')) {
      final languageFamily = languageCode.split('-')[0];
      final familyMatches = availableVoices.where((voice) => 
        voice.toLowerCase().contains(languageFamily.toLowerCase()) &&
        !fallbacks.contains(voice)
      ).toList();
      fallbacks.addAll(familyMatches);
    }
    
    // Finally, add any remaining voices as last resort
    final remaining = availableVoices.where((voice) => !fallbacks.contains(voice)).toList();
    fallbacks.addAll(remaining);
    
    return fallbacks;
  }
  
  /// Get default voice for a language if no specific voice is requested
  static String? getDefaultVoice(String languageCode, List<String> availableVoices) {
    final fallbacks = getFallbackVoices(languageCode, availableVoices);
    return fallbacks.isNotEmpty ? fallbacks.first : null;
  }
}

/// TTS operation timeout handler
class TTSTimeoutHandler {
  static const Duration _defaultSynthesisTimeout = Duration(seconds: 30);
  static const Duration _defaultPlaybackTimeout = Duration(seconds: 60);
  
  /// Execute synthesis with timeout and fallback
  static Future<T> executeSynthesisWithTimeout<T>(
    Future<T> Function() operation, {
    Duration? timeout,
    Future<T> Function()? fallbackOperation,
  }) async {
    final actualTimeout = timeout ?? _defaultSynthesisTimeout;
    
    try {
      return await operation().timeout(actualTimeout);
    } on TimeoutException catch (e) {
      if (fallbackOperation != null) {
        try {
          return await fallbackOperation().timeout(actualTimeout);
        } catch (fallbackError) {
          throw TTSSynthesisException(
            'Synthesis timed out and fallback failed',
            'timeout_text',
            details: {
              'timeoutSeconds': actualTimeout.inSeconds,
              'fallbackError': fallbackError.toString(),
            },
            originalError: e,
          );
        }
      } else {
        throw TTSSynthesisException(
          'Synthesis operation timed out',
          'timeout_text',
          details: {'timeoutSeconds': actualTimeout.inSeconds},
          originalError: e,
        );
      }
    }
  }
  
  /// Execute playback with timeout
  static Future<T> executePlaybackWithTimeout<T>(
    Future<T> Function() operation, {
    Duration? timeout,
  }) async {
    final actualTimeout = timeout ?? _defaultPlaybackTimeout;
    
    try {
      return await operation().timeout(actualTimeout);
    } on TimeoutException catch (e) {
      throw TTSAudioPlaybackException(
        'Audio playback timed out',
        details: {'timeoutSeconds': actualTimeout.inSeconds},
        originalError: e,
      );
    }
  }
}