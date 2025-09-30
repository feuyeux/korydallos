/// TTS Service Interface
///
/// Provides an abstraction layer for TTS functionality across all Alouette applications.
/// This interface ensures loose coupling and enables easy testing and mocking.

import 'package:alouette_lib_tts/alouette_tts.dart';

abstract class ITTSService {
  /// Initialize the TTS service
  ///
  /// Returns true if initialization was successful, false otherwise.
  /// Should be called before using any other methods.
  Future<bool> initialize({bool autoFallback = true});

  /// Speak the given text using the specified voice
  ///
  /// [text] - The text to speak
  /// [voiceName] - Optional voice name. If null, uses default voice.
  /// [rate] - Speech rate (0.1 to 2.0, default 1.0)
  /// [volume] - Volume level (0.0 to 1.0, default 1.0)
  /// [pitch] - Pitch level (0.5 to 2.0, default 1.0)
  Future<void> speak(
    String text, {
    String? voiceName,
    double rate = 1.0,
    double volume = 1.0,
    double pitch = 1.0,
  });

  /// Speak the given text using the best voice for the specified language
  ///
  /// [text] - The text to speak
  /// [languageName] - Language name (e.g., "Chinese", "English", "French")
  /// [rate] - Speech rate (0.1 to 2.0, default 1.0)
  /// [volume] - Volume level (0.0 to 1.0, default 1.0)
  /// [pitch] - Pitch level (0.5 to 2.0, default 1.0)
  Future<void> speakInLanguage(
    String text,
    String languageName, {
    double rate = 1.0,
    double volume = 1.0,
    double pitch = 1.0,
  });

  /// Stop current speech
  Future<void> stop();

  /// Pause current speech
  Future<void> pause();

  /// Resume paused speech
  Future<void> resume();

  /// Get list of available voices
  Future<List<TTSVoice>> getAvailableVoices();

  /// Get current TTS engine type
  TTSEngineType? get currentEngine;

  /// Check if TTS is currently speaking
  bool get isSpeaking;

  /// Check if TTS is paused
  bool get isPaused;

  /// Check if TTS service is initialized
  bool get isInitialized;

  /// Switch to a different TTS engine
  Future<void> switchEngine(TTSEngineType engineType);

  /// Dispose resources and cleanup
  void dispose();
}

/// TTS Voice model
class TTSVoice {
  final String name;
  final String language;
  final String? gender;
  final bool isDefault;

  const TTSVoice({
    required this.name,
    required this.language,
    this.gender,
    this.isDefault = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TTSVoice &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          language == other.language;

  @override
  int get hashCode => name.hashCode ^ language.hashCode;

  @override
  String toString() =>
      'TTSVoice(name: $name, language: $language, gender: $gender)';
}
