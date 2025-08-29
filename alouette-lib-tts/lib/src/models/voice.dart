import '../enums/voice_gender.dart';
import '../enums/voice_quality.dart';

/// 语音模型
class Voice {
  /// 语音ID
  final String id;

  /// 语音名称
  final String name;

  /// 语言代码 (例如: 'en-US', 'zh-CN')
  final String languageCode;

  /// 性别
  final VoiceGender gender;

  /// 质量
  final VoiceQuality quality;

  /// 可选的元数据
  final Map<String, dynamic> metadata;

  const Voice({
    required this.id,
    required this.name,
    required this.languageCode,
    required this.gender,
    required this.quality,
    this.metadata = const {},
  });

  @override
  String toString() =>
      'Voice(id: $id, name: $name, languageCode: $languageCode)';
}
