import 'package:flutter/material.dart';
import '../controllers/tts_controller.dart' as local;
import '../widgets/tts_input_section.dart';
import '../widgets/tts_control_section.dart';

class TTSPage extends StatefulWidget {
  final local.TTSController controller;
  final TextEditingController textController;
  
  const TTSPage({
    super.key,
    required this.controller,
    required this.textController,
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
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, child) {
                return TTSInputSection(
                  controller: widget.controller,
                  textController: widget.textController,
                );
              },
            ),
          ),
          
          const SizedBox(height: 2),
          
          // TTS controls and parameters - Compact at bottom
          ListenableBuilder(
            listenable: widget.controller,
            builder: (context, child) {
              return TTSControlSection(
                controller: widget.controller,
                textController: widget.textController,
              );
            },
          ),
        ],
      ),
    );
  }
}