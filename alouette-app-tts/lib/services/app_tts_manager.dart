import 'package:alouette_lib_tts/alouette_tts.dart';

/// Simplified TTS Manager for app-tts that reuses library functionality
class AppTTSManager {
  static TTSService? _service;
  static VoiceService? _voiceService;
  static AudioPlayer? _audioPlayer;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _service = TTSService();
      await _service!.initialize(autoFallback: true);
      
      _voiceService = VoiceService(_service!);
      _audioPlayer = AudioPlayer();
      _isInitialized = true;
      
      TTSLogger.initialization('App TTS Manager', 'completed');
    } catch (e) {
      TTSLogger.error('App TTS Manager initialization failed', e);
      rethrow;
    }
  }

  static TTSService get service {
    if (!_isInitialized || _service == null) {
      throw StateError('TTS Manager not initialized');
    }
    return _service!;
  }

  static VoiceService get voiceService {
    if (!_isInitialized || _voiceService == null) {
      throw StateError('TTS Manager not initialized');
    }
    return _voiceService!;
  }

  static AudioPlayer get audioPlayer {
    if (!_isInitialized || _audioPlayer == null) {
      throw StateError('TTS Manager not initialized');
    }
    return _audioPlayer!;
  }

  static bool get isInitialized => _isInitialized;
  
  static TTSEngineType? get currentEngine => _service?.currentEngine;

  static void dispose() {
    _service?.dispose();
    _voiceService?.dispose();
    _service = null;
    _voiceService = null;
    _audioPlayer = null;
    _isInitialized = false;
  }
}