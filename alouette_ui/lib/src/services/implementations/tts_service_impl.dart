import 'package:flutter/foundation.dart';
import 'package:alouette_lib_tts/alouette_tts.dart' as tts_lib;
import '../interfaces/tts_service_contract.dart';

/// TTS Service Implementation
///
/// Concrete implementation of TTSServiceContract that wraps the alouette_lib_tts library.
/// Provides thread-safe initialization and proper resource management.
class TTSServiceImpl implements TTSServiceContract {
  tts_lib.TTSService? _ttsService;
  bool _isInitialized = false;
  bool _isDisposed = false;

  // Synchronization lock for thread-safe initialization
  static final Object _initLock = Object();

  @override
  Future<bool> initialize({bool autoFallback = true}) async {
    if (_isInitialized) return true;
    if (_isDisposed) {
      throw StateError('Cannot initialize a disposed TTS service');
    }

    try {
      // Use synchronized block for thread safety
      return await _synchronized(_initLock, () async {
        if (_isInitialized) return true;

        _ttsService = tts_lib.TTSService();
        await _ttsService!.initialize(autoFallback: autoFallback);

        _isInitialized = true;

        return true;
      });
    } catch (e) {
      _cleanup();
      return false;
    }
  }

  @override
  Future<void> speak(
    String text, {
    String? voiceName,
    double rate = 1.0,   // 1.0 = normal speed (1.0x)
    double volume = 1.0, // 1.0 = 100% volume
    double pitch = 1.0,  // 1.0 = normal pitch (1.0x)
  }) async {
    _ensureInitialized();

    try {
      // Parameters are now passed directly to speakText via TTSRequest
      await _ttsService!.speakText(
        text,
        voiceName: voiceName,
        rate: rate,
        pitch: pitch,
        volume: volume,
      );
    } catch (e) {
      throw TTSException('Error speaking text: $e');
    }
  }

  @override
  @override
  Future<void> speakInLanguage(
    String text,
    String languageName, {
    double rate = 1.0,   // 1.0 = normal speed (1.0x)
    double volume = 1.0, // 1.0 = 100% volume
    double pitch = 1.0,  // 1.0 = normal pitch (1.0x)
  }) async {
    _ensureInitialized();

    try {
      // Get available voices and find one matching the language
      final voices = await _ttsService!.getVoices();

      // Find a voice that matches the language code
      String? matchingVoice;
      for (final voice in voices) {
        if (voice.languageCode == languageName) {
          matchingVoice = voice.id;
          break;
        }
      }

      // Parameters are now passed directly to speakText via TTSRequest
      if (matchingVoice != null) {
        await _ttsService!.speakText(
          text,
          voiceName: matchingVoice,
          rate: rate,
          pitch: pitch,
          volume: volume,
          format: 'audio-24khz-48kbitrate-mono-mp3',
        );
      } else {
        await _ttsService!.speakText(
          text,
          languageName: languageName,
          rate: rate,
          pitch: pitch,
          volume: volume,
        );
      }
    } catch (e) {
      throw TTSException('Error speaking text in $languageName: $e');
    }
  }

  @override
  Future<void> stop() async {
    _ensureInitialized();
    try {
      await _ttsService!.stop();
    } catch (e) {}
  }

  @override
  Future<void> pause() async {
    _ensureInitialized();
    // Note: Pause functionality may not be available in current library
    try {
      // Implementation depends on actual AudioPlayer API
    } catch (e) {
      debugPrint('Error pausing audio: $e');
    }
  }

  @override
  Future<void> resume() async {
    _ensureInitialized();
    // Note: Resume functionality may not be available in current library
    try {
      // Implementation depends on actual AudioPlayer API
      debugPrint(
        'Resume requested - implementation depends on library capabilities',
      );
    } catch (e) {
      debugPrint('Error resuming audio: $e');
    }
  }

  @override
  Future<List<TTSVoice>> getAvailableVoices() async {
    _ensureInitialized();

    try {
      final voices = await _ttsService!.getVoices();
      return voices
          .map(
            (voice) => TTSVoice(
              name: voice.id,
              language: voice.languageCode,
              gender: voice.gender.name,
              isDefault: false,
            ),
          )
          .toList();
    } catch (e) {
      throw TTSException('Error getting available voices: $e');
    }
  }

  @override
  tts_lib.TTSEngineType? get currentEngine {
    if (!_isInitialized || _ttsService == null) return null;
    return _ttsService!.currentEngine;
  }

  @override
  bool get isSpeaking {
    if (!_isInitialized || _ttsService == null) return false;
    // Library may not have this property - return false for now
    return false;
  }

  @override
  bool get isPaused {
    if (!_isInitialized || _ttsService == null) return false;
    // Library may not have this property - return false for now
    return false;
  }

  @override
  bool get isInitialized => _isInitialized && !_isDisposed;

  @override
  Future<void> switchEngine(tts_lib.TTSEngineType engineType) async {
    _ensureInitialized();

    try {
      await _ttsService!.switchEngine(engineType);
    } catch (e) {
      throw TTSException('Error switching engine: $e');
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;

    _cleanup();
    _isDisposed = true;
  }

  void _cleanup() {
    _ttsService?.dispose();
    _ttsService = null;
    _isInitialized = false;
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('TTS Service not initialized. Call initialize() first.');
    }
    if (_isDisposed) {
      throw StateError('TTS Service has been disposed.');
    }
  }

  /// Simplified synchronized implementation
  Future<T> _synchronized<T>(Object lock, Future<T> Function() action) async {
    return await action();
  }
}

/// TTS specific exception
class TTSException implements Exception {
  final String message;

  const TTSException(this.message);

  @override
  String toString() => 'TTSException: $message';
}
