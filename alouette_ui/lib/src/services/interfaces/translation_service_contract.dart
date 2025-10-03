/// Translation Service Interface
///
/// Provides an abstraction layer for translation functionality.
abstract class TranslationServiceContract {
  /// Initialize the translation service
  Future<bool> initialize();

  /// Translate text from source language to target language
  ///
  /// [text] - The text to translate
  /// [sourceLanguage] - Source language code (null for auto-detect)
  /// [targetLanguage] - Target language code
  Future<String> translate({
    required String text,
    String? sourceLanguage,
    required String targetLanguage,
  });

  /// Translate text to multiple target languages
  ///
  /// [text] - The text to translate
  /// [sourceLanguage] - Source language code (null for auto-detect)
  /// [targetLanguages] - List of target language codes
  Future<Map<String, String>> translateToMultiple({
    required String text,
    String? sourceLanguage,
    required List<String> targetLanguages,
  });

  /// Detect the language of the given text
  Future<String?> detectLanguage(String text);

  /// Get list of supported languages
  Future<List<LanguageInfo>> getSupportedLanguages();

  /// Check if a language is supported
  bool isLanguageSupported(String languageCode);

  /// Check if the service is initialized
  bool get isInitialized;

  /// Dispose resources and cleanup
  void dispose();
}

/// Language information model
class LanguageInfo {
  final String code;
  final String name;
  final String nativeName;
  final bool isSupported;

  const LanguageInfo({
    required this.code,
    required this.name,
    required this.nativeName,
    this.isSupported = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageInfo &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() =>
      'LanguageInfo(code: $code, name: $name, nativeName: $nativeName)';
}
