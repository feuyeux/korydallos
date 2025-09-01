/// 简化的语音模型
/// 参照 hello-tts-dart 的 Voice 设计
class Voice {
  /// 语音名称/标识符
  final String name;

  /// 显示名称
  final String displayName;

  /// 语言代码 (如 'en', 'zh')
  final String language;

  /// 性别
  final String gender;

  /// 完整区域设置 (如 'en-US', 'zh-CN')
  final String locale;

  /// 是否为神经网络语音
  final bool isNeural;

  /// 是否为标准语音
  final bool isStandard;

  const Voice({
    required this.name,
    required this.displayName,
    required this.language,
    required this.gender,
    required this.locale,
    this.isNeural = false,
    this.isStandard = false,
  });

  /// 从 JSON 创建 Voice 实例
  factory Voice.fromJson(Map<String, dynamic> json) {
    return Voice(
      name: json['Name'] ?? json['name'] ?? '',
      displayName: json['DisplayName'] ?? json['displayName'] ?? '',
      language: (json['Locale'] ?? json['locale'] ?? '').split('-')[0],
      gender: json['Gender'] ?? json['gender'] ?? '',
      locale: json['Locale'] ?? json['locale'] ?? '',
      isNeural: (json['VoiceType'] ?? json['voiceType'] ?? '').contains('Neural'),
      isStandard: (json['VoiceType'] ?? json['voiceType'] ?? '').contains('Standard'),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() => {
    'Name': name,
    'DisplayName': displayName,
    'Locale': locale,
    'Gender': gender,
    'VoiceType': isNeural ? 'Neural' : 'Standard',
  };

  @override
  String toString() {
    return 'Voice(name: $name, displayName: $displayName, language: $language, gender: $gender)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Voice && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
