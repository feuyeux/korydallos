import 'package:flutter_tts/flutter_tts.dart';

import '../core/tts_service.dart';
import '../models/voice.dart';
import '../enums/voice_gender.dart';
import '../enums/voice_quality.dart';

/// Flutter TTS 的实现类
class FlutterTTSService implements TTSService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  String? _currentVoice;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      _initialized = true;
    } catch (e) {
      throw FlutterTTSException('Failed to initialize Flutter TTS: $e');
    }
  }

  @override
  Future<List<Voice>> getVoices() async {
    _checkInitialized();

    try {
      final voices = await _tts.getVoices as List<dynamic>;
      return voices.map((v) => _parseVoice(v)).toList();
    } catch (e) {
      throw FlutterTTSException('Failed to get voices: $e');
    }
  }

  @override
  Future<List<Voice>> getVoicesByLanguage(String languageCode) async {
    final voices = await getVoices();
    return voices.where((v) => v.languageCode == languageCode).toList();
  }

  @override
  Future<void> setVoice(String voiceId) async {
    _checkInitialized();
    await _tts.setVoice({"name": voiceId});
    _currentVoice = voiceId;
  }

  @override
  Future<void> speak(String text) async {
    _checkInitialized();

    if (_currentVoice == null) {
      throw FlutterTTSException('No voice selected');
    }

    if (text.isEmpty) {
      return;
    }

    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  @override
  Future<void> dispose() async {
    await stop();
    _initialized = false;
  }

  void _checkInitialized() {
    if (!_initialized) {
      throw FlutterTTSException('Flutter TTS not initialized');
    }
  }

  Voice _parseVoice(dynamic raw) {
    final Map<String, dynamic> voice = raw as Map<String, dynamic>;

    return Voice(
      id: voice['name'] as String,
      name: voice['name'] as String,
      languageCode: voice['locale'] as String,
      gender: _parseGender(voice['name'] as String),
      quality: VoiceQuality.standard,
      metadata: {
        'flutterTTSName': voice['name'],
        'flutterTTSLocale': voice['locale'],
      },
    );
  }

  VoiceGender _parseGender(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('female') || lower.contains('woman')) {
      return VoiceGender.female;
    } else if (lower.contains('male') || lower.contains('man')) {
      return VoiceGender.male;
    }
    return VoiceGender.neutral;
  }
}

/// Flutter TTS 相关异常
class FlutterTTSException implements Exception {
  final String message;
  FlutterTTSException(this.message);

  @override
  String toString() => 'FlutterTTSException: $message';
}
