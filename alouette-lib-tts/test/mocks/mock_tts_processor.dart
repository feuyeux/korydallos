import 'dart:typed_data';
import 'package:alouette_lib_tts/src/engines/base_tts_processor.dart';
import 'package:alouette_lib_tts/src/models/voice_model.dart';
import 'package:alouette_lib_tts/src/models/tts_error.dart';
import 'package:alouette_lib_tts/src/enums/voice_gender.dart';
import 'package:alouette_lib_tts/src/enums/voice_quality.dart';

/// Mock TTS processor for testing purposes
class MockTTSProcessor implements TTSProcessor {
  List<VoiceModel>? _mockVoices;
  List<int>? _mockAudio;
  bool _shouldFailSynthesis = false;
  bool _shouldFailVoices = false;
  bool _stopCalled = false;
  bool _disposeCalled = false;
  double _speechRate = 1.0;
  double _pitch = 1.0;
  double _volume = 1.0;

  // Getters for test verification
  bool get stopCalled => _stopCalled;
  bool get disposeCalled => _disposeCalled;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;

  void setMockVoices(List<VoiceModel> voices) {
    _mockVoices = voices;
  }

  void setMockAudio(List<int> audio) {
    _mockAudio = audio;
  }

  void setShouldFailSynthesis(bool fail) {
    _shouldFailSynthesis = fail;
  }

  void setShouldFailVoices(bool fail) {
    _shouldFailVoices = fail;
  }

  void reset() {
    _mockVoices = null;
    _mockAudio = null;
    _shouldFailSynthesis = false;
    _shouldFailVoices = false;
    _stopCalled = false;
    _disposeCalled = false;
    _speechRate = 1.0;
    _pitch = 1.0;
    _volume = 1.0;
  }

  @override
  String get engineName => 'mock';

  @override
  Future<List<VoiceModel>> getAvailableVoices() async {
    if (_shouldFailVoices) {
      throw TTSError('Mock voice retrieval error');
    }

    if (_mockVoices != null) {
      return _mockVoices!;
    }

    return [
      VoiceModel(
        id: 'mock-voice-1',
        displayName: 'Mock Voice 1',
        languageCode: 'en-US',
        gender: VoiceGender.female,
        quality: VoiceQuality.neural,
        isNeural: true,
      ),
      VoiceModel(
        id: 'mock-voice-2',
        displayName: 'Mock Voice 2',
        languageCode: 'es-ES',
        gender: VoiceGender.male,
        quality: VoiceQuality.standard,
        isNeural: false,
      ),
    ];
  }

  @override
  Future<Uint8List> synthesizeToAudio(
    String text,
    String voiceName, {
    String format = 'mp3',
  }) async {
    if (_shouldFailSynthesis) {
      throw TTSError('Mock synthesis error');
    }

    if (_mockAudio != null) {
      return Uint8List.fromList(_mockAudio!);
    }

    // Return mock audio data
    return Uint8List.fromList([1, 2, 3, 4, 5]);
  }

  @override
  Future<void> stop() async {
    _stopCalled = true;
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
  }

  @override
  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume;
  }

  @override
  void dispose() {
    _disposeCalled = true;
  }

  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {
    // Mock initialization - always succeeds
  }

  @override
  Future<bool> isAvailable() async {
    return true;
  }

  @override
  Map<String, dynamic> get engineInfo => {
    'name': engineName,
    'version': '1.0.0',
    'platform': 'mock',
    'capabilities': ['synthesis', 'voices'],
  };
}