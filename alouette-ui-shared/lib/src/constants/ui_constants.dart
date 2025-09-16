/// UI constants for Alouette applications

/// LLM Provider constants
class LLMProviders {
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

/// App configuration constants
class AppDefaults {
  static const String defaultModel = 'qwen2.5:latest';
  static const String fallbackModel = 'qwen2.5:1.5b';

  // TTS defaults
  static const double defaultSpeechRate = 1.0;
  static const double defaultVolume = 1.0;
  static const double defaultPitch = 1.0;

  // UI spacing
  static const double defaultPadding = 16.0;
  static const double compactPadding = 8.0;
  static const double largePadding = 24.0;

  // Animation durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 200);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
}

/// UI sizing constants
class UISizes {
  // Input widget heights
  static const double textInputHeight = 60.0;
  static const double textInputHeightCompact = 48.0;

  // Border radius
  static const double inputBorderRadius = 8.0;
  static const double buttonBorderRadius = 8.0;
  static const double languageSelectionHeight = 110.0;

  // Card dimensions
  static const double cardBorderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const double cardElevationHover = 4.0;

  // Button dimensions - 优化按钮尺寸标准（更紧凑美观）
  static const double buttonHeightSmall = 28.0; // 小按钮 - 减少4px
  static const double buttonHeightMedium = 32.0; // 中等按钮 - 减少8px
  static const double buttonHeightLarge = 36.0; // 大按钮 - 减少12px
  static const double buttonMinWidth = 56.0; // 最小按钮宽度 - 减少8px
  static const double compactButtonWidth = 80.0; // 紧凑按钮宽度 - 增加20px避免溢出

  // Icon sizes - 统一图标尺寸
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeLarge = 24.0;

  // Icon size aliases for compatibility
  static const double smallIconSize = iconSizeSmall;
  static const double mediumIconSize = iconSizeMedium;
  static const double largeIconSize = iconSizeLarge;

  // Spacing
  static const double spacingXxs = 2.0;
  static const double spacingXs = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;
  static const double fixedLanguageChipsHeight = 72.0;

  // Border radius
  static const double borderRadiusS = 4.0;
  static const double borderRadiusM = 8.0;

  // Dialog sizes
  static const double configDialogWidth = 500.0;
}

/// Text style constants
class TextStyles {
  static const double smallFontSize = 10.0;
  static const double mediumFontSize = 12.0;
  static const double largeFontSize = 14.0;
  static const double titleFontSize = 16.0;
}
