import '../models/voice.dart';

/// TTS 语音适配器的基础接口
abstract class TTSVoiceAdapter {
  /// 解析语音信息
  Voice parseVoice(dynamic rawVoice);

  /// 获取适配后的语音ID
  String getVoiceId(Voice voice);
}
