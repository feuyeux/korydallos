import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';

/// Settings page for TTS configuration
class TTSSettingsPage extends StatefulWidget {
  final ITTSController controller;

  const TTSSettingsPage({super.key, required this.controller});

  @override
  State<TTSSettingsPage> createState() => _TTSSettingsPageState();
}

class _TTSSettingsPageState extends State<TTSSettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: 'TTS Settings',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voice Information
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Voice Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    'Selected Voice',
                    widget.controller.selectedVoice ?? 'None',
                  ),
                  _buildInfoRow(
                    'Available Voices',
                    widget.controller.availableVoices.length.toString(),
                  ),
                  _buildInfoRow(
                    'Speaking',
                    widget.controller.isSpeaking ? 'Yes' : 'No',
                  ),
                  _buildInfoRow(
                    'Paused',
                    widget.controller.isPaused ? 'Yes' : 'No',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Voice Parameters
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Voice Parameters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildParameterSlider(
                    'Speech Rate',
                    widget.controller.speechRate,
                    0.0,
                    1.0,
                    '${(widget.controller.speechRate * 2).toStringAsFixed(1)}x',
                    widget.controller.setSpeechRate,
                  ),
                  const SizedBox(height: 16),
                  _buildParameterSlider(
                    'Pitch',
                    widget.controller.speechPitch,
                    0.0,
                    1.0,
                    '${(widget.controller.speechPitch * 2).toStringAsFixed(1)}x',
                    widget.controller.setSpeechPitch,
                  ),
                  const SizedBox(height: 16),
                  _buildParameterSlider(
                    'Volume',
                    widget.controller.speechVolume,
                    0.0,
                    1.0,
                    '${(widget.controller.speechVolume * 100).toInt()}%',
                    widget.controller.setSpeechVolume,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildParameterSlider(
    String label,
    double value,
    double min,
    double max,
    String displayValue,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(displayValue),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 10).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
