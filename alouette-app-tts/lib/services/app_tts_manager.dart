import 'package:alouette_lib_tts/alouette_tts.dart';
import 'tts_service_extension.dart';
import 'tts_service_adapter.dart';

/// Simplified TTS Manager for app-tts that reuses library functionality
class AppTTSManager {
  static TTSService? _ttsService;
  static CustomTTSService? _service;
  static VoiceService? _voiceService;
  static AudioPlayer? _audioPlayer;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _ttsService = TTSService();
      await _ttsService!.initialize(autoFallback: true);
      
      _service = CustomTTSService(_ttsService!);
      _voiceService = VoiceService(_ttsService!);
      _audioPlayer = AudioPlayer();
      _isInitialized = true;
      
      TTSLogger.initialization('App TTS Manager', 'completed');
    } catch (e) {
      TTSLogger.error('App TTS Manager initialization failed', e);
      rethrow;
    }
  }

  static CustomTTSService get service {
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
  
  /// 获取TTSService适配器，用于与需要TTSService接口的组件兼容
  static TTSService getTTSServiceAdapter() {
    if (!_isInitialized || _service == null) {
      throw StateError('TTS Manager not initialized');
    }
    return TTSServiceAdapter(_service!);
  }

  static void dispose() {
    _service?.dispose(); // 这会调用内部_ttsService的dispose
    _voiceService?.dispose();
    _ttsService = null;
    _service = null;
    _voiceService = null;
    _audioPlayer = null;
    _isInitialized = false;
  }
}