import 'dart:io';
import '../utils/platform_utils.dart';
import '../utils/tts_logger.dart';
import '../models/tts_error.dart';
import '../enums/tts_engine_type.dart';
import '../exceptions/tts_exceptions.dart';
import '../engines/edge_tts_processor.dart';
import '../engines/flutter_tts_processor.dart';
import '../engines/base_tts_processor.dart';
import 'platform_detector.dart';

/// TTS Engine Factory for platform-specific engine selection
/// Follows Flutter naming conventions and provides unified engine creation
class TTSEngineFactory {
  static TTSEngineFactory? _instance;
  static TTSEngineFactory get instance => _instance ??= TTSEngineFactory._();

  TTSEngineFactory._();

  late final PlatformDetector _platformDetector = PlatformDetector();

  /// Create TTS processor for current platform automatically
  Future<TTSProcessor> createForPlatform() async {
    TTSLogger.debug('Creating TTS processor for current platform');

    try {
      final strategy = _platformDetector.getTTSStrategy();
      final fallbackEngines = strategy.getFallbackEngines();
      
      TTSLogger.debug('Platform strategy: ${strategy.runtimeType}');
      TTSLogger.debug('Fallback engines: ${fallbackEngines.map((e) => e.name).join(', ')}');
      
      // Try engines in order of preference
      for (final engine in fallbackEngines) {
        try {
          if (strategy.isEngineSupported(engine) && await isEngineAvailable(engine)) {
            TTSLogger.debug('Using engine: ${engine.name}');
            return await createForEngine(engine);
          } else {
            TTSLogger.debug('Engine ${engine.name} not available, trying next...');
          }
        } catch (e) {
          TTSLogger.warning('Failed to create ${engine.name} engine: $e');
          continue; // Try next engine
        }
      }

      // If no engines from strategy work, try any available engine
      final availableEngines = await getAvailableEngines();
      if (availableEngines.isNotEmpty) {
        TTSLogger.warning('Using fallback engine: ${availableEngines.first.name}');
        return await createForEngine(availableEngines.first);
      }

      throw TTSError(
        'No TTS engines available for this platform. '
        'Platform: ${_platformDetector.platformName}, '
        'Tried engines: ${fallbackEngines.map((e) => e.name).join(', ')}',
        code: TTSErrorCodes.initializationFailed,
      );
    } catch (e) {
      TTSLogger.error('Failed to create processor for platform', e);
      rethrow;
    }
  }

  /// Create TTS processor for specific engine type
  Future<TTSProcessor> createForEngine(TTSEngineType engineType) async {
    TTSLogger.debug('Creating TTS processor for engine: ${engineType.name}');

    // Check availability first
    final available = await isEngineAvailable(engineType);
    if (!available) {
      String errorMessage = '${engineType.name} TTS is not available on this system.';
      
      // Provide installation suggestions
      if (engineType == TTSEngineType.edge) {
        errorMessage += '\nTo install: pip install edge-tts\nEnsure Python and pip are in your PATH.';
      }

      throw TTSError(
        errorMessage,
        code: TTSErrorCodes.initializationFailed,
      );
    }

    // Create processor based on engine type
    switch (engineType) {
      case TTSEngineType.edge:
        return EdgeTTSProcessor();
      case TTSEngineType.flutter:
        return FlutterTTSProcessor();
    }
  }

  /// Check if specific engine is available on current platform
  Future<bool> isEngineAvailable(TTSEngineType engineType) async {
    switch (engineType) {
      case TTSEngineType.edge:
        return await _isEdgeTTSAvailable();
      case TTSEngineType.flutter:
        return _isFlutterTTSAvailable();
    }
  }

  /// Get all available engines for current platform
  Future<List<TTSEngineType>> getAvailableEngines() async {
    final availableEngines = <TTSEngineType>[];

    for (final engineType in TTSEngineType.values) {
      try {
        final available = await isEngineAvailable(engineType);
        if (available) {
          availableEngines.add(engineType);
        }
      } catch (e) {
        TTSLogger.warning('Failed to check availability for ${engineType.name}: $e');
      }
    }

    return availableEngines;
  }

  /// Get platform information and engine availability
  Future<Map<String, dynamic>> getPlatformInfo() async {
    final availableEngines = await getAvailableEngines();
    final platformInfo = _platformDetector.getPlatformInfo();

    return {
      ...platformInfo,
      'recommendedEngine': _platformDetector.getRecommendedEngine().name,
      'availableEngines': availableEngines.map((e) => e.name).toList(),
    };
  }

  /// Check Edge TTS availability
  Future<bool> _isEdgeTTSAvailable() async {
    if (!_platformDetector.supportsProcessExecution) {
      TTSLogger.debug('Edge TTS not supported: platform does not support process execution');
      return false;
    }

    try {
      TTSLogger.debug('Checking Edge TTS availability...');
      final available = await PlatformUtils.isEdgeTTSAvailableWithTimeout(
        timeout: const Duration(seconds: 12),
      );
      TTSLogger.debug('Edge TTS availability check result: $available');

      if (!available) {
        // Get diagnostic information
        final edgePath = await PlatformUtils.getEdgeTTSPath();
        TTSLogger.debug('Edge TTS path check result: $edgePath');

        // Try version command for more info
        try {
          final result = await Process.run('edge-tts', ['--version'])
              .timeout(const Duration(seconds: 5));
          TTSLogger.debug('edge-tts --version exit code: ${result.exitCode}');
          TTSLogger.debug('edge-tts --version stdout: ${result.stdout}');
          TTSLogger.debug('edge-tts --version stderr: ${result.stderr}');
        } catch (e) {
          TTSLogger.debug('edge-tts --version command failed: $e');
        }
      }

      return available;
    } catch (e) {
      TTSLogger.warning('Edge TTS availability check failed: $e');
      return false;
    }
  }

  /// Check Flutter TTS availability
  bool _isFlutterTTSAvailable() {
    return _platformDetector.isFlutterTTSSupported;
  }
}