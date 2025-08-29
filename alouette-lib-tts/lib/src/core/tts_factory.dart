import '../core/tts_service.dart';
import '../edge/edge_tts_service.dart';
import '../flutter/flutter_tts_service.dart';

/// TTS 实现类型
enum TTSType {
  /// Microsoft Edge TTS
  edge,

  /// Flutter TTS
  flutter,
}

/// TTS 服务工厂类
class TTSFactory {
  /// 创建指定类型的 TTS 服务实例
  static Future<TTSService> create(TTSType type) async {
    final service = switch (type) {
      TTSType.edge => EdgeTTSService(),
      TTSType.flutter => FlutterTTSService(),
    };

    await service.initialize();
    return service;
  }
}
