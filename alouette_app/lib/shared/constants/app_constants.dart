class AppConstants {
  // App Information
  static const String appName = 'Alouette App';
  static const String appVersion = '1.0.0';
  
  // Default Configuration
  static const String defaultLLMProvider = 'ollama';
  static const String defaultServerUrl = 'http://localhost:11434';
  
  // Timeouts
  static const Duration ttsInitializationTimeout = Duration(seconds: 10);
  static const Duration translationTimeout = Duration(seconds: 30);
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
}