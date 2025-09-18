import '../../../config/translation_app_config.dart';

/// Application-wide constants for the Translation App
class AppConstants {
  // Re-export configuration constants for easy access
  static const String appName = TranslationAppConfig.appName;
  static const String appVersion = TranslationAppConfig.appVersion;
  static const String appBuild = TranslationAppConfig.appBuild;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  static const double defaultBorderRadius = 8.0;
  static const double smallBorderRadius = 4.0;
  static const double largeBorderRadius = 12.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Breakpoints for responsive design
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;
  
  // Translation-specific constants
  static const int maxTextLength = TranslationAppConfig.maxTextLength;
  static const int maxSelectedLanguages = TranslationAppConfig.maxSelectedLanguages;
  
  // Default values
  static const List<String> defaultTargetLanguages = TranslationAppConfig.defaultTargetLanguages;
}