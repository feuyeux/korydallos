import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart' as tts_lib;
import 'package:alouette_ui_shared/alouette_ui_shared.dart' as ui;

class TTSController {
  // Services
  tts_lib.VoiceService? _voiceService;
  tts_lib.UnifiedTTSService? _ttsService;
  tts_lib.AudioPlayer? _audioPlayer;

  // State notifiers
  final ValueNotifier<bool> isInitializedNotifier = ValueNotifier(false);
  final ValueNotifier<String?> errorMessageNotifier = ValueNotifier(null);
  final ValueNotifier<tts_lib.TTSEngineType?> currentEngineNotifier = ValueNotifier(null);
  final ValueNotifier<String?> currentVoiceNameNotifier = ValueNotifier(null);
  final ValueNotifier<List<tts_lib.VoiceModel>> availableVoicesNotifier = ValueNotifier([]);
  final ValueNotifier<bool> isLoadingVoicesNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);

  Future<void> initialize() async {
    try {
      errorMessageNotifier.value = null;
      isInitializedNotifier.value = false;

      _ttsService = ui.ServiceLocator.get<tts_lib.UnifiedTTSService>();
      _voiceService = tts_lib.VoiceService(_ttsService!);
      _audioPlayer = _ttsService!.audioPlayer;

      currentEngineNotifier.value = _ttsService!.currentEngine;

      await _loadVoices();
      isInitializedNotifier.value = true;
    } catch (e) {
      debugPrint('Failed to initialize TTS services: $e');
      errorMessageNotifier.value = e.toString();
      isInitializedNotifier.value = false;
    }
  }

  Future<void> _loadVoices() async {
    if (_voiceService == null) return;

    try {
      isLoadingVoicesNotifier.value = true;
      final voices = await _voiceService!.getAllVoices();
      availableVoicesNotifier.value = voices;
      
      if (voices.isNotEmpty) {
        currentVoiceNameNotifier.value = voices.first.name;
      }
    } catch (e) {
      debugPrint('Failed to load voices: $e');
      availableVoicesNotifier.value = [];
    } finally {
      isLoadingVoicesNotifier.value = false;
    }
  }

  Future<void> switchEngine(tts_lib.TTSEngineType engineType) async {
    if (_ttsService == null) return;

    try {
      isPlayingNotifier.value = true;
      await _ttsService!.switchEngine(engineType);
      currentEngineNotifier.value = engineType;
      currentVoiceNameNotifier.value = null;
      await _loadVoices();
    } catch (e) {
      debugPrint('Failed to switch engine: $e');
    } finally {
      isPlayingNotifier.value = false;
    }
  }

  void setCurrentVoice(String voiceName) {
    currentVoiceNameNotifier.value = voiceName;
  }

  Future<void> speak(String text) async {
    if (_ttsService == null ||
        currentVoiceNameNotifier.value == null ||
        _audioPlayer == null) {
      return;
    }

    isPlayingNotifier.value = true;
    try {
      final audioData = await _ttsService!.synthesizeText(
        text,
        currentVoiceNameNotifier.value!,
      );
      await _audioPlayer!.playBytes(audioData);
    } on tts_lib.TTSError catch (e) {
      debugPrint('TTS Error: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error: $e');
    } finally {
      isPlayingNotifier.value = false;
    }
  }

  void stop() {
    isPlayingNotifier.value = false;
  }

  void dispose() {
    isInitializedNotifier.dispose();
    errorMessageNotifier.dispose();
    currentEngineNotifier.dispose();
    currentVoiceNameNotifier.dispose();
    availableVoicesNotifier.dispose();
    isLoadingVoicesNotifier.dispose();
    isPlayingNotifier.dispose();
  }
}