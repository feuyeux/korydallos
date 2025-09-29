import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
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
      mainAxisSize: MainAxisSize.min,
      children: [
          // Control buttons
          ModernCard(
            child: Padding(
              padding: const EdgeInsets.all(6.0), // Reduced from 8 to 6
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.play_circle,
                        color: AppTheme.primaryColor,
                        size: 14, // Reduced from 16 to 14
                      ),
                      const SizedBox(width: 3), // Reduced from 4 to 3
                      const Text(
                        'Playback Controls',
                        style: TextStyle(
                          fontSize: 12, // Reduced from 13 to 12
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6), // Reduced from 8 to 6

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
                          size: ModernButtonSize.medium,
                          icon: Icons.play_arrow,
                        ),
                      ),
                      const SizedBox(width: 8), // Reduced from 12 to 8
                      Expanded(
                        child: ModernButton(
                          onPressed: controller.isInitialized && controller.isPlaying
                              ? controller.stopSpeaking
                              : null,
                          text: 'Stop',
                          type: ModernButtonType.secondary,
                          size: ModernButtonSize.medium,
                          icon: Icons.stop,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4), // Reduced from 6 to 4

          // Parameters
          ModernCard(
            child: Padding(
              padding: const EdgeInsets.all(6.0), // Reduced from 8 to 6
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.tune,
                        color: AppTheme.primaryColor,
                        size: 14, // Reduced from 16 to 14
                      ),
                      const SizedBox(width: 3), // Reduced from 4 to 3
                      const Text(
                        'Voice Parameters',
                        style: TextStyle(
                          fontSize: 12, // Reduced from 13 to 12
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6), // Reduced from 8 to 6

                  // Parameter sliders in a row
                  Row(
                    children: [
                      // Rate slider
                      Expanded(
                        child: _buildCompactParameterSlider(
                          context,
                          icon: Icons.speed,
                          label: 'Rate',
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
                      
                      const SizedBox(width: 8),

                      // Pitch slider
                      Expanded(
                        child: _buildCompactParameterSlider(
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
                      
                      const SizedBox(width: 8),

                      // Volume slider
                      Expanded(
                        child: _buildCompactParameterSlider(
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
                ],
              ),
            ),
          ),
        ],
      );
  }



  Widget _buildCompactParameterSlider(
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
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon and label row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: sliderColor, size: 12),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 2),
        
        // Value display
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 1,
          ),
          decoration: BoxDecoration(
            color: sliderColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            valueDisplay,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w500,
              color: sliderColor,
            ),
          ),
        ),
        
        const SizedBox(height: 2),
        
        // Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: sliderColor,
            inactiveTrackColor: sliderColor.withValues(alpha: 0.2),
            thumbColor: sliderColor,
            overlayColor: sliderColor.withValues(alpha: 0.2),
            trackHeight: 2.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
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
    );
  }
}