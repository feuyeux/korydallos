import 'package:flutter/material.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';
import '../controllers/tts_controller.dart' as local;
import '../../../config/tts_app_config.dart';

/// Widget for TTS controls and parameters
class TTSControlSection extends StatelessWidget {
  final local.TTSController controller;
  final TextEditingController textController;

  const TTSControlSection({
    super.key,
    required this.controller,
    required this.textController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Control buttons
        ModernCard(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.play_circle,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Playback Controls',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Control buttons
                Row(
                  children: [
                    Expanded(
                      child: ModernButton(
                        onPressed: controller.isInitialized && 
                                 !controller.isPlaying &&
                                 textController.text.trim().isNotEmpty
                            ? () => controller.speakText(textController.text)
                            : null,
                        text: 'Speak',
                        type: ModernButtonType.primary,
                        size: ModernButtonSize.large,
                        icon: Icons.play_arrow,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ModernButton(
                        onPressed: controller.isInitialized && controller.isPlaying
                            ? controller.stopSpeaking
                            : null,
                        text: 'Stop',
                        type: ModernButtonType.secondary,
                        size: ModernButtonSize.large,
                        icon: Icons.stop,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Parameters
        Expanded(
          child: ModernCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.tune,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Voice Parameters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Parameter sliders
                  Expanded(
                    child: Column(
                      children: [
                        // Rate slider
                        Expanded(
                          child: _buildParameterSlider(
                            context,
                            icon: Icons.speed,
                            label: 'Speech Rate',
                            value: controller.rate,
                            min: TTSAppConfig.minRate,
                            max: TTSAppConfig.maxRate,
                            divisions: 29,
                            valueDisplay: '${controller.rate.toStringAsFixed(1)}x',
                            onChanged: controller.isInitialized
                                ? controller.updateRate
                                : null,
                          ),
                        ),

                        // Pitch slider
                        Expanded(
                          child: _buildParameterSlider(
                            context,
                            icon: Icons.piano,
                            label: 'Pitch',
                            value: controller.pitch,
                            min: TTSAppConfig.minPitch,
                            max: TTSAppConfig.maxPitch,
                            divisions: 15,
                            valueDisplay: '${controller.pitch.toStringAsFixed(1)}x',
                            onChanged: controller.isInitialized
                                ? controller.updatePitch
                                : null,
                          ),
                        ),

                        // Volume slider
                        Expanded(
                          child: _buildParameterSlider(
                            context,
                            icon: Icons.volume_up,
                            label: 'Volume',
                            value: controller.volume,
                            min: TTSAppConfig.minVolume,
                            max: TTSAppConfig.maxVolume,
                            divisions: 10,
                            valueDisplay: '${(controller.volume * 100).toInt()}%',
                            onChanged: controller.isInitialized
                                ? controller.updateVolume
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParameterSlider(
    BuildContext context, {
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String valueDisplay,
    required Function(double)? onChanged,
  }) {
    final sliderColor = AppTheme.primaryColor;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: sliderColor.withValues(alpha: 0.1),
            ),
            child: Icon(icon, color: sliderColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: sliderColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        valueDisplay,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: sliderColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: sliderColor,
                    inactiveTrackColor: sliderColor.withValues(alpha: 0.2),
                    thumbColor: sliderColor,
                    overlayColor: sliderColor.withValues(alpha: 0.2),
                    trackHeight: 3.0,
                  ),
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: divisions,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}