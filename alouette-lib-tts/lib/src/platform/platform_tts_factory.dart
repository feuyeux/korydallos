import '../core/tts_factory.dart';
import '../core/tts_service.dart';

/// 平台特定的 TTS 工厂类
class PlatformTTSFactory {
  /// 根据平台创建最适合的 TTS 服务实例
  static Future<TTSService> createForPlatform() async {
    // 首先尝试使用 Flutter TTS
    try {
      return await TTSFactory.create(TTSType.flutter);
    } catch (e) {
      // 如果 Flutter TTS 初始化失败，尝试使用 Edge TTS
      try {
        return await TTSFactory.create(TTSType.edge);
      } catch (e) {
        throw PlatformTTSException(
            'No available TTS service for current platform.');
      }
    }
  }
}

/// 平台 TTS 异常
class PlatformTTSException implements Exception {
  final String message;

  PlatformTTSException(this.message);

  @override
  String toString() => 'PlatformTTSException: $message';
}
