import 'package:flutter/material.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';
import '../controllers/tts_controller.dart' as local;

/// Widget for text input and voice selection
class TTSInputSection extends StatelessWidget {
  final local.TTSController controller;
  final TextEditingController textController;

  const TTSInputSection({
    super.key,
    required this.controller,
    required this.textController,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.text_fields,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Text Input',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Text input field
          Expanded(
            child: ModernTextField(
              controller: textController,
              hintText: 'Enter text to speak...',
              maxLines: null,
              expands: true,
              enabled: controller.isInitialized,
            ),
          ),

          const SizedBox(height: 16),

          // Voice selection
          if (controller.isInitialized && controller.availableVoices.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Voice Selection',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ModernDropdown<String>(
                  value: controller.currentVoice,
                  items: controller.availableVoices
                      .map((voice) => DropdownMenuItem<String>(
                            value: voice.id,
                            child: Text(
                              voice.displayName.isNotEmpty 
                                  ? voice.displayName 
                                  : voice.id,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: controller.isInitialized
                      ? (String? value) {
                          if (value != null) {
                            controller.changeVoice(value);
                          }
                        }
                      : null,
                  hint: 'Select a voice',
                ),
              ],
            ),

          // Loading indicator when not initialized
          if (!controller.isInitialized)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Initializing TTS...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}