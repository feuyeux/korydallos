import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';

/// Widget for displaying TTS status information
class TTSStatusSection extends StatelessWidget {
  final ITTSController controller;
  final VoidCallback? onConfigurePressed;

  const TTSStatusSection({
    super.key,
    required this.controller,
    this.onConfigurePressed,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      child: Row(
        children: [
          // Unified status indicator
          Expanded(
            child: StreamBuilder<bool>(
              stream: controller.speakingStream,
              initialData: controller.isSpeaking,
              builder: (context, speakingSnapshot) {
                return StreamBuilder<String?>(
                  stream: controller.errorStream,
                  initialData: controller.errorMessage,
                  builder: (context, errorSnapshot) {
                    final isSpeaking = speakingSnapshot.data ?? false;
                    final error = errorSnapshot.data;

                    StatusType status;
                    String message;

                    if (error != null) {
                      status = StatusType.error;
                      message = 'TTS Error';
                    } else if (isSpeaking) {
                      status = StatusType.info;
                      message = 'Speaking...';
                    } else {
                      status = StatusType.success;
                      message = 'TTS Ready';
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusIndicator(status: status, message: message),
                        if (controller.selectedVoice != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Voice: ${controller.selectedVoice}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Configure button
          if (onConfigurePressed != null)
            IconButton(
              icon: const Icon(Icons.settings, size: 20),
              onPressed: onConfigurePressed,
              tooltip: 'Configure TTS',
            ),
        ],
      ),
    );
  }

  // Removed duplicate status logic - now using unified StatusIndicator
}
