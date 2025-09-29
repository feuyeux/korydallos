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
      padding: const EdgeInsets.all(4.0),
      child: Column(
        children: [
          // Text input and voice selection - Reduced height
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.28, // Reduced from 35% to 28%
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
          
          const SizedBox(height: 4), // Reduced from 8 to 4
          
          // TTS controls and parameters - Flexible remaining space
          Expanded(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, child) {
                return TTSControlSection(
                  controller: widget.controller,
                  textController: widget.textController,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}