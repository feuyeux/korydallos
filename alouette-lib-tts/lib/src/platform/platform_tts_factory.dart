import '../core/tts_processor.dart';
import '../edge/edge_tts_processor.dart';
import '../flutter/flutter_tts_processor.dart';
import '../utils/platform_utils.dart';
import '../models/tts_error.dart';

/// 平台特定的 TTS 工厂类
/// 重构后实现基于平台的自动引擎选择逻辑
/// Desktop 平台优先使用 Edge TTS，Mobile/Web 使用 Flutter TTS
class PlatformTTSFactory {
  /// 根据平台自动选择最适合的 TTS 处理器
  /// Desktop 平台必须使用 Edge TTS，Mobile/Web 使用 Flutter TTS
  static Future<TTSProcessor> createForPlatform() async {
    if (PlatformUtils.isDesktop) {
      // Desktop 平台必须使用 Edge TTS，不允许回退
      if (!PlatformUtils.supportsProcessExecution) {
        throw TTSError(
          'Desktop platform requires Edge TTS, but process execution is not supported.',
          code: TTSErrorCodes.platformNotSupported,
        );
      }
      
      final isEdgeAvailable = await PlatformUtils.isEdgeTTSAvailableWithTimeout();
      if (!isEdgeAvailable) {
        throw TTSError(
          'Desktop platform requires Edge TTS, but edge-tts is not available. '
          'Please install edge-tts using "pip install edge-tts" and ensure it\'s in your PATH.',
          code: TTSErrorCodes.initializationFailed,
        );
      }
      
      return EdgeTTSProcessor();
    } else if (PlatformUtils.isMobile || PlatformUtils.isWeb) {
      // Mobile 和 Web 平台使用 Flutter TTS
      return FlutterTTSProcessor();
    } else {
      // 未知平台，默认使用 Flutter TTS
      return FlutterTTSProcessor();
    }
  }

  /// 手动指定引擎类型创建 TTS 处理器
  /// 提供手动引擎选择功能
  static Future<TTSProcessor> create(TTSEngineType engineType) async {
    switch (engineType) {
      case TTSEngineType.edge:
        // 检查 Edge TTS 是否可用
        if (!PlatformUtils.supportsProcessExecution) {
          throw TTSError(
            'Edge TTS is not supported on this platform. '
            'Edge TTS requires process execution capabilities which are not available on web platforms.',
            code: TTSErrorCodes.platformNotSupported,
          );
        }
        
        final isAvailable = await PlatformUtils.isEdgeTTSAvailableWithTimeout();
        if (!isAvailable) {
          throw TTSError(
            'Edge TTS is not available on this system. '
            'Please install edge-tts using "pip install edge-tts" and ensure it\'s in your PATH.',
            code: TTSErrorCodes.initializationFailed,
          );
        }
        
        return EdgeTTSProcessor();
        
      case TTSEngineType.flutter:
        if (!PlatformUtils.isFlutterTTSSupported) {
          throw TTSError(
            'Flutter TTS is not supported on this platform.',
            code: TTSErrorCodes.platformNotSupported,
          );
        }
        
        return FlutterTTSProcessor();
    }
  }

  /// 获取当前平台推荐的引擎类型
  static TTSEngineType get recommendedEngineType => PlatformUtils.recommendedEngine;

  /// 检查指定引擎是否在当前平台可用
  static Future<bool> isEngineAvailable(TTSEngineType engineType) async {
    switch (engineType) {
      case TTSEngineType.edge:
        return PlatformUtils.supportsProcessExecution && 
               await PlatformUtils.isEdgeTTSAvailableWithTimeout();
      case TTSEngineType.flutter:
        return PlatformUtils.isFlutterTTSSupported;
    }
  }

  /// 获取当前平台所有可用的引擎类型
  static Future<List<TTSEngineType>> getAvailableEngines() async {
    final availableEngines = <TTSEngineType>[];
    
    // 检查 Flutter TTS
    if (await isEngineAvailable(TTSEngineType.flutter)) {
      availableEngines.add(TTSEngineType.flutter);
    }
    
    // 检查 Edge TTS
    if (await isEngineAvailable(TTSEngineType.edge)) {
      availableEngines.add(TTSEngineType.edge);
    }
    
    return availableEngines;
  }

  /// 获取平台和引擎可用性信息
  static Future<Map<String, dynamic>> getPlatformInfo() async {
    final platformInfo = PlatformUtils.getPlatformInfo();
    final availableEngines = await getAvailableEngines();
    
    return {
      ...platformInfo,
      'availableEngines': availableEngines.map((e) => e.name).toList(),
      'edgeTTSAvailable': await isEngineAvailable(TTSEngineType.edge),
      'flutterTTSAvailable': await isEngineAvailable(TTSEngineType.flutter),
    };
  }
}

/// 平台 TTS 异常
/// 保持向后兼容性
class PlatformTTSException implements Exception {
  final String message;

  PlatformTTSException(this.message);

  @override
  String toString() => 'PlatformTTSException: $message';
}
