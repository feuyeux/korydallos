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
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Control buttons
          ModernCard(
            child: Padding(
              padding: const EdgeInsets.all(8.0), // Reduced from 12 to 8
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.play_circle,
                        color: AppTheme.primaryColor,
                        size: 16, // Reduced from 18 to 16
                      ),
                      const SizedBox(width: 4), // Reduced from 6 to 4
                      const Text(
                        'Playback Controls',
                        style: TextStyle(
                          fontSize: 13, // Reduced from 14 to 13
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8), // Reduced from 12 to 8
                  // Control buttons
                  Row(
                    children: [
                      Expanded(
                        child: ModernButton(
                          onPressed:
                              controller.isInitialized &&
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
                          onPressed:
                              controller.isInitialized && controller.isPlaying
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

          const SizedBox(height: 6), // Reduced from 8 to 6
          // Parameters
          ModernCard(
            child: Padding(
              padding: const EdgeInsets.all(8.0), // Reduced from 12 to 8
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
                        size: 16, // Reduced from 18 to 16
                      ),
                      const SizedBox(width: 4), // Reduced from 6 to 4
                      const Text(
                        'Voice Parameters',
                        style: TextStyle(
                          fontSize: 13, // Reduced from 14 to 13
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8), // Reduced from 12 to 8
                  // Parameter sliders
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Rate slider
                      _buildParameterSlider(
                        context,
                        icon: Icons.speed,
                        label: 'Speech Rate',
                        value: controller.rate,
                        min: TTSAppConfig.minRate,
                        max: TTSAppConfig.maxRate,
                        divisions: 29,
                        valueDisplay: '${controller.rate.toStringAsFixed(1)}x',
                        onChanged: controller.isInitialized
                            ? (v) async {
                                await controller.updateRate(v);
                                if (controller.isPlaying) {
                                  await controller.stopSpeaking();
                                  if (textController.text.trim().isNotEmpty) {
                                    await controller.speakText(
                                      textController.text.trim(),
                                    );
                                  }
                                }
                              }
                            : null,
                      ),

                      // Pitch slider
                      _buildParameterSlider(
                        context,
                        icon: Icons.piano,
                        label: 'Pitch',
                        value: controller.pitch,
                        min: TTSAppConfig.minPitch,
                        max: TTSAppConfig.maxPitch,
                        divisions: 15,
                        valueDisplay: '${controller.pitch.toStringAsFixed(1)}x',
                        onChanged: controller.isInitialized
                            ? (v) async {
                                await controller.updatePitch(v);
                                if (controller.isPlaying) {
                                  await controller.stopSpeaking();
                                  if (textController.text.trim().isNotEmpty) {
                                    await controller.speakText(
                                      textController.text.trim(),
                                    );
                                  }
                                }
                              }
                            : null,
                      ),

                      // Volume slider
                      _buildParameterSlider(
                        context,
                        icon: Icons.volume_up,
                        label: 'Volume',
                        value: controller.volume,
                        min: TTSAppConfig.minVolume,
                        max: TTSAppConfig.maxVolume,
                        divisions: 10,
                        valueDisplay: '${(controller.volume * 100).toInt()}%',
                        onChanged: controller.isInitialized
                            ? (v) async {
                                await controller.updateVolume(v);
                                if (controller.isPlaying) {
                                  await controller.stopSpeaking();
                                  if (textController.text.trim().isNotEmpty) {
                                    await controller.speakText(
                                      textController.text.trim(),
                                    );
                                  }
                                }
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 1.0), // Reduced from 2 to 1
      child: Row(
        children: [
          Container(
            width: 20, // Reduced from 24 to 20
            height: 20, // Reduced from 24 to 20
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: sliderColor.withValues(alpha: 0.1),
            ),
            child: Icon(
              icon,
              color: sliderColor,
              size: 12,
            ), // Reduced from 14 to 12
          ),
          const SizedBox(width: 6), // Reduced from 8 to 6
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
                        fontSize: 11, // Reduced from 12 to 11
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3, // Reduced from 4 to 3
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: sliderColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          2,
                        ), // Reduced from 3 to 2
                      ),
                      child: Text(
                        valueDisplay,
                        style: TextStyle(
                          fontSize: 9, // Reduced from 10 to 9
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
                    trackHeight: 2.0, // Reduced from 2.5 to 2.0
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ), // Smaller thumb
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
