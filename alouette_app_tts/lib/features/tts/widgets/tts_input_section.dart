import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';

/// Widget for text input and voice selection
class TTSInputSection extends StatefulWidget {
  final ITTSController controller;
  final TextEditingController textController;

  const TTSInputSection({
    super.key,
    required this.controller,
    required this.textController,
  });

  @override
  State<TTSInputSection> createState() => _TTSInputSectionState();
}

class _TTSInputSectionState extends State<TTSInputSection> {
  @override
  void initState() {
    super.initState();
    // Sync text controller with TTS controller
    widget.textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    widget.controller.text = widget.textController.text;
  }

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.text_fields, color: AppTheme.primaryColor, size: 14),
                const SizedBox(width: 3),
                const Text(
                  'Text Input',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Text input field
            Expanded(
              child: ModernTextField(
                controller: widget.textController,
                hintText: 'Enter text to speak...',
                maxLines: null,
                expands: true,
                enabled: true,
              ),
            ),

            const SizedBox(height: 6),

            // Voice selection
            if (widget.controller.availableVoices.isNotEmpty)
              _buildVoiceSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.record_voice_over,
              color: AppTheme.primaryColor,
              size: 14,
            ),
            const SizedBox(width: 3),
            const Text(
              'Voice Selection',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Voice dropdown
        Container(
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: widget.controller.selectedVoice,
              isExpanded: true,
              isDense: true,
              hint: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text('Select Voice', style: TextStyle(fontSize: 11)),
              ),
              items: widget.controller.availableVoices
                  .map(
                    (voice) => DropdownMenuItem<String>(
                      value: voice,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          voice,
                          style: const TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (String? voice) {
                if (voice != null) {
                  widget.controller.setVoice(voice);
                }
              },
              icon: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.arrow_drop_down, size: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
