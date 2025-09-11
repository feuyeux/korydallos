import 'package:alouette_lib_tts/alouette_tts.dart';

/// Simplified TTS Manager - delegates to library services
class TTSManager {
  static TTSService? _service;
  static VoiceService? _voiceService;
  static AudioPlayer? _audioPlayer;
  static bool _isInitialized = false;

  /// Get TTS service instance
  static Future<TTSService> getService() async {
    if (!_isInitialized) {
      try {
        _service = TTSService();
        await _service!.initialize(autoFallback: true);
        
        _voiceService = VoiceService(_service!);
        _audioPlayer = AudioPlayer();
        _isInitialized = true;
        
        print('TTS Manager: Initialized with ${_service!.currentEngine} engine');
      } catch (e) {
        print('TTS initialization error: $e');
        rethrow;
      }
    }
    return _service!;
  }

  /// Get voice service instance
  static Future<VoiceService> getVoiceService() async {
    await getService(); // Ensure initialization
    return _voiceService!;
  }

  /// Get audio player instance
  static AudioPlayer getAudioPlayer() {
    if (_audioPlayer == null) {
      throw Exception('TTS Manager not initialized. Call getService() first.');
    }
    return _audioPlayer!;
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
}
