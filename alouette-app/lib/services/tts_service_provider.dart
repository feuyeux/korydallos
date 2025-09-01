import 'package:alouette_lib_tts/alouette_tts.dart';

/// 提供TTS服务实例的工厂类 - 使用新的统一 API
class TTSServiceProvider {
  static UnifiedTTSService? _instance;
  static AudioPlayer? _audioPlayer;

  /// 获取TTS服务实例
  static Future<UnifiedTTSService> getInstance() async {
    _instance ??= await _createService();
    return _instance!;
  }

  /// 获取音频播放器实例
  static AudioPlayer getAudioPlayer() {
    _audioPlayer ??= AudioPlayer();
    return _audioPlayer!;
  }

  /// 创建新的TTS服务实例
  static Future<UnifiedTTSService> _createService() async {
    final service = UnifiedTTSService();
    // 自动选择最适合当前平台的引擎
    await service.initialize();
    return service;
  }

  /// 手动创建指定引擎的服务实例
  static Future<UnifiedTTSService> createWithEngine(TTSEngineType engineType) async {
    final service = UnifiedTTSService();
    await service.initialize(preferredEngine: engineType);
    return service;
  }

  /// 获取当前使用的引擎类型
  static TTSEngineType? get currentEngine => _instance?.currentEngine;

  /// 切换引擎
  static Future<void> switchEngine(TTSEngineType engineType) async {
    if (_instance != null) {
      await _instance!.switchEngine(engineType);
    }
  }

  /// 释放TTS服务资源
  static Future<void> dispose() async {
    if (_instance != null) {
      _instance!.dispose();
      _instance = null;
      _audioPlayer = null;
    }
  }
}
