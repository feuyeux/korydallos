import 'package:alouette_lib_tts/alouette_tts.dart';

/// TTS 服务管理类
class TTSManager {
  static TTSService? _service;
  static bool _isInitialized = false;

  /// 获取 TTS 服务实例
  static Future<TTSService> getService() async {
    if (!_isInitialized) {
      try {
        _service = await TTSFactory.create(TTSType.edge);
        await _service!.initialize();
        _isInitialized = true;
      } catch (e, stack) {
        print('TTS initialization error: $e\n$stack');
        rethrow;
      }
    }
    return _service!;
  }

  /// 释放资源
  static Future<void> dispose() async {
    if (_isInitialized && _service != null) {
      await _service!.dispose();
      _service = null;
      _isInitialized = false;
    }
  }

  /// 服务是否已初始化
  static bool get isInitialized => _isInitialized;
}
