import '../core/tts_voice_adapter.dart';
import '../models/voice.dart';

/// Flutter TTS 语音适配器
class FlutterTTSVoiceAdapter implements TTSVoiceAdapter {
  @override
  Voice parseVoice(dynamic rawVoice) {
    final Map<String, dynamic> voice = rawVoice as Map<String, dynamic>;

    final locale = voice['locale'] as String;
    return Voice(
      name: voice['name'] as String,
      displayName: voice['name'] as String,
      language: locale.split('-')[0],
      gender: _parseGenderString(voice['name'] as String),
      locale: locale,
      isNeural: false,
      isStandard: true,
    );
  }

  @override
  String getVoiceId(Voice voice) {
    return voice.name; // Use the name as the ID for Flutter TTS
  }

  String _parseGenderString(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('female') || lower.contains('woman')) {
      return 'Female';
    } else if (lower.contains('male') || lower.contains('man')) {
      return 'Male';
    }
    return 'Unknown';
  }
}
