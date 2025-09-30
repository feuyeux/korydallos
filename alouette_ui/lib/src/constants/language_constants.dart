/// Language constants for Alouette applications
class LanguageOption {
  final String code;
  final String name;
  final String nativeName;
  final String _emojiFlag;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
    required String flag,
  }) : _emojiFlag = flag;

  /// Get platform-appropriate flag representation
  String get flag => _emojiFlag;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageOption &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

class LanguageConstants {
  /// Supported languages with comprehensive information
  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(
      code: 'zh-CN',
      name: 'Chinese',
      nativeName: '中文',
      flag: '🇨🇳',
    ),
    LanguageOption(
      code: 'en-US',
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
    ),
    LanguageOption(
      code: 'ja-JP',
      name: 'Japanese',
      nativeName: '日本語',
      flag: '🇯🇵',
    ),
    LanguageOption(
      code: 'ko-KR',
      name: 'Korean',
      nativeName: '한국어',
      flag: '🇰🇷',
    ),
    LanguageOption(
      code: 'fr-FR',
      name: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
    ),
    LanguageOption(
      code: 'de-DE',
      name: 'German',
      nativeName: 'Deutsch',
      flag: '🇩🇪',
    ),
    LanguageOption(
      code: 'es-ES',
      name: 'Spanish',
      nativeName: 'Español',
      flag: '🇪🇸',
    ),
    LanguageOption(
      code: 'it-IT',
      name: 'Italian',
      nativeName: 'Italiano',
      flag: '🇮🇹',
    ),
    LanguageOption(
      code: 'ru-RU',
      name: 'Russian',
      nativeName: 'Русский',
      flag: '🇷🇺',
    ),
    LanguageOption(
      code: 'el-GR',
      name: 'Greek',
      nativeName: 'Ελληνικά',
      flag: '🇬🇷',
    ),
    LanguageOption(
      code: 'ar-SA',
      name: 'Arabic',
      nativeName: 'العربية',
      flag: '🇸🇦',
    ),
    LanguageOption(
      code: 'hi-IN',
      name: 'Hindi',
      nativeName: 'हिन्दी',
      flag: '🇮🇳',
    ),
  ];

  static const LanguageOption defaultLanguage = LanguageOption(
    code: 'en-US',
    name: 'English',
    nativeName: 'English',
    flag: '🇺🇸',
  );

  /// Default selected languages for translation
  static const List<String> defaultSelectedLanguages = ['English'];

  /// Get language option by code
  static LanguageOption? getLanguageByCode(String code) {
    try {
      final key = code.toLowerCase();
      return supportedLanguages.firstWhere(
        (lang) => lang.code.toLowerCase() == key,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get language option by name
  static LanguageOption? getLanguageByName(String name) {
    try {
      return supportedLanguages.firstWhere(
        (lang) => lang.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get translation language names mapping
  static Map<String, String> get translationLanguageNames {
    return Map.fromEntries(
      supportedLanguages.map((lang) => MapEntry(lang.code, lang.name)),
    );
  }

  /// Get list of language names only
  static List<String> get languageNames {
    return supportedLanguages.map((lang) => lang.name).toList();
  }

  /// Get list of language codes only
  static List<String> get languageCodes {
    return supportedLanguages.map((lang) => lang.code).toList();
  }
}
