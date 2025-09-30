import 'package:alouette_lib_tts/alouette_tts.dart';
import 'package:alouette_ui/alouette_ui.dart';

/// Configuration for the TTS Application
/// 
/// Contains only TTS app-specific settings. UI constants should use
/// design tokens from alouette_ui library.
class TTSAppConfig {
  /// Default TTS configuration (uses UI library defaults)
  static const TTSConfig defaultTTSConfig = TTSConfig(
    speechRate: TTSDefaults.speechRate,
    pitch: TTSDefaults.pitch,
    volume: TTSDefaults.volume,
  );

  /// TTS app-specific settings
  static const TTSEngineType? preferredEngine = null; // Auto-detect
  static const bool enableAutoFallback = true;

  /// Application-specific constants
  static const String appTitle = 'Alouette TTS';
  static const String defaultText =
      'Hello, I can read for you. This is a text-to-speech application.';
}
