import 'package:alouette_lib_tts/src/interfaces/simple_tts_service.dart';
import 'package:alouette_lib_tts/src/services/edge/edge_tts_command_line_client.dart';
import 'package:alouette_lib_tts/src/services/edge/edge_tts_player.dart';
import 'package:alouette_lib_tts/src/services/edge/edge_tts_voice_discovery.dart';
import 'package:alouette_lib_tts/src/services/edge/edge_tts_voice_selector.dart';

/// 提供TTS服务实例的工厂类
class TTSServiceProvider {
  static SimpleTTSService? _instance;

  /// 获取TTS服务实例
  static Future<SimpleTTSService> getInstance() async {
    _instance ??= await _createService();
    return _instance!;
  }

  /// 创建新的TTS服务实例
  static Future<SimpleTTSService> _createService() async {
    final discovery = EdgeTTSVoiceDiscovery();
    final selector = EdgeTTSVoiceSelector(discovery);
    final client = EdgeTTSCommandLineClient();
    final player = EdgeTTSPlayer();

    await Future.wait([
      selector.initialize(),
      player.initialize(),
    ]);

    return EdgeTTSService(
      client: client,
      player: player,
      selector: selector,
    );
  }

  /// 释放TTS服务资源
  static Future<void> dispose() async {
    if (_instance != null) {
      await _instance!.dispose();
      _instance = null;
    }
  }
}
