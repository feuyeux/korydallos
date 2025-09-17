import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';

/// Shared TTS Manager for all Alouette applications
/// Provides a unified interface for TTS functionality across apps
class SharedTTSManager {
  static TTSService? _service;
  static VoiceService? _voiceService;
  static AudioPlayer? _audioPlayer;
  static bool _isInitialized = false;

  /// Get TTS service instance with automatic initialization
  static Future<TTSService> getService() async {
    if (!_isInitialized) {
      await _initializeServices();
    }
    return _service!;
  }

  /// Get voice service instance
  static Future<VoiceService> getVoiceService() async {
    if (!_isInitialized) {
      await _initializeServices();
    }
    return _voiceService!;
  }

  /// Get audio player instance
  static AudioPlayer getAudioPlayer() {
    if (_audioPlayer == null) {
      throw Exception('TTS Manager not initialized. Call getService() first.');
    }
    return _audioPlayer!;
  }

  /// Initialize all TTS services
  static Future<void> _initializeServices() async {
    if (_isInitialized) return;

    try {
      _service = TTSService();

      // On macOS, force Edge TTS as preferred engine
      TTSEngineType? preferredEngine;
      if (!kIsWeb && Platform.isMacOS) {
        preferredEngine = TTSEngineType.edge;
        print(
            '[TTS] DEBUG: macOS detected - forcing Edge TTS as preferred engine');

        // Quick check if edge-tts is available
        try {
          final quickCheck = await Process.run('which', ['edge-tts'])
              .timeout(Duration(seconds: 3));
          if (quickCheck.exitCode == 0) {
            print(
                '[TTS] DEBUG: Quick check confirms edge-tts is available at: ${quickCheck.stdout.toString().trim()}');
          } else {
            print(
                '[TTS] DEBUG: Quick check failed, but will still try Edge TTS');
          }
        } catch (e) {
          print(
              '[TTS] DEBUG: Quick edge-tts check failed: $e, but will still try Edge TTS');
        }
      }

      print(
          '[TTS] DEBUG: Initializing TTS service with preferredEngine: ${preferredEngine?.name ?? 'auto'}');
      await _service!.initialize(
        preferredEngine: preferredEngine,
        autoFallback: true,
      );

      _voiceService = VoiceService(_service!);
      _audioPlayer = AudioPlayer();
      _isInitialized = true;

      print('[TTS] DEBUG: TTS service initialized successfully');
      print(
          '[TTS] DEBUG: Current engine: ${_service!.currentEngine?.name ?? 'unknown'}');
      print(
          '[TTS] DEBUG: Current backend: ${_service!.currentBackend ?? 'unknown'}');

      // Get platform diagnostics
      final platformInfo = await _service!.getPlatformInfo();
      print('[TTS] DEBUG: Platform info: $platformInfo');
    } catch (e) {
      print('[TTS] ERROR: TTS initialization failed: $e');
      rethrow;
    }
  }

  /// Get current engine type
  static TTSEngineType? get currentEngine => _service?.currentEngine;

  /// Switch TTS engine
  static Future<void> switchEngine(TTSEngineType engineType) async {
    if (_service != null) {
      await _service!.switchEngine(engineType);
    }
  }

  /// Dispose resources
  static Future<void> dispose() async {
    if (_isInitialized && _service != null) {
      _service!.dispose();
      _voiceService?.dispose();
      _service = null;
      _voiceService = null;
      _audioPlayer = null;
      _isInitialized = false;
    }
  }

  /// Check if initialized
  static bool get isInitialized => _isInitialized;

  /// Helper method for simple text-to-speech with default settings
  static Future<void> speakText(String text, {String? voiceName}) async {
    try {
      print(
          '[TTS] DEBUG: Starting speech synthesis for: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."');

      final service = await getService();
      final voiceService = await getVoiceService();
      final audioPlayer = getAudioPlayer();

      // Use provided voice or first available voice
      String selectedVoice = voiceName ?? '';
      if (selectedVoice.isEmpty) {
        final voices = await voiceService.getAllVoices();
        if (voices.isNotEmpty) {
          selectedVoice = voices.first.name;
        } else {
          throw Exception('No voices available for TTS');
        }
      }

      print('[TTS] DEBUG: Using voice: $selectedVoice');

      final audioData = await service.synthesizeText(text, selectedVoice);
      print('[TTS] DEBUG: Audio data size: ${audioData.length} bytes');

      // Check if this is minimal audio data (direct playback mode)
      if (audioData.length <= 10) {
        print(
            '[TTS] DEBUG: Using direct playback mode - no additional audio processing needed');
        return; // Direct playback has already occurred
      }

      await audioPlayer.playBytes(audioData);
      print('[TTS] DEBUG: Audio playback completed');
    } catch (e) {
      print('[TTS] ERROR: Speech synthesis failed: $e');
      rethrow;
    }
  }
}
