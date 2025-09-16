/// UI constants for Alouette applications
/// 
/// This file contains only unique constants that are not covered by the Design Token system.
/// For common sizing, spacing, and styling values, use tokens from the `/tokens` directory.

/// LLM Provider configuration constants
class LLMProviders {
  const LLMProviders._();
  
  static const List<Map<String, String>> providers = [
    {'value': 'ollama', 'name': 'Ollama'},
    {'value': 'lmstudio', 'name': 'LM Studio'},
  ];

  static const Map<String, int> defaultPorts = {
    'ollama': 11434,
    'lmstudio': 1234,
  };

  static const Map<String, String> defaultUrls = {
    'ollama': 'http://localhost:11434',
    'lmstudio': 'http://localhost:1234/v1',
  };

  static const Map<String, String> apiPaths = {
    'ollama': '/api/generate',
    'lmstudio': '/chat/completions',
  };
}

/// TTS service configuration constants
class TTSDefaults {
  const TTSDefaults._();
  
  static const double speechRate = 1.0;
  static const double volume = 1.0;
  static const double pitch = 1.0;
}

/// AI model configuration constants  
class ModelDefaults {
  const ModelDefaults._();
  
  static const String defaultModel = 'qwen2.5:latest';
  static const String fallbackModel = 'qwen2.5:1.5b';
}

/// App-specific UI sizes that don't fit into the general design token system
class AppSpecificSizes {
  const AppSpecificSizes._();
  
  // Component-specific heights that are unique to this app
  static const double languageSelectionHeight = 110.0;
  static const double fixedLanguageChipsHeight = 72.0;
  static const double textInputHeight = 60.0;
  static const double textInputHeightCompact = 48.0;
  
  // Component-specific widths
  static const double compactButtonWidth = 80.0;
  
  // Material design elevation values
  static const double cardElevation = 2.0;
  static const double cardElevationHover = 4.0;
}

/// Legacy aliases for backward compatibility - DEPRECATED
/// Use the corresponding design tokens instead
@Deprecated('Use SpacingTokens.l instead')
class UISizes {
  @Deprecated('Use SpacingTokens.l instead')
  static const double spacingM = 16.0;
  
  @Deprecated('Use AppSpecificSizes.languageSelectionHeight instead')
  static const double languageSelectionHeight = AppSpecificSizes.languageSelectionHeight;
  
  @Deprecated('Use AppSpecificSizes.fixedLanguageChipsHeight instead')
  static const double fixedLanguageChipsHeight = AppSpecificSizes.fixedLanguageChipsHeight;
}

/// Legacy text styles - DEPRECATED  
/// Use TypographyTokens instead
@Deprecated('Use TypographyTokens instead')
class TextStyles {
  @Deprecated('Use TypographyTokens.bodySmall.fontSize instead')
  static const double smallFontSize = 10.0;
  @Deprecated('Use TypographyTokens.bodyMedium.fontSize instead')
  static const double mediumFontSize = 12.0;
}
