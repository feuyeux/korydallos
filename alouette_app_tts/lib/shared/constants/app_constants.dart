/// Application-specific constants for the TTS app
class AppConstants {
  // Application metadata
  static const String appName = 'Alouette TTS';
  static const String appVersion = '1.0.0';
  
  // Default values
  static const String defaultSampleText = 'Hello, I can read for you.';
  static const String voiceTestText = 'Hello, this is a voice test.';
  
  // UI constants
  static const double cardPadding = 16.0;
  static const double sectionSpacing = 8.0;
  static const double controlButtonSpacing = 16.0;
  
  // TTS parameter limits (matching config)
  static const double minSpeechRate = 0.1;
  static const double maxSpeechRate = 3.0;
  static const double minPitch = 0.5;
  static const double maxPitch = 2.0;
  static const double minVolume = 0.0;
  static const double maxVolume = 1.0;
  
  // Error messages
  static const String initializationError = 'Failed to initialize TTS service';
  static const String voiceLoadError = 'Failed to load voices';
  static const String speakError = 'Failed to speak text';
  static const String stopError = 'Failed to stop TTS';
  static const String engineSwitchError = 'Failed to switch TTS engine';
}