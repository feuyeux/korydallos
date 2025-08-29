import '../core/tts_voice_adapter.dart';
import '../models/voice.dart';
import '../enums/voice_gender.dart';
import '../enums/voice_quality.dart';

/// Edge TTS 语音适配器
class EdgeTTSVoiceAdapter implements TTSVoiceAdapter {
  @override
  Voice parseVoice(dynamic rawVoice) {
    final line = rawVoice as String;
    final parts = line.split('\t');
    if (parts.length < 2) {
      throw FormatException('Invalid voice format: $line');
    }

    final nameParts = parts[0].split(' ');
    if (nameParts.length < 2) {
      throw FormatException('Invalid voice name format: ${parts[0]}');
    }

    final locale = nameParts[0];
    final name = nameParts.sublist(1).join(' ');

    return Voice(
      id: parts[0],
      name: name,
      languageCode: locale,
      gender: _parseGender(name),
      quality: VoiceQuality.neural,
      metadata: {
        'edgeTTSName': parts[0],
      },
    );
  }

  @override
  String getVoiceId(Voice voice) {
    return voice.metadata['edgeTTSName'] as String? ?? voice.id;
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
