import '../core/tts_voice_adapter.dart';
import '../models/voice.dart';
import '../enums/voice_gender.dart';
import '../enums/voice_quality.dart';

/// Flutter TTS 语音适配器
class FlutterTTSVoiceAdapter implements TTSVoiceAdapter {
  @override
  Voice parseVoice(dynamic rawVoice) {
    final Map<String, dynamic> voice = rawVoice as Map<String, dynamic>;

    return Voice(
      id: voice['name'] as String,
      name: voice['name'] as String,
      languageCode: voice['locale'] as String,
      gender: _parseGender(voice['name'] as String),
      quality: VoiceQuality.standard,
      metadata: {
        'flutterTTSName': voice['name'],
        'flutterTTSLocale': voice['locale'],
      },
    );
  }

  @override
  String getVoiceId(Voice voice) {
    return voice.metadata?['flutterTTSName'] as String? ?? voice.id;
  }

  VoiceGender _parseGender(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('female') || lower.contains('woman')) {
      return VoiceGender.female;
    } else if (lower.contains('male') || lower.contains('man')) {
      return VoiceGender.male;
    }
    return VoiceGender.neutral;
  }
}
