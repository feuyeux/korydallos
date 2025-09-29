import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import '../shared/constants/app_constants.dart';

class AppConfig {
  /// Default LLM configuration for translation services
  static LLMConfig get defaultLLMConfig => const LLMConfig(
    provider: AppConstants.defaultLLMProvider,
    serverUrl: AppConstants.defaultServerUrl,
    selectedModel: '',
  );

  /// Default TTS configuration for speech synthesis
  static const TTSConfig defaultTTSConfig = TTSConfig(
    speechRate: 1.0,
    pitch: 1.0,
    volume: 1.0,
  );

  /// Application-specific constants
  static const String appTitle = 'Alouette';
  static const String appVersion = '1.0.0';

  /// Feature flags for the main application
  static const bool enableTranslationFeature = true;
  static const bool enableTTSFeature = true;
  static const bool enableAutoConfiguration = true;
  static const bool enableErrorReporting = true;

  /// TTS parameter ranges for the main application
  static const double minRate = 0.1;
  static const double maxRate = 3.0;
  static const double minPitch = 0.5;
  static const double maxPitch = 2.0;
  static const double minVolume = 0.0;
  static const double maxVolume = 1.0;

  /// Maximum text length for translation and TTS
  static const int maxTextLength = 10000;

  /// Connection timeout settings
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}