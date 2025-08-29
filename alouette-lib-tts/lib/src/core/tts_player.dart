/// TTS 播放器的基础接口
abstract class TTSPlayer {
  /// 播放音频
  Future<void> play(String source);

  /// 停止播放
  Future<void> stop();

  /// 释放资源
  Future<void> dispose();
}
