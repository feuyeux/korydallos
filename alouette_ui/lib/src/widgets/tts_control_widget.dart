import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import '../components/organisms/tts_control_panel.dart';
import '../components/molecules/voice_selector.dart';

/// TTS Control Widget - Migrated to use Atomic Design
/// 
/// This widget now uses the new TTSControlPanel organism component
/// for consistent UI across all applications.
class TTSControlWidget extends StatelessWidget {
  final double rate;
  final double pitch;
  final double volume;
  final bool isPlaying;
  final bool isInitialized;
  final ValueChanged<double> onRateChanged;
  final ValueChanged<double> onPitchChanged;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onSpeak;
  final VoidCallback onStop;

  const TTSControlWidget({
    super.key,
    required this.rate,
    required this.pitch,
    required this.volume,
    required this.isPlaying,
    required this.isInitialized,
    required this.onRateChanged,
    required this.onPitchChanged,
    required this.onVolumeChanged,
    required this.onSpeak,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    // Create a default voice model for backward compatibility
    final defaultVoice = VoiceModel(
      id: 'default',
      displayName: 'Default Voice',
      languageCode: 'en-US',
      gender: VoiceGender.neutral,
      quality: VoiceQuality.standard,
    );

    return TTSControlPanel(
      selectedVoice: defaultVoice,
      availableVoices: [defaultVoice],
      onVoiceChanged: null, // Not used in this legacy widget
      currentText: null, // Not provided in legacy interface
      onPlay: onSpeak,
      onPause: onStop, // Legacy widget doesn't distinguish pause/stop
      onStop: onStop,
      isPlaying: isPlaying,
      isPaused: false, // Legacy widget doesn't track pause state
      isLoading: !isInitialized,
      volume: volume,
      onVolumeChanged: onVolumeChanged,
      speechRate: rate,
      onSpeechRateChanged: onRateChanged,
      pitch: pitch,
      onPitchChanged: onPitchChanged,
      showAdvancedControls: true, // Show all controls for legacy compatibility
    );
  }
}
