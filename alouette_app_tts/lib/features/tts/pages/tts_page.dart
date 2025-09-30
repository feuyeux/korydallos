import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import '../widgets/tts_input_section.dart';
import '../widgets/tts_control_section.dart';

class TTSPage extends StatefulWidget {
  final ITTSController controller;
  final TextEditingController textController;
  final String? language;

  const TTSPage({
    super.key,
    required this.controller,
    required this.textController,
    this.language,
  });

  @override
  State<TTSPage> createState() => _TTSPageState();
}

class _TTSPageState extends State<TTSPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Column(
        children: [
          // Text input and voice selection - Takes most space
          Expanded(
            flex: 3,
            child: TTSInputSection(
              controller: widget.controller,
              textController: widget.textController,
              language: widget.language,
            ),
          ),

          const SizedBox(height: 2),

          // TTS controls and parameters - Compact at bottom
          TTSControlSection(
            controller: widget.controller,
            textController: widget.textController,
          ),
        ],
      ),
    );
  }
}
