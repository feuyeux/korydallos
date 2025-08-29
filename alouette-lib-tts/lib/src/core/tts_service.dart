import '../models/voice.dart';

/// TTS 服务的基础接口
abstract class TTSService {
  /// 服务是否已初始化
  bool get isInitialized;

  /// 初始化 TTS 服务
  Future<void> initialize();

  /// 获取所有可用的语音列表
  Future<List<Voice>> getVoices();

  /// 按语言代码过滤语音
  Future<List<Voice>> getVoicesByLanguage(String languageCode);

  /// 设置要使用的语音
  Future<void> setVoice(String voiceId);

  /// 播放文本
  Future<void> speak(String text);

  /// 停止播放
  Future<void> stop();

  /// 释放资源
  Future<void> dispose();
}
