import 'package:alouette_lib_tts/alouette_tts.dart';

/// TTS 服务管理类 - 使用新的统一 API
class TTSManager {
  static UnifiedTTSService? _service;
  static AudioPlayer? _audioPlayer;
  static bool _isInitialized = false;

  /// 获取 TTS 服务实例
  static Future<UnifiedTTSService> getService() async {
    if (!_isInitialized) {
      try {
        _service = UnifiedTTSService();
        // 桌面平台强制使用 Edge TTS，移动平台使用 Flutter TTS
        final preferredEngine = PlatformUtils.isDesktop 
            ? TTSEngineType.edge 
            : TTSEngineType.flutter;
        
        await _service!.initialize(
          preferredEngine: preferredEngine,
          autoFallback: true, // 允许回退以确保应用能正常启动
        );
        _audioPlayer = AudioPlayer();
        _isInitialized = true;
        print('TTS Manager: Initialized with ${_service!.currentEngine} engine');
      } catch (e, stack) {
        print('TTS initialization error: $e\n$stack');
        rethrow;
      }
    }
    return _service!;
  }

  /// 获取音频播放器实例
  static AudioPlayer getAudioPlayer() {
    if (_audioPlayer == null) {
      throw Exception('TTS Manager not initialized. Call getService() first.');
    }
    return _audioPlayer!;
  }

  /// 获取当前使用的引擎类型
  static TTSEngineType? get currentEngine => _service?.currentEngine;

  /// 切换 TTS 引擎
  static Future<void> switchEngine(TTSEngineType engineType) async {
    if (_service != null) {
      await _service!.switchEngine(engineType);
    }
  }

  /// 释放资源
  static Future<void> dispose() async {
    if (_isInitialized && _service != null) {
      _service!.dispose();
      _service = null;
      _audioPlayer = null;
      _isInitialized = false;
    }
  }

  /// 服务是否已初始化
  static bool get isInitialized => _isInitialized;
}
