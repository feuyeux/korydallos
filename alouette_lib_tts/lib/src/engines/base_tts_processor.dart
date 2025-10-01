import 'dart:typed_data';
import '../models/voice_model.dart';
import '../models/tts_error.dart';
import '../exceptions/tts_exceptions.dart';
import '../utils/cache_manager.dart';
import '../utils/error_handler.dart';
import '../utils/tts_logger.dart';

/// Base TTS processor interface following Flutter naming conventions
/// Provides unified interface for all TTS engines
abstract class TTSProcessor {
  /// Get the engine name
  String get engineName;

  /// Get all available voices
  Future<List<VoiceModel>> getAvailableVoices();

  /// Synthesize text to audio bytes
  ///
  /// [text] Text to synthesize
  /// [voiceName] Voice name to use
  /// [format] Audio format, defaults to 'mp3'
  ///
  /// Returns audio data as bytes
  Future<Uint8List> synthesizeToAudio(
    String text,
    String voiceName, {
    String format = 'mp3',
  });

  /// Stop current TTS playback
  Future<void> stop();

  /// Set speech rate
  /// [rate] Speech rate value, typically between 0.1 and 3.0
  Future<void> setSpeechRate(double rate);

  /// Set pitch
  /// [pitch] Pitch value, typically between 0.5 and 2.0
  Future<void> setPitch(double pitch);

  /// Set volume
  /// [volume] Volume value, typically between 0.0 and 1.0
  Future<void> setVolume(double volume);

  /// Dispose resources
  void dispose();
}

/// Base implementation of TTS processor with common functionality
/// Provides caching, error handling, and validation
abstract class BaseTTSProcessor implements TTSProcessor {
  bool _disposed = false;
  late final CacheManager _cacheManager;

  BaseTTSProcessor() {
    _cacheManager = CacheManager.instance;
  }

  /// Cache manager instance
  CacheManager get cacheManager => _cacheManager;

  /// Check if processor is disposed
  bool get isDisposed => _disposed;

  /// Ensure processor is not disposed
  void ensureNotDisposed() {
    if (_disposed) {
      throw StateError('TTS processor has been disposed');
    }
  }

  /// Get voices with caching support
  Future<List<VoiceModel>> getVoicesWithCache(
    Future<List<VoiceModel>> Function() fetcher,
  ) async {
    ensureNotDisposed();

    // Check cache first
    final cachedVoices = _cacheManager.getCachedVoices(engineName);
    if (cachedVoices != null) {
      return cachedVoices;
    }

    return await ErrorHandler.wrapAsync(
      () async {
        TTSLogger.voice('Loading voices', 0, engineName);
        final voices = await fetcher();

        // Cache results
        _cacheManager.cacheVoices(engineName, voices);

        TTSLogger.voice('Loaded voices', voices.length, engineName);
        return voices;
      },
      '$engineName voice list retrieval',
      TTSErrorCodes.voiceListError,
    );
  }

  /// Synthesize text with caching support
  Future<Uint8List> synthesizeTextWithCache(
    String text,
    String voiceName,
    String format,
    Future<Uint8List> Function() synthesizer, {
    String? cacheKeySuffix,
  }) async {
    ensureNotDisposed();

    // Validate parameters
    _validateSynthesisParams(text, voiceName);

    // Check cache
    final String voiceKey = (cacheKeySuffix != null && cacheKeySuffix.isNotEmpty)
        ? '$voiceName$cacheKeySuffix'
        : voiceName;
    final cachedAudio = _cacheManager.getCachedAudio(text, voiceKey, format);
    if (cachedAudio != null) {
      TTSLogger.debug('Using cached audio data for synthesis');
      return cachedAudio;
    }

    return await ErrorHandler.wrapAsync(
      () async {
        TTSLogger.debug(
          'Starting text synthesis with $engineName for text: ${text.length} chars, voice: $voiceName, format: $format',
        );

        final audioData = await synthesizer();

        // Cache results (include parameters in cache key if provided)
        _cacheManager.cacheAudio(text, voiceKey, format, audioData);

        TTSLogger.debug(
          'Text synthesis completed successfully - ${audioData.length} bytes generated',
        );

        return audioData;
      },
      '$engineName text synthesis',
      TTSErrorCodes.synthesisError,
    );
  }

  /// Validate synthesis parameters
  void _validateSynthesisParams(String text, String voiceName) {
    if (text.trim().isEmpty) {
      throw TTSError(
        'Text cannot be empty. Please provide valid text content for synthesis.',
        code: TTSErrorCodes.emptyText,
      );
    }

    if (voiceName.trim().isEmpty) {
      throw TTSError(
        'Voice name cannot be empty. Please specify a valid voice name. '
        'Use getAvailableVoices() to see available voices.',
        code: TTSErrorCodes.emptyVoiceName,
      );
    }
  }

  @override
  void dispose() {
    TTSLogger.debug('Disposing $engineName processor');
    _disposed = true;
  }
}
