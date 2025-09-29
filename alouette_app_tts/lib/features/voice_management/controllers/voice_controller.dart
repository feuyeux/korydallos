import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import 'package:alouette_ui/alouette_ui.dart';

/// Controller for voice management functionality
class VoiceController extends ChangeNotifier {
  // TTS Service from ServiceLocator
  UnifiedTTSService? _ttsService;
  
  // State variables
  List<VoiceModel> _voices = [];
  String? _selectedVoiceId;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<VoiceModel> get voices => _voices;
  String? get selectedVoiceId => _selectedVoiceId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load available voices
  Future<void> loadVoices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get TTS service from ServiceLocator
      _ttsService = ServiceLocator.get<UnifiedTTSService>();
      
      // Initialize if not already initialized
      if (!_ttsService!.isInitialized) {
        await _ttsService!.initialize();
      }
      
      // Load voices
      _voices = await _ttsService!.getVoices();
      
      // Set default selected voice if none selected
      if (_selectedVoiceId == null && _voices.isNotEmpty) {
        _selectedVoiceId = _voices.first.id;
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load voices: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a voice
  void selectVoice(String voiceId) {
    if (_selectedVoiceId != voiceId) {
      _selectedVoiceId = voiceId;
      notifyListeners();
    }
  }

  /// Test a voice by speaking sample text
  Future<void> testVoice(String voiceId) async {
    if (_ttsService == null || !_ttsService!.isInitialized) {
      return;
    }

    try {
      const sampleText = 'Hello, this is a voice test.';
      await _ttsService!.speakText(sampleText, voiceName: voiceId);
    } catch (e) {
      _error = 'Failed to test voice: $e';
      notifyListeners();
    }
  }

  /// Get voice by ID
  VoiceModel? getVoiceById(String voiceId) {
    try {
      return _voices.firstWhere((voice) => voice.id == voiceId);
    } catch (e) {
      return null;
    }
  }

  /// Get voices by language
  List<VoiceModel> getVoicesByLanguage(String languageCode) {
    return _voices.where((voice) => 
        voice.languageCode.startsWith(languageCode)).toList();
  }

  /// Get voices by gender
  List<VoiceModel> getVoicesByGender(VoiceGender gender) {
    return _voices.where((voice) => voice.gender == gender).toList();
  }

  /// Get neural voices only
  List<VoiceModel> getNeuralVoices() {
    return _voices.where((voice) => voice.isNeural).toList();
  }

  /// Clear error
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}