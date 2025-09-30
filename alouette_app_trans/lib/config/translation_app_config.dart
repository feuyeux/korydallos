/// Configuration for the Translation Application
/// 
/// Contains only translation app-specific settings. UI constants should use
/// design tokens from alouette_ui library. LLM defaults use UI library constants.
class TranslationAppConfig {
  /// Application Information
  static const String appName = 'Alouette Translator';
  static const String appVersion = '1.0.0';
  static const String appBuild = '1';

  /// Default LLM Configuration (uses UI library defaults)
  static const String defaultProvider = 'ollama';
  static const String defaultServerUrl = 'http://localhost:11434';

  /// Translation app-specific settings
  static const int maxTextLength = 5000;
  static const int maxSelectedLanguages = 10;

  /// Storage Keys (application-specific)
  static const String llmConfigKey = 'llm_config';
  static const String userPreferencesKey = 'user_preferences';
  static const String translationHistoryKey = 'translation_history';

  /// Feature Flags (translation app-specific)
  static const bool enableAutoConfiguration = true;
  static const bool enableTranslationHistory = true;
  static const bool enableOfflineMode = false;
  static const bool enableAnalytics = false;
}
