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
    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldScroll =
            !constraints.hasBoundedHeight || constraints.maxHeight < 360;

        final content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Control buttons
            CustomCard(
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
                          child: CustomButton(
                            onPressed:
                                controller.isInitialized &&
                                    !controller.isPlaying &&
                                    textController.text.trim().isNotEmpty
                                ? () =>
                                      controller.speakText(textController.text)
                                : null,
                            text: 'Speak',
                            type: CustomButtonType.primary,
                            size: CustomButtonSize.medium,
                            icon: Icons.play_arrow,
                          ),
                        ),
                        const SizedBox(width: 8), // Reduced from 12 to 8
                        Expanded(
                          child: CustomButton(
                            onPressed:
                                controller.isInitialized && controller.isPlaying
                                ? controller.stopSpeaking
                                : null,
                            text: 'Stop',
                            type: CustomButtonType.secondary,
                            size: CustomButtonSize.medium,
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
            CustomCard(
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
                    // Parameter sliders - 3 in one row
                    Row(
                      children: [
                        // Speech Rate slider
                        Expanded(
                          child: _buildCompactSlider(
                            context,
                            icon: Icons.speed,
                            label: 'Rate',
                            value: controller.rate,
                            min: TTSAppConfig.minRate,
                            max: TTSAppConfig.maxRate,
                            divisions: 29,
                            valueDisplay:
                                '${controller.rate.toStringAsFixed(1)}x',
                            onChanged: controller.isInitialized
                                ? (v) async {
                                    await controller.updateRate(v);
                                    if (controller.isPlaying) {
                                      await controller.stopSpeaking();
                                      if (textController.text
                                          .trim()
                                          .isNotEmpty) {
                                        await controller.speakText(
                                          textController.text.trim(),
                                        );
                                      }
                                    }
                                  }
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Pitch slider
                        Expanded(
                          child: _buildCompactSlider(
                            context,
                            icon: Icons.piano,
                            label: 'Pitch',
                            value: controller.pitch,
                            min: TTSAppConfig.minPitch,
                            max: TTSAppConfig.maxPitch,
                            divisions: 15,
                            valueDisplay:
                                '${controller.pitch.toStringAsFixed(1)}x',
                            onChanged: controller.isInitialized
                                ? (v) async {
                                    await controller.updatePitch(v);
                                    if (controller.isPlaying) {
                                      await controller.stopSpeaking();
                                      if (textController.text
                                          .trim()
                                          .isNotEmpty) {
                                        await controller.speakText(
                                          textController.text.trim(),
                                        );
                                      }
                                    }
                                  }
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Volume slider
                        Expanded(
                          child: _buildCompactSlider(
                            context,
                            icon: Icons.volume_up,
                            label: 'Volume',
                            value: controller.volume,
                            min: TTSAppConfig.minVolume,
                            max: TTSAppConfig.maxVolume,
                            divisions: 10,
                            valueDisplay:
                                '${(controller.volume * 100).toInt()}%',
                            onChanged: controller.isInitialized
                                ? (v) async {
                                    await controller.updateVolume(v);
                                    if (controller.isPlaying) {
                                      await controller.stopSpeaking();
                                      if (textController.text
                                          .trim()
                                          .isNotEmpty) {
                                        await controller.speakText(
                                          textController.text.trim(),
                                        );
                                      }
                                    }
                                  }
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

        if (shouldScroll) {
          return SingleChildScrollView(child: content);
        }

        return Align(alignment: Alignment.topCenter, child: content);
      },
    );
  }

  Widget _buildCompactSlider(
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: sliderColor, size: 18),
        const SizedBox(height: 4),
        Text(
          valueDisplay,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          activeColor: sliderColor,
          inactiveColor: sliderColor.withValues(alpha: 0.3),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }
}
