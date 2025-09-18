import 'dart:typed_data';
import '../engines/base_tts_processor.dart';
import '../models/voice_model.dart';
import '../models/tts_error.dart';
import '../enums/tts_engine_type.dart';
import '../exceptions/tts_exceptions.dart';
import '../utils/tts_logger.dart';
import '../utils/error_handler.dart';
import 'tts_engine_factory.dart';
import 'platform_detector.dart';
import 'tts_service_interface.dart';

/// Unified TTS Service - Main service interface for text-to-speech functionality
/// Provides consistent API across all TTS engines with automatic platform detection
class TTSService implements TTSServiceInterface {
  TTSProcessor? _processor;
  TTSEngineType? _currentEngine;
  bool _initialized = false;

  final TTSEngineFactory _engineFactory = TTSEngineFactory.instance;
  final PlatformDetector _platformDetector = PlatformDetector();

  /// Get current engine type
  TTSEngineType? get currentEngine => _currentEngine;

  /// Get current engine name
  String? get currentEngineName => _processor?.engineName;

  /// Get current backend name (alias for currentEngineName)
  String? get currentBackend => currentEngineName;

  /// Check if service is initialized
  bool get isInitialized => _initialized && _processor != null;

  /// Initialize TTS service with optional preferred engine
  Future<void> initialize({
    TTSEngineType? preferredEngine,
    bool autoFallback = true,
  }) async {
    if (_initialized) {
      return; // Already initialized
    }

    try {
      if (preferredEngine != null) {
        // Check if preferred engine is supported on current platform
        final strategy = _platformDetector.getTTSStrategy();
        
        if (!strategy.isEngineSupported(preferredEngine)) {
          TTSLogger.warning('Preferred engine ${preferredEngine.name} is not supported on ${_platformDetector.platformName}');
          
          if (!autoFallback) {
            throw TTSError(
              'Engine ${preferredEngine.name} is not supported on ${_platformDetector.platformName}',
              code: TTSErrorCodes.platformNotSupported,
            );
          }
          
          // Use platform-specific fallback
          _processor = await _engineFactory.createForPlatform();
          _currentEngine = _getActualEngineFromProcessor();
        } else {
          // Try to use specified engine
          try {
            _processor = await _engineFactory.createForEngine(preferredEngine);
            _currentEngine = preferredEngine;
            TTSLogger.engine('Initialized', preferredEngine.name, 'Using preferred engine');
          } catch (e) {
            TTSLogger.warning('Preferred engine ${preferredEngine.name} failed: $e');

            if (!autoFallback) {
              rethrow; // Don't fallback if not allowed
            }

            // Fallback using platform strategy
            TTSLogger.warning('Preferred engine ${preferredEngine.name} failed, using platform fallback strategy');
            _processor = await _engineFactory.createForPlatform();
            _currentEngine = _getActualEngineFromProcessor();
          }
        }
      } else {
        // Auto-select best engine for platform using strategy
        _processor = await _engineFactory.createForPlatform();
        _currentEngine = _getActualEngineFromProcessor();
      }

      _initialized = true;
      TTSLogger.initialization('TTS service', 'completed', 'Using ${_currentEngine?.name} engine on ${_platformDetector.platformName}');
    } catch (e) {
      throw ErrorHandler.handleInitializationError(e, 'TTS service');
    }
  }

  /// Switch to different TTS engine
  Future<void> switchEngine(
    TTSEngineType engineType, {
    bool disposeOld = true,
    bool autoFallback = true,
  }) async {
    if (_currentEngine == engineType && _processor != null) {
      return; // Already using target engine
    }

    // Check if target engine is supported on current platform
    final strategy = _platformDetector.getTTSStrategy();
    if (!strategy.isEngineSupported(engineType)) {
      if (!autoFallback) {
        throw TTSError(
          'Engine ${engineType.name} is not supported on ${_platformDetector.platformName}',
          code: TTSErrorCodes.platformNotSupported,
        );
      }
      
      // Use platform fallback strategy
      TTSLogger.warning('Engine ${engineType.name} not supported on ${_platformDetector.platformName}, using platform fallback');
      final fallbackEngines = strategy.getFallbackEngines();
      
      for (final fallbackEngine in fallbackEngines) {
        if (fallbackEngine != engineType && await isEngineAvailable(fallbackEngine)) {
          return await switchEngine(fallbackEngine, disposeOld: disposeOld, autoFallback: false);
        }
      }
      
      throw TTSError(
        'No suitable fallback engine available for ${engineType.name} on ${_platformDetector.platformName}',
        code: TTSErrorCodes.noFallbackAvailable,
      );
    }

    TTSProcessor? oldProcessor = _processor;

    try {
      // Create new processor
      _processor = await _engineFactory.createForEngine(engineType);
      _currentEngine = engineType;
      TTSLogger.engine('Switched', engineType.name, 'Engine switch completed successfully on ${_platformDetector.platformName}');

      // Dispose old processor
      if (disposeOld && oldProcessor != null) {
        try {
          oldProcessor.dispose();
          TTSLogger.debug('Old processor disposed successfully');
        } catch (e) {
          TTSLogger.warning('Failed to dispose old processor: $e');
        }
      }
    } catch (e) {
      // Restore old processor on failure
      _processor = oldProcessor;
      throw ErrorHandler.handleInitializationError(e, '${engineType.name} engine');
    }
  }

  /// Get available voices
  Future<List<VoiceModel>> getVoices() async {
    _ensureInitialized();

    try {
      return await _processor!.getAvailableVoices();
    } catch (e) {
      throw ErrorHandler.handleVoiceError(e, 'retrieval from ${_currentEngine?.name} engine');
    }
  }

  /// Synthesize text to audio bytes
  Future<Uint8List> synthesizeText(
    String text,
    String voiceName, {
    String format = 'mp3',
  }) async {
    _ensureInitialized();

    try {
      return await _processor!.synthesizeToAudio(
        text,
        voiceName,
        format: format,
      );
    } catch (e) {
      throw TTSError(
        'Failed to synthesize text using ${_currentEngine?.name} engine: $e',
        code: TTSErrorCodes.synthesisError,
        originalError: e,
      );
    }
  }

  /// Stop current TTS operation
  Future<void> stop() async {
    _ensureInitialized();

    try {
      await _processor!.stop();
    } catch (e) {
      throw TTSError(
        'Failed to stop TTS using ${_currentEngine?.name} engine: $e',
        code: TTSErrorCodes.stopFailed,
        originalError: e,
      );
    }
  }

  /// Set speech rate
  Future<void> setSpeechRate(double rate) async {
    _ensureInitialized();
    await _processor!.setSpeechRate(rate);
  }

  /// Set pitch
  Future<void> setPitch(double pitch) async {
    _ensureInitialized();
    await _processor!.setPitch(pitch);
  }

  /// Set volume
  Future<void> setVolume(double volume) async {
    _ensureInitialized();
    await _processor!.setVolume(volume);
  }

  /// Get platform and engine information
  Future<Map<String, dynamic>> getPlatformInfo() async {
    final platformInfo = await _engineFactory.getPlatformInfo();
    final strategy = _platformDetector.getTTSStrategy();

    return {
      ...platformInfo,
      'currentEngine': _currentEngine?.name,
      'currentEngineName': currentEngineName,
      'isInitialized': isInitialized,
      'strategy': strategy.runtimeType.toString(),
      'fallbackEngines': strategy.getFallbackEngines().map((e) => e.name).toList(),
      'supportedEngines': TTSEngineType.values
          .where((e) => strategy.isEngineSupported(e))
          .map((e) => e.name)
          .toList(),
    };
  }

  /// Check if specific engine is available
  Future<bool> isEngineAvailable(TTSEngineType engineType) async {
    return await _engineFactory.isEngineAvailable(engineType);
  }

  /// Get all available engines
  Future<List<TTSEngineType>> getAvailableEngines() async {
    return await _engineFactory.getAvailableEngines();
  }

  /// Get platform-specific configuration for an engine
  Map<String, dynamic> getEngineConfig(TTSEngineType engineType) {
    final strategy = _platformDetector.getTTSStrategy();
    return strategy.getEngineConfig(engineType);
  }

  /// Get recommended engine for current platform
  TTSEngineType getRecommendedEngine() {
    return _platformDetector.getRecommendedEngine();
  }

  /// Get fallback engines for current platform
  List<TTSEngineType> getFallbackEngines() {
    return _platformDetector.getFallbackEngines();
  }

  /// Reinitialize service with new settings
  Future<void> reinitialize({
    TTSEngineType? preferredEngine,
    bool autoFallback = true,
  }) async {
    dispose();
    await initialize(
      preferredEngine: preferredEngine,
      autoFallback: autoFallback,
    );
  }

  /// Dispose service and release resources
  void dispose() {
    TTSLogger.debug('Disposing TTS service');
    try {
      _processor?.dispose();
    } catch (e) {
      TTSLogger.warning('Error during processor disposal: $e');
    } finally {
      _processor = null;
      _currentEngine = null;
      _initialized = false;
      TTSLogger.debug('TTS service disposed successfully');
    }
  }

  /// Ensure service is initialized
  void _ensureInitialized() {
    if (!isInitialized) {
      throw TTSError(
        'TTS service is not initialized. Please call initialize() first.',
        code: TTSErrorCodes.notInitialized,
      );
    }
  }

  /// Get the actual engine type from the processor
  TTSEngineType? _getActualEngineFromProcessor() {
    if (_processor == null) return null;
    
    switch (_processor!.engineName) {
      case 'edge':
        return TTSEngineType.edge;
      case 'flutter':
        return TTSEngineType.flutter;
      default:
        return null;
    }
  }
}