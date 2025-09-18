# Alouette API Documentation

Complete API reference for all public interfaces and services in the Alouette ecosystem.

## Table of Contents

- [Translation Services](#translation-services)
- [TTS Services](#tts-services)
- [UI Components](#ui-components)
- [Service Management](#service-management)
- [Configuration Management](#configuration-management)
- [Theme Management](#theme-management)
- [Data Models](#data-models)
- [Error Handling](#error-handling)

## Translation Services

### TranslationService

The main service for AI-powered translation functionality.

#### Methods

##### `translateToMultipleLanguages`

Translates text to multiple target languages simultaneously.

```dart
Future<TranslationResult> translateToMultipleLanguages(
  String sourceText,
  List<String> targetLanguages,
  LLMConfig config,
) async
```

**Parameters:**
- `sourceText` (String): The text to translate
- `targetLanguages` (List<String>): List of target language codes (e.g., ['es', 'fr', 'de'])
- `config` (LLMConfig): LLM configuration including provider, server URL, and model

**Returns:** `TranslationResult` containing translations for each target language

**Example:**
```dart
final translationService = ServiceManager.getTranslationService();
final config = LLMConfig(
  provider: 'ollama',
  serverUrl: 'http://localhost:11434',
  selectedModel: 'llama3.2',
);

final result = await translationService.translateToMultipleLanguages(
  'Hello, world!',
  ['es', 'fr', 'de'],
  config,
);

print(result.translations['es']); // "¡Hola, mundo!"
```

##### `testConnection`

Tests connectivity to the configured LLM provider.

```dart
Future<ConnectionStatus> testConnection(LLMConfig config) async
```

**Parameters:**
- `config` (LLMConfig): LLM configuration to test

**Returns:** `ConnectionStatus` indicating success/failure and details

##### `getAvailableModels`

Retrieves available models from the LLM provider.

```dart
Future<List<String>> getAvailableModels(LLMConfig config) async
```

**Parameters:**
- `config` (LLMConfig): LLM configuration

**Returns:** List of available model names

### LLMConfigService

Service for managing LLM configuration and connection testing.

#### Methods

##### `saveConfig`

Saves LLM configuration to persistent storage.

```dart
Future<void> saveConfig(LLMConfig config) async
```

##### `loadConfig`

Loads LLM configuration from persistent storage.

```dart
Future<LLMConfig?> loadConfig() async
```

##### `testConnection`

Tests connection to LLM provider with given configuration.

```dart
Future<Map<String, dynamic>> testConnection(LLMConfig config) async
```

## TTS Services

### UnifiedTTSService

The main service providing unified text-to-speech functionality across all platforms.

#### Methods

##### `initialize`

Initializes the TTS service with optional engine preference.

```dart
Future<void> initialize({TTSEngineType? preferredEngine}) async
```

**Parameters:**
- `preferredEngine` (TTSEngineType?, optional): Preferred TTS engine (edge, flutter)

**Example:**
```dart
final ttsService = UnifiedTTSService();
await ttsService.initialize(preferredEngine: TTSEngineType.edge);
```

##### `getVoices`

Retrieves available voices for the current engine.

```dart
Future<List<VoiceModel>> getVoices() async
```

**Returns:** List of available voices with metadata

##### `synthesizeText`

Synthesizes text to audio data.

```dart
Future<Uint8List> synthesizeText(
  String text,
  String voiceName, {
  String format = 'mp3',
}) async
```

**Parameters:**
- `text` (String): Text to synthesize
- `voiceName` (String): Voice identifier
- `format` (String, optional): Audio format (mp3, wav, etc.)

**Returns:** Audio data as bytes

##### `switchEngine`

Switches to a different TTS engine at runtime.

```dart
Future<void> switchEngine(TTSEngineType engineType) async
```

**Parameters:**
- `engineType` (TTSEngineType): Target engine type

#### Properties

##### `currentEngine`

Gets the currently active TTS engine.

```dart
TTSEngineType? get currentEngine
```

##### `isInitialized`

Checks if the service is initialized.

```dart
bool get isInitialized
```

### TTSProcessor (Abstract)

Base interface for TTS engine implementations.

#### Methods

##### `getVoices`

```dart
Future<List<VoiceModel>> getVoices() async
```

##### `synthesizeText`

```dart
Future<Uint8List> synthesizeText(
  String text,
  String voiceName, {
  String format = 'mp3',
}) async
```

##### `dispose`

```dart
void dispose()
```

#### Properties

##### `engineName`

```dart
String get engineName
```

### AudioPlayer

Cross-platform audio player for TTS-generated content.

#### Methods

##### `playBytes`

Plays audio from byte data.

```dart
Future<void> playBytes(
  Uint8List audioData, {
  String format = 'mp3',
}) async
```

##### `play`

Plays audio from file path.

```dart
Future<void> play(String filePath) async
```

##### `stop`

Stops current playback.

```dart
Future<void> stop() async
```

## UI Components

### Atoms

#### AlouetteButton

Consistent button component with multiple variants.

```dart
AlouetteButton({
  Key? key,
  required String text,
  required VoidCallback? onPressed,
  AlouetteButtonVariant variant = AlouetteButtonVariant.primary,
  AlouetteButtonSize size = AlouetteButtonSize.medium,
  IconData? icon,
  bool isLoading = false,
  bool isEnabled = true,
})
```

**Parameters:**
- `text` (String): Button text
- `onPressed` (VoidCallback?): Callback when pressed
- `variant` (AlouetteButtonVariant): Visual variant (primary, secondary, tertiary, destructive)
- `size` (AlouetteButtonSize): Size variant (small, medium, large)
- `icon` (IconData?, optional): Optional icon
- `isLoading` (bool): Show loading indicator
- `isEnabled` (bool): Enable/disable button

**Example:**
```dart
AlouetteButton(
  text: 'Translate',
  onPressed: () => handleTranslate(),
  variant: AlouetteButtonVariant.primary,
  size: AlouetteButtonSize.large,
  icon: Icons.translate,
)
```

#### AlouetteTextField

Unified text input component.

```dart
AlouetteTextField({
  Key? key,
  TextEditingController? controller,
  String? labelText,
  String? hintText,
  String? errorText,
  bool obscureText = false,
  TextInputType keyboardType = TextInputType.text,
  ValueChanged<String>? onChanged,
  VoidCallback? onEditingComplete,
  int? maxLines = 1,
  bool enabled = true,
})
```

#### AlouetteSlider

Consistent slider component with labels and icons.

```dart
AlouetteSlider({
  Key? key,
  required double value,
  required ValueChanged<double> onChanged,
  double min = 0.0,
  double max = 1.0,
  int? divisions,
  String? label,
  IconData? icon,
  bool enabled = true,
})
```

### Molecules

#### LanguageSelector

Dropdown-based language selection component.

```dart
LanguageSelector({
  Key? key,
  required List<LanguageOption> availableLanguages,
  required String? selectedLanguage,
  required ValueChanged<String?> onLanguageChanged,
  String? labelText,
  bool enabled = true,
})
```

#### VoiceSelector

Voice selection dropdown for TTS.

```dart
VoiceSelector({
  Key? key,
  required List<VoiceModel> availableVoices,
  required String? selectedVoice,
  required ValueChanged<String?> onVoiceChanged,
  String? labelText,
  bool enabled = true,
})
```

#### StatusIndicator

Comprehensive status display with actions.

```dart
StatusIndicator({
  Key? key,
  required StatusType status,
  required String message,
  String? details,
  List<StatusAction>? actions,
  bool showIcon = true,
  bool isCompact = false,
})
```

### Organisms

#### TranslationPanel

Complete translation interface with input, language selection, and results.

```dart
TranslationPanel({
  Key? key,
  required TextEditingController textController,
  required List<String> selectedLanguages,
  required ValueChanged<List<String>> onLanguagesChanged,
  required VoidCallback onTranslate,
  required VoidCallback onClear,
  Map<String, String>? translationResults,
  bool isTranslating = false,
  String? errorMessage,
  bool isCompact = false,
})
```

#### TTSControlPanel

Comprehensive TTS interface with voice selection and controls.

```dart
TTSControlPanel({
  Key? key,
  required TextEditingController textController,
  required List<VoiceModel> availableVoices,
  required String? selectedVoice,
  required ValueChanged<String?> onVoiceChanged,
  required VoidCallback onPlay,
  required VoidCallback onStop,
  double speechRate = 1.0,
  double volume = 1.0,
  double pitch = 1.0,
  ValueChanged<double>? onSpeechRateChanged,
  ValueChanged<double>? onVolumeChanged,
  ValueChanged<double>? onPitchChanged,
  bool isPlaying = false,
  bool showAdvancedControls = false,
})
```

#### ConfigDialog

Multi-section configuration interface.

```dart
ConfigDialog({
  Key? key,
  required String title,
  required List<ConfigSection> sections,
  required VoidCallback onSave,
  required VoidCallback onCancel,
  VoidCallback? onReset,
  bool showAdvanced = false,
})
```

## Service Management

### ServiceManager

High-level service management with lifecycle control.

#### Methods

##### `initialize`

Initializes services based on configuration.

```dart
static Future<ServiceInitializationResult> initialize(
  ServiceConfiguration configuration,
) async
```

**Parameters:**
- `configuration` (ServiceConfiguration): Service configuration

**Returns:** `ServiceInitializationResult` with success status and any errors

##### `getTTSService`

Gets the initialized TTS service.

```dart
static UnifiedTTSService getTTSService()
```

##### `getTranslationService`

Gets the initialized translation service.

```dart
static TranslationService getTranslationService()
```

##### `getServiceStatus`

Gets current service status.

```dart
static Map<String, bool> getServiceStatus()
```

##### `dispose`

Disposes all services and cleans up resources.

```dart
static Future<void> dispose() async
```

### ServiceLocator

Core dependency injection container.

#### Methods

##### `register`

Registers a service instance.

```dart
static void register<T>(T service)
```

##### `registerFactory`

Registers a factory function for lazy creation.

```dart
static void registerFactory<T>(T Function() factory)
```

##### `registerSingleton`

Registers a singleton factory.

```dart
static void registerSingleton<T>(T Function() factory)
```

##### `get`

Retrieves a registered service.

```dart
static T get<T>()
```

##### `isRegistered`

Checks if a service type is registered.

```dart
static bool isRegistered<T>()
```

##### `clear`

Clears all registered services.

```dart
static void clear()
```

### ServiceConfiguration

Configuration for service initialization.

#### Constructors

```dart
const ServiceConfiguration({
  required bool initializeTTS,
  required bool initializeTranslation,
  bool ttsAutoFallback = true,
  bool verboseLogging = false,
  int initializationTimeoutMs = 30000,
})
```

#### Predefined Configurations

```dart
// For TTS-only applications
ServiceConfiguration.ttsOnly

// For translation-only applications
ServiceConfiguration.translationOnly

// For combined applications
ServiceConfiguration.combined

// For testing (no services)
ServiceConfiguration.testing
```

## Configuration Management

### ConfigurationManager

Centralized configuration management service.

#### Methods

##### `initialize`

Initializes the configuration manager.

```dart
Future<void> initialize() async
```

##### `getConfiguration`

Gets the current configuration.

```dart
Future<AppConfiguration> getConfiguration() async
```

##### `updateConfiguration`

Updates the entire configuration.

```dart
Future<bool> updateConfiguration(AppConfiguration config) async
```

##### `resetToDefaults`

Resets configuration to default values.

```dart
Future<void> resetToDefaults() async
```

#### UI Preferences

##### `setThemeMode`

```dart
Future<void> setThemeMode(String themeMode) async
```

##### `getThemeMode`

```dart
Future<String> getThemeMode() async
```

##### `setPrimaryLanguage`

```dart
Future<void> setPrimaryLanguage(String languageCode) async
```

##### `getPrimaryLanguage`

```dart
Future<String> getPrimaryLanguage() async
```

##### `setFontScale`

```dart
Future<void> setFontScale(double scale) async
```

##### `getFontScale`

```dart
Future<double> getFontScale() async
```

#### App Settings

##### `setAppSetting`

```dart
Future<void> setAppSetting<T>(String key, T value) async
```

##### `getAppSetting`

```dart
Future<T?> getAppSetting<T>(String key) async
```

##### `updateAppSettings`

```dart
Future<void> updateAppSettings(Map<String, dynamic> settings) async
```

#### Validation

##### `isConfigurationValid`

```dart
Future<bool> isConfigurationValid() async
```

##### `getConfigurationErrors`

```dart
Future<List<String>> getConfigurationErrors() async
```

##### `validateConfiguration`

```dart
Future<Map<String, dynamic>> validateConfiguration() async
```

#### Export/Import

##### `exportConfiguration`

```dart
Future<String> exportConfiguration() async
```

##### `importConfiguration`

```dart
Future<bool> importConfiguration(String configJson) async
```

#### Reactive Updates

##### `configurationStream`

Stream of configuration changes.

```dart
Stream<AppConfiguration> get configurationStream
```

## Theme Management

### ThemeService

Advanced theme management with customization support.

#### Methods

##### `setThemeMode`

```dart
void setThemeMode(AlouetteThemeMode mode)
```

##### `setUseCustomColors`

```dart
void setUseCustomColors(bool useCustom)
```

##### `setCustomPrimaryColor`

```dart
void setCustomPrimaryColor(Color color)
```

##### `getLightTheme`

```dart
ThemeData getLightTheme()
```

##### `getDarkTheme`

```dart
ThemeData getDarkTheme()
```

#### Properties

##### `themeMode`

```dart
AlouetteThemeMode get themeMode
```

##### `useCustomColors`

```dart
bool get useCustomColors
```

### Design Tokens

#### ColorTokens

Semantic color system.

```dart
class ColorTokens {
  // Primary colors
  static const Color primary = Color(0xFF3B82F6);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFDBEAFE);
  
  // Surface colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1F2937);
  
  // Functional colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}
```

#### TypographyTokens

Material Design 3 typography scale.

```dart
class TypographyTokens {
  static const TextStyle displayLargeStyle = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    height: 1.12,
  );
  
  static const TextStyle headlineLargeStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    height: 1.25,
  );
  
  static const TextStyle bodyLargeStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
}
```

#### SpacingTokens

Consistent spacing scale.

```dart
class SpacingTokens {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}
```

## Data Models

### Translation Models

#### TranslationResult

```dart
class TranslationResult {
  final String sourceText;
  final Map<String, String> translations;
  final DateTime timestamp;
  final bool isSuccessful;
  final String? errorMessage;
  
  const TranslationResult({
    required this.sourceText,
    required this.translations,
    required this.timestamp,
    required this.isSuccessful,
    this.errorMessage,
  });
}
```

#### LLMConfig

```dart
class LLMConfig {
  final String provider;
  final String serverUrl;
  final String? apiKey;
  final String selectedModel;
  final Map<String, dynamic> additionalSettings;
  
  const LLMConfig({
    required this.provider,
    required this.serverUrl,
    this.apiKey,
    required this.selectedModel,
    this.additionalSettings = const {},
  });
}
```

### TTS Models

#### VoiceModel

```dart
class VoiceModel {
  final String name;
  final String displayName;
  final String language;
  final String gender;
  final String locale;
  final bool isNeural;
  final bool isStandard;
  
  const VoiceModel({
    required this.name,
    required this.displayName,
    required this.language,
    required this.gender,
    required this.locale,
    required this.isNeural,
    required this.isStandard,
  });
}
```

#### TTSConfig

```dart
class TTSConfig {
  final TTSEngineType engineType;
  final double speechRate;
  final double volume;
  final double pitch;
  final Map<String, dynamic> engineSpecificSettings;
  
  const TTSConfig({
    required this.engineType,
    this.speechRate = 1.0,
    this.volume = 1.0,
    this.pitch = 1.0,
    this.engineSpecificSettings = const {},
  });
}
```

### Configuration Models

#### AppConfiguration

```dart
class AppConfiguration {
  final LLMConfig? translationConfig;
  final TTSConfig? ttsConfig;
  final UIPreferences uiPreferences;
  final Map<String, dynamic> appSettings;
  final DateTime lastUpdated;
  final String version;
  
  const AppConfiguration({
    this.translationConfig,
    this.ttsConfig,
    required this.uiPreferences,
    this.appSettings = const {},
    required this.lastUpdated,
    required this.version,
  });
}
```

#### UIPreferences

```dart
class UIPreferences {
  final String themeMode;
  final String primaryLanguage;
  final double fontScale;
  final bool showAdvancedOptions;
  final bool enableAnimations;
  final WindowPreferences? windowPreferences;
  final Map<String, dynamic> customSettings;
  
  const UIPreferences({
    this.themeMode = 'system',
    this.primaryLanguage = 'en',
    this.fontScale = 1.0,
    this.showAdvancedOptions = false,
    this.enableAnimations = true,
    this.windowPreferences,
    this.customSettings = const {},
  });
}
```

## Error Handling

### Exception Types

#### TranslationException

Base exception for translation-related errors.

```dart
class TranslationException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  const TranslationException(
    this.message, {
    this.code,
    this.originalError,
  });
}
```

#### TTSError

Base error class for TTS-related issues.

```dart
class TTSError extends Error {
  final String message;
  final String? code;
  final dynamic originalError;
  
  TTSError(
    this.message, {
    this.code,
    this.originalError,
  });
}
```

#### ServiceNotRegisteredException

Thrown when accessing unregistered services.

```dart
class ServiceNotRegisteredException implements Exception {
  final String message;
  final Type serviceType;
  
  const ServiceNotRegisteredException(
    this.message,
    this.serviceType,
  );
}
```

### Error Codes

#### Translation Error Codes

```dart
class TranslationErrorCodes {
  static const String connectionFailed = 'TRANSLATION_CONNECTION_FAILED';
  static const String authenticationFailed = 'TRANSLATION_AUTH_FAILED';
  static const String modelNotFound = 'TRANSLATION_MODEL_NOT_FOUND';
  static const String timeout = 'TRANSLATION_TIMEOUT';
  static const String invalidResponse = 'TRANSLATION_INVALID_RESPONSE';
  static const String rateLimited = 'TRANSLATION_RATE_LIMITED';
}
```

#### TTS Error Codes

```dart
class TTSErrorCodes {
  static const String engineNotAvailable = 'TTS_ENGINE_NOT_AVAILABLE';
  static const String voiceNotFound = 'TTS_VOICE_NOT_FOUND';
  static const String synthesisFailed = 'TTS_SYNTHESIS_FAILED';
  static const String audioPlaybackFailed = 'TTS_PLAYBACK_FAILED';
  static const String initializationFailed = 'TTS_INIT_FAILED';
}
```

### Error Handling Patterns

#### Service Error Handling

```dart
try {
  final result = await translationService.translateToMultipleLanguages(
    text,
    languages,
    config,
  );
  // Handle success
} on TranslationException catch (e) {
  switch (e.code) {
    case TranslationErrorCodes.connectionFailed:
      // Handle connection error
      break;
    case TranslationErrorCodes.authenticationFailed:
      // Handle auth error
      break;
    default:
      // Handle generic error
  }
} catch (e) {
  // Handle unexpected errors
}
```

#### UI Error Handling

```dart
StatusIndicator(
  status: hasError ? StatusType.error : StatusType.success,
  message: errorMessage ?? 'Operation completed successfully',
  actions: hasError ? [
    StatusAction(
      label: 'Retry',
      onPressed: () => retryOperation(),
    ),
    StatusAction(
      label: 'Report Issue',
      onPressed: () => reportIssue(),
    ),
  ] : null,
)
```

## Usage Examples

### Complete Translation Workflow

```dart
class TranslationWorkflow {
  final TranslationService _translationService;
  final ConfigurationManager _configManager;
  
  TranslationWorkflow()
    : _translationService = ServiceManager.getTranslationService(),
      _configManager = ConfigurationManager.instance;
  
  Future<void> performTranslation(
    String text,
    List<String> targetLanguages,
  ) async {
    try {
      // Get current configuration
      final config = await _configManager.getConfiguration();
      final llmConfig = config.translationConfig;
      
      if (llmConfig == null) {
        throw TranslationException('Translation not configured');
      }
      
      // Perform translation
      final result = await _translationService.translateToMultipleLanguages(
        text,
        targetLanguages,
        llmConfig,
      );
      
      if (result.isSuccessful) {
        // Handle successful translation
        _handleTranslationSuccess(result);
      } else {
        // Handle translation failure
        _handleTranslationError(result.errorMessage);
      }
    } on TranslationException catch (e) {
      _handleTranslationError(e.message);
    } catch (e) {
      _handleTranslationError('Unexpected error: $e');
    }
  }
  
  void _handleTranslationSuccess(TranslationResult result) {
    // Update UI with results
    print('Translations: ${result.translations}');
  }
  
  void _handleTranslationError(String? error) {
    // Show error to user
    print('Translation error: $error');
  }
}
```

### Complete TTS Workflow

```dart
class TTSWorkflow {
  final UnifiedTTSService _ttsService;
  final AudioPlayer _audioPlayer;
  
  TTSWorkflow()
    : _ttsService = ServiceManager.getTTSService(),
      _audioPlayer = AudioPlayer();
  
  Future<void> synthesizeAndPlay(String text, String voiceName) async {
    try {
      // Synthesize text to audio
      final audioData = await _ttsService.synthesizeText(text, voiceName);
      
      // Play the audio
      await _audioPlayer.playBytes(audioData);
      
      print('TTS synthesis and playback completed');
    } on TTSError catch (e) {
      switch (e.code) {
        case TTSErrorCodes.voiceNotFound:
          print('Voice not available: ${e.message}');
          break;
        case TTSErrorCodes.synthesisFailed:
          print('Synthesis failed: ${e.message}');
          break;
        default:
          print('TTS error: ${e.message}');
      }
    } catch (e) {
      print('Unexpected TTS error: $e');
    }
  }
  
  Future<List<VoiceModel>> getAvailableVoices() async {
    try {
      return await _ttsService.getVoices();
    } catch (e) {
      print('Failed to get voices: $e');
      return [];
    }
  }
}
```

This API documentation provides comprehensive coverage of all public interfaces and services in the Alouette ecosystem. For implementation details and examples, refer to the individual library documentation and example applications.