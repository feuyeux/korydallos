import 'dart:typed_data';

import '../engines/base_processor.dart';
import '../platform/platform_factory.dart';
import '../utils/platform_utils.dart';
import '../utils/error_handler.dart';
import '../utils/tts_logger.dart';
import '../models/voice.dart';
import '../models/tts_error.dart';
import '../enums/tts_engine_type.dart';
 
class TTSService {
  BaseTTSProcessor? _processor;
  TTSEngineType? _currentEngine;
  bool _initialized = false;
 
  TTSEngineType? get currentEngine => _currentEngine;
 
  String? get currentBackend => _processor?.backend; 
  bool get isInitialized => _initialized && _processor != null;

 
  Future<void> initialize({
    TTSEngineType? preferredEngine,
    bool autoFallback = true,
  }) async {
    if (_initialized) {
      return; // 已经初始化，直接返回
    }

    try {
      if (preferredEngine != null) {
        // 尝试使用指定的引擎
        try {
      _processor = await PlatformTTSFactory.instance.createForEngine(preferredEngine);
          _currentEngine = preferredEngine;
          TTSLogger.engine('Initialized', preferredEngine.name, 'Using preferred engine');
        } catch (e) {
          if (!autoFallback) {
            rethrow; // 不允许回退时直接抛出错误
          }
          
          TTSLogger.warning('Preferred engine ${preferredEngine.name} failed, trying platform default: $e');
          // 回退到平台推荐的引擎
          _processor = await PlatformTTSFactory.instance.createForPlatform();
          _currentEngine = PlatformTTSFactory.instance.recommendedEngineType;
        }
      } else {
        // 自动选择最适合的引擎
        _processor = await PlatformTTSFactory.instance.createForPlatform();
        _currentEngine = PlatformTTSFactory.instance.recommendedEngineType;
      }

      _initialized = true;
      TTSLogger.initialization('TTS service', 'completed', 'Using ${_currentEngine?.name} engine');
    } catch (e) {
      throw ErrorHandler.handleInitializationError(e, 'TTS service');
    }
  } 
  Future<void> switchEngine(
    TTSEngineType engineType, {
    bool disposeOld = true,
  }) async {
    if (_currentEngine == engineType && _processor != null) {
      return; // 已经是目标引擎，无需切换
    }

    BaseTTSProcessor? oldProcessor = _processor;

    try {
      // 创建新的处理器
      _processor = await PlatformTTSFactory.instance.createForEngine(engineType);
      _currentEngine = engineType;
      TTSLogger.engine('Switched', engineType.name, 'Engine switch completed successfully');

      // 释放旧的处理器
      if (disposeOld && oldProcessor != null) {
        try {
          oldProcessor.dispose();
          TTSLogger.debug('Old processor disposed successfully');
        } catch (e) {
          TTSLogger.warning('Failed to dispose old processor: $e');
        }
      }
    } catch (e) {
      // 切换失败时恢复旧的处理器
      _processor = oldProcessor;
      
      throw ErrorHandler.handleInitializationError(e, '${engineType.name} engine');
    }
  }
 
  Future<List<Voice>> getVoices() async {
    _ensureInitialized();
    
    try {
      return await _processor!.getVoices();
    } catch (e) {
      throw ErrorHandler.handleVoiceError(e, 'retrieval from ${_currentEngine?.name} engine');
    }
  }
 
  Future<Uint8List> synthesizeText(
    String text,
    String voiceName, {
    String format = 'mp3',
  }) async {
    _ensureInitialized();

    try {
      return await _processor!.synthesizeText(
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

  /// 获取当前平台和引擎信息
  Future<Map<String, dynamic>> getPlatformInfo() async {
    final platformInfo = await PlatformTTSFactory.instance.getPlatformInfo();
    
    return {
      ...platformInfo,
      'currentEngine': _currentEngine?.name,
      'currentBackend': currentBackend,
      'isInitialized': isInitialized,
    };
  }

  /// 检查指定引擎是否可用
  Future<bool> isEngineAvailable(TTSEngineType engineType) async {
    return await PlatformTTSFactory.instance.isEngineAvailable(engineType);
  }

  /// 获取所有可用的引擎类型
  Future<List<TTSEngineType>> getAvailableEngines() async {
    return await PlatformTTSFactory.instance.getAvailableEngines();
  }
 
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

  /// 释放资源
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

  /// 确保服务已初始化
  void _ensureInitialized() {
    if (!isInitialized) {
      throw TTSError(
        'TTS service is not initialized. Please call initialize() first.',
        code: TTSErrorCodes.notInitialized,
      );
    }
  }
}