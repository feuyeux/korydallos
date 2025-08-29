import 'package:flutter_tts/flutter_tts.dart';
import '../core/tts_player.dart';

/// Flutter TTS 播放器实现
class FlutterTTSPlayer implements TTSPlayer {
  final FlutterTts _tts;

  FlutterTTSPlayer(this._tts);

  @override
  Future<void> play(String text) async {
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  @override
  Future<void> dispose() async {
    await stop();
  }
}
