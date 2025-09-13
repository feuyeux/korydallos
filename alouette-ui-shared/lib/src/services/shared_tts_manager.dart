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
      await _service!.initialize(autoFallback: true);
      
      _voiceService = VoiceService(_service!);
      _audioPlayer = AudioPlayer();
      _isInitialized = true;
      
      print('Shared TTS Manager: Initialized with ${_service!.currentEngine} engine');
    } catch (e) {
      print('TTS initialization error: $e');
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

      final audioData = await service.synthesizeText(text, selectedVoice);
      await audioPlayer.playBytes(audioData);
    } catch (e) {
      print('Error speaking text: $e');
      rethrow;
    }
  }
}