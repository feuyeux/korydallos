import 'package:alouette_lib_tts/alouette_tts.dart';

/// Configuration for the TTS Application
class TTSAppConfig {
  /// Default TTS configuration
  static const TTSConfig defaultTTSConfig = TTSConfig(
    speechRate: 1.0,
    pitch: 1.0,
    volume: 1.0,
  );

  /// Preferred TTS engine for this application
  static const TTSEngineType? preferredEngine = null; // Auto-detect

  /// Enable auto-fallback when preferred engine fails
  static const bool enableAutoFallback = true;

  /// Application-specific constants
  static const String appTitle = 'Alouette TTS';
  static const String defaultText =
      'Hello, I can read for you. This is a text-to-speech application.';

  /// TTS parameter ranges
  static const double minRate = 0.1;
  static const double maxRate = 3.0;
  static const double minPitch = 0.5;
  static const double maxPitch = 2.0;
  static const double minVolume = 0.0;
  static const double maxVolume = 1.0;
}
