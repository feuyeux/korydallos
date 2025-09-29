import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_text_field.dart';
import '../widgets/modern_dropdown.dart';
import '../tokens/dimension_tokens.dart';

/// TTS输入组件 - 包含文本输入和语音选择
class TTSInputWidget extends StatelessWidget {
  final TextEditingController textController;
  final String? currentVoice;
  final VoiceService? voiceService;
  final bool isInitialized;
  final ValueChanged<String>? onVoiceChanged;

  const TTSInputWidget({
    super.key,
    required this.textController,
    this.currentVoice,
    this.voiceService,
    required this.isInitialized,
    this.onVoiceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Text input area
        Expanded(
          flex: 2,
          child: ModernCard(
            padding: EdgeInsets.all(SpacingTokens.s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.text_fields, size: 20),
                    const SizedBox(
                        width: 4), // Reduced spacing to avoid overflow
                    Text(
                      'Text Input',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: SpacingTokens.l),
                Expanded(
                  child: ModernTextField(
                    controller: textController,
                    maxLines: null,
                    expands: true,
                    hintText: 'Enter text to speak...',
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8), // Reduced spacing to prevent overflow

        // Voice selection area
        Expanded(
          flex: 1,
          child: ModernCard(
            padding: EdgeInsets.all(SpacingTokens.s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.record_voice_over, size: 20),
                    const SizedBox(width: 4), // Reduced spacing
                    Expanded(
                      child: Text(
                        'Voice',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SpacingTokens.l),
                Expanded(
                  child: _buildVoiceSelector(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceSelector() {
    if (!isInitialized || voiceService == null) {
      return const Center(
        child: Text(
          'TTS not initialized',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return FutureBuilder<List<VoiceModel>>(
      future: voiceService!.getAllVoices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading voices:\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          );
        }

        final voices = snapshot.data ?? [];
        if (voices.isEmpty) {
          return const Center(
            child: Text(
              'No voices available',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ModernDropdown<String>(
          value: currentVoice ?? voices.first.id,
          items: voices
              .map((voice) => DropdownMenuItem<String>(
                    value: voice.id,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          voice.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          voice.languageCode,
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null && onVoiceChanged != null) {
              onVoiceChanged!(value);
            }
          },
        );
      },
    );
  }
}
