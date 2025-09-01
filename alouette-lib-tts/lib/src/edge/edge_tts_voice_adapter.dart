import '../core/tts_voice_adapter.dart';
import '../models/voice.dart';
import '../models/tts_error.dart';

/// Edge TTS 语音适配器
/// 更新为使用统一的 TTSError 错误处理
class EdgeTTSVoiceAdapter implements TTSVoiceAdapter {
  @override
  Voice parseVoice(dynamic rawVoice) {
    try {
      final line = rawVoice as String;
      final parts = line.split('\t');
      if (parts.length < 2) {
        throw TTSError(
          'Invalid voice format: expected tab-separated values but got: $line',
          code: TTSErrorCodes.invalidVoiceFormat,
          originalError: line,
        );
      }

      final nameParts = parts[0].split(' ');
      if (nameParts.length < 2) {
        throw TTSError(
          'Invalid voice name format: expected locale and name but got: ${parts[0]}',
          code: TTSErrorCodes.invalidVoiceNameFormat,
          originalError: parts[0],
        );
      }

      final locale = nameParts[0];
      final name = nameParts.sublist(1).join(' ');

      return Voice(
        name: parts[0],
        displayName: name,
        language: locale.split('-')[0],
        gender: _parseGenderString(name),
        locale: locale,
        isNeural: true,
        isStandard: false,
      );
    } catch (e) {
      if (e is TTSError) {
        rethrow;
      }
      
      throw TTSError(
        'Failed to parse voice data: $e',
        code: TTSErrorCodes.voiceParseError,
        originalError: e,
      );
    }
  }

  @override
  String getVoiceId(Voice voice) {
    return voice.name; // Use the name as the ID for Edge TTS
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
