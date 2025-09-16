import 'package:flutter/material.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_button.dart';
import '../widgets/compact_slider.dart';

/// TTS控制组件 - 包含参数调节和播放控制
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
    return Row(
      children: [
        // Parameters area
        Expanded(
          flex: 2,
          child: ModernCard(
            padding: const EdgeInsets.all(8.0), // SpacingTokens.s
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune, size: 20),
                    const SizedBox(width: 4), // Reduced spacing
                    Text(
                      'Voice Parameters',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0), // SpacingTokens.l
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: CompactSlider(
                          label: 'Speed',
                          value: rate,
                          min: 0.1,
                          max: 2.0,
                          divisions: 19,
                          onChanged: onRateChanged,
                        ),
                      ),
                      const SizedBox(width: 4), // Reduced spacing
                      Expanded(
                        child: CompactSlider(
                          label: 'Pitch',
                          value: pitch,
                          min: 0.5,
                          max: 2.0,
                          divisions: 15,
                          onChanged: onPitchChanged,
                        ),
                      ),
                      const SizedBox(width: 4), // Reduced spacing
                      Expanded(
                        child: CompactSlider(
                          label: 'Volume',
                          value: volume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          onChanged: onVolumeChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8), // Reduced spacing to prevent overflow

        // Controls area
        Expanded(
          flex: 1,
          child: ModernCard(
            padding: const EdgeInsets.all(8.0), // SpacingTokens.s
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.play_circle_outline, size: 20),
                    const SizedBox(width: 4), // Reduced spacing
                    Expanded(
                      child: Text(
                        'Controls',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0), // SpacingTokens.l
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ModernButton(
                          text: isPlaying ? 'Pause' : 'Speak',
                          icon: isPlaying ? Icons.pause : Icons.play_arrow,
                          onPressed: isInitialized
                              ? (isPlaying ? onStop : onSpeak)
                              : null,
                          type: ModernButtonType.primary,
                          size: ModernButtonSize.large,
                        ),
                      ),
                      const SizedBox(height: 16.0), // SpacingTokens.l
                      SizedBox(
                        width: double.infinity,
                        child: ModernButton(
                          text: 'Stop',
                          icon: Icons.stop,
                          onPressed: isInitialized && isPlaying ? onStop : null,
                          type: ModernButtonType.outline,
                          size: ModernButtonSize.medium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
