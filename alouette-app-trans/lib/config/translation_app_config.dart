/// Configuration constants and settings for the Translation Application
class TranslationAppConfig {
  // Application Information
  static const String appName = 'Alouette Translator';
  static const String appVersion = '1.0.0';
  static const String appBuild = '1';
  
  // Default LLM Configuration
  static const String defaultProvider = 'ollama';
  static const String defaultServerUrl = 'http://localhost:11434';
  static const List<String> supportedProviders = ['ollama', 'lm_studio'];
  
  // Default Translation Settings
  static const List<String> defaultTargetLanguages = [
    'Chinese',
    'Spanish', 
    'French',
    'German',
    'Japanese',
  ];
  
  static const int maxTextLength = 5000;
  static const int maxSelectedLanguages = 10;
  
  // UI Configuration
  static const double defaultFontSize = 14.0;
  static const double minFontSize = 12.0;
  static const double maxFontSize = 20.0;
  
  // Auto-configuration Settings
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Storage Keys
  static const String llmConfigKey = 'llm_config';
  static const String userPreferencesKey = 'user_preferences';
  static const String translationHistoryKey = 'translation_history';
  
  // Feature Flags
  static const bool enableAutoConfiguration = true;
  static const bool enableTranslationHistory = true;
  static const bool enableOfflineMode = false;
  static const bool enableAnalytics = false;
  
  // Supported Languages for Translation
  static const Map<String, String> supportedLanguages = {
    'Chinese': 'zh',
    'Spanish': 'es',
    'French': 'fr',
    'German': 'de',
    'Japanese': 'ja',
    'Korean': 'ko',
    'Italian': 'it',
    'Portuguese': 'pt',
    'Russian': 'ru',
    'Arabic': 'ar',
    'Hindi': 'hi',
    'Dutch': 'nl',
    'Swedish': 'sv',
    'Norwegian': 'no',
    'Danish': 'da',
    'Finnish': 'fi',
    'Polish': 'pl',
    'Czech': 'cs',
    'Hungarian': 'hu',
    'Turkish': 'tr',
  };
  
  // Error Messages
  static const String noTextError = 'Please enter text to translate';
  static const String noLanguagesError = 'Please select target languages';
  static const String notConfiguredError = 'Please configure LLM settings first';
  static const String connectionError = 'Failed to connect to LLM provider';
  static const String translationError = 'Translation failed';
  
  // Success Messages
  static const String autoConfigSuccessMessage = 'Auto-configuration successful!';
  static const String configUpdatedMessage = 'Configuration updated successfully';
  static const String connectionSuccessMessage = 'Connection successful!';
}