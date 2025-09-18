import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';
import '../../../config/tts_app_config.dart';

/// Controller for TTS functionality using UnifiedTTSService from ServiceLocator
class TTSController extends ChangeNotifier {
  // TTS Service from ServiceLocator
  UnifiedTTSService? _ttsService;
  
  // State variables
  bool _isInitialized = false;
  bool _isPlaying = false;
  String? _currentVoice;
  List<VoiceModel> _availableVoices = [];
  TTSEngineType? _currentEngine;
  
  // TTS parameters
  double _rate = TTSAppConfig.defaultTTSConfig.speechRate;
  double _pitch = TTSAppConfig.defaultTTSConfig.pitch;
  double _volume = TTSAppConfig.defaultTTSConfig.volume;
  
  // Error handling
  String? _lastError;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isPlaying => _isPlaying;
  String? get currentVoice => _currentVoice;
  List<VoiceModel> get availableVoices => _availableVoices;
  TTSEngineType? get currentEngine => _currentEngine;
  double get rate => _rate;
  double get pitch => _pitch;
  double get volume => _volume;
  String? get lastError => _lastError;

  /// Initialize TTS service from ServiceLocator
  Future<void> initialize() async {
    try {
      _clearError();
      
      // Get TTS service from ServiceLocator
      _ttsService = ServiceLocator.get<UnifiedTTSService>();
      
      // Initialize if not already initialized
      if (!_ttsService!.isInitialized) {
        await _ttsService!.initialize(
          preferredEngine: TTSAppConfig.preferredEngine,
          autoFallback: TTSAppConfig.enableAutoFallback,
          config: TTSAppConfig.defaultTTSConfig,
        );
      }
      
      // Load available voices
      await _loadVoices();
      
      // Update current engine
      _currentEngine = _ttsService!.currentEngine;
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize TTS: $e');
      _isInitialized = true; // Set to true to show error state
      notifyListeners();
    }
  }

  /// Load available voices
  Future<void> _loadVoices() async {
    try {
      _availableVoices = await _ttsService!.getVoices();
      
      // Set default voice if none selected
      if (_currentVoice == null && _availableVoices.isNotEmpty) {
        _currentVoice = _availableVoices.first.id;
      }
    } catch (e) {
      _setError('Failed to load voices: $e');
    }
  }

  /// Speak the provided text
  Future<void> speakText(String text) async {
    if (!_isInitialized || _ttsService == null || text.trim().isEmpty) {
      return;
    }

    try {
      _clearError();
      _isPlaying = true;
      notifyListeners();

      // Update TTS parameters before speaking
      await _updateTTSParameters();

      // Speak the text
      await _ttsService!.speakText(
        text,
        voiceName: _currentVoice,
      );

      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      _isPlaying = false;
      _setError('Failed to speak text: $e');
      notifyListeners();
    }
  }

  /// Stop current TTS operation
  Future<void> stopSpeaking() async {
    if (!_isInitialized || _ttsService == null) {
      return;
    }

    try {
      await _ttsService!.stop();
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      _setError('Failed to stop TTS: $e');
      _isPlaying = false;
      notifyListeners();
    }
  }

  /// Change the current voice
  Future<void> changeVoice(String voiceId) async {
    if (_currentVoice == voiceId) return;

    _currentVoice = voiceId;
    notifyListeners();
  }

  /// Update speech rate
  Future<void> updateRate(double newRate) async {
    if (_rate == newRate) return;

    _rate = newRate.clamp(TTSAppConfig.minRate, TTSAppConfig.maxRate);
    
    if (_isInitialized && _ttsService != null) {
      try {
        await _ttsService!.setSpeechRate(_rate);
      } catch (e) {
        _setError('Failed to update speech rate: $e');
      }
    }
    
    notifyListeners();
  }

  /// Update pitch
  Future<void> updatePitch(double newPitch) async {
    if (_pitch == newPitch) return;

    _pitch = newPitch.clamp(TTSAppConfig.minPitch, TTSAppConfig.maxPitch);
    
    if (_isInitialized && _ttsService != null) {
      try {
        await _ttsService!.setPitch(_pitch);
      } catch (e) {
        _setError('Failed to update pitch: $e');
      }
    }
    
    notifyListeners();
  }

  /// Update volume
  Future<void> updateVolume(double newVolume) async {
    if (_volume == newVolume) return;

    _volume = newVolume.clamp(TTSAppConfig.minVolume, TTSAppConfig.maxVolume);
    
    if (_isInitialized && _ttsService != null) {
      try {
        await _ttsService!.setVolume(_volume);
      } catch (e) {
        _setError('Failed to update volume: $e');
      }
    }
    
    notifyListeners();
  }

  /// Switch TTS engine
  Future<void> switchEngine(TTSEngineType engineType) async {
    if (!_isInitialized || _ttsService == null || _currentEngine == engineType) {
      return;
    }

    try {
      _clearError();
      
      await _ttsService!.switchEngine(
        engineType,
        autoFallback: TTSAppConfig.enableAutoFallback,
      );
      
      _currentEngine = engineType;
      
      // Reload voices for new engine
      await _loadVoices();
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to switch engine: $e');
      notifyListeners();
    }
  }

  /// Get platform information
  Future<Map<String, dynamic>> getPlatformInfo() async {
    if (!_isInitialized || _ttsService == null) {
      return {};
    }

    try {
      return await _ttsService!.getPlatformInfo();
    } catch (e) {
      _setError('Failed to get platform info: $e');
      return {};
    }
  }

  /// Update TTS parameters on the service
  Future<void> _updateTTSParameters() async {
    if (_ttsService == null) return;

    try {
      await _ttsService!.updateConfig(TTSConfig(
        speechRate: _rate,
        pitch: _pitch,
        volume: _volume,
      ));
    } catch (e) {
      // Log error but don't throw - parameters might not be critical
      _setError('Warning: Failed to update TTS parameters: $e');
    }
  }

  /// Set error message
  void _setError(String error) {
    _lastError = error;
  }

  /// Clear error message
  void _clearError() {
    _lastError = null;
  }

  @override
  void dispose() {
    // Don't dispose the TTS service as it's managed by ServiceLocator
    // and might be used by other parts of the application
    super.dispose();
  }
}