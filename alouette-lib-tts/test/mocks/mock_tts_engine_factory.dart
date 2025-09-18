import 'package:alouette_lib_tts/src/core/tts_engine_factory.dart';
import 'package:alouette_lib_tts/src/engines/base_tts_processor.dart';
import 'package:alouette_lib_tts/src/enums/tts_engine_type.dart';
import 'package:alouette_lib_tts/src/models/tts_error.dart';
import 'package:alouette_lib_tts/src/exceptions/tts_exceptions.dart';
import 'mock_tts_processor.dart';

/// Mock TTS engine factory for testing purposes
class MockTTSEngineFactory {
  MockTTSProcessor? _mockProcessor;
  bool _shouldFail = false;
  TTSEngineType? _failForEngine;
  TTSEngineType? _unsupportedEngine;

  void setMockProcessor(MockTTSProcessor processor) {
    _mockProcessor = processor;
  }

  void setShouldFail(bool fail) {
    _shouldFail = fail;
  }

  void setFailForEngine(TTSEngineType engine) {
    _failForEngine = engine;
  }

  void setUnsupportedEngine(TTSEngineType engine) {
    _unsupportedEngine = engine;
  }

  void reset() {
    _mockProcessor = null;
    _shouldFail = false;
    _failForEngine = null;
    _unsupportedEngine = null;
  }

  Future<TTSProcessor> createForEngine(TTSEngineType engineType) async {
    if (_shouldFail || _failForEngine == engineType) {
      throw TTSError('Mock factory failure for ${engineType.name}');
    }

    if (_unsupportedEngine == engineType) {
      throw TTSError(
        'Engine ${engineType.name} is not supported on this platform',
        code: TTSErrorCodes.platformNotSupported,
      );
    }

    return _mockProcessor ?? MockTTSProcessor();
  }

  Future<TTSProcessor> createForPlatform() async {
    if (_shouldFail) {
      throw TTSError('Mock factory failure for platform');
    }

    return _mockProcessor ?? MockTTSProcessor();
  }

  Future<bool> isEngineAvailable(TTSEngineType engineType) async {
    if (_unsupportedEngine == engineType) {
      return false;
    }
    
    // Flutter TTS is always available in tests
    if (engineType == TTSEngineType.flutter) {
      return true;
    }
    
    // Edge TTS availability depends on platform
    if (engineType == TTSEngineType.edge) {
      return true; // Assume available for testing
    }
    
    return false;
  }

  Future<List<TTSEngineType>> getAvailableEngines() async {
    final engines = <TTSEngineType>[];
    
    for (final engine in TTSEngineType.values) {
      if (await isEngineAvailable(engine)) {
        engines.add(engine);
      }
    }
    
    return engines;
  }

  Future<Map<String, dynamic>> getPlatformInfo() async {
    return {
      'platform': 'mock',
      'isDesktop': true,
      'isMobile': false,
      'isWeb': false,
      'recommendedEngine': 'flutter',
      'availableEngines': ['flutter', 'edge'],
      'supportsProcessExecution': true,
      'supportsFileSystem': true,
    };
  }
}