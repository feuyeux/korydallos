import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';

class TTSPage extends StatefulWidget {
  const TTSPage({super.key});

  @override
  State<TTSPage> createState() => _TTSPageState();
}

class _TTSPageState extends State<TTSPage> with AutoControllerDisposal {
  late final ITTSController _controller;
  final TextEditingController _textController = TextEditingController(
    text: 'Hello, this is a test message.',
  );

  @override
  void initState() {
    super.initState();
    _controller = createTTSController();
    _controller.text = _textController.text;
    // Sync text controller with TTS controller
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _controller.text = _textController.text;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Voice selector
          if (_controller.availableVoices.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice Selection',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _controller.selectedVoice,
                  isExpanded: true,
                  items: _controller.availableVoices.map((voice) {
                    return DropdownMenuItem(value: voice, child: Text(voice));
                  }).toList(),
                  onChanged: (voiceName) {
                    if (voiceName != null) {
                      _controller.setVoice(voiceName);
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),

          // Speech parameters
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Speech Parameters',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  // Speech Rate
                  Text(
                    'Rate: ${(_controller.speechRate * 2).toStringAsFixed(1)}x',
                  ),
                  Slider(
                    value: _controller.speechRate,
                    onChanged: (value) => _controller.setSpeechRate(value),
                    min: 0.0,
                    max: 1.0,
                  ),

                  // Speech Pitch
                  Text(
                    'Pitch: ${(_controller.speechPitch * 2).toStringAsFixed(1)}x',
                  ),
                  Slider(
                    value: _controller.speechPitch,
                    onChanged: (value) => _controller.setSpeechPitch(value),
                    min: 0.0,
                    max: 1.0,
                  ),

                  // Speech Volume
                  Text('Volume: ${(_controller.speechVolume * 100).toInt()}%'),
                  Slider(
                    value: _controller.speechVolume,
                    onChanged: (value) => _controller.setSpeechVolume(value),
                    min: 0.0,
                    max: 1.0,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Text input
          TextField(
            controller: _textController,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter text to speak',
              labelText: 'Text to Synthesize',
            ),
            onChanged: (text) => _controller.text = text,
          ),

          const SizedBox(height: 16),

          // Control buttons
          Row(
            children: [
              Expanded(
                child: StreamBuilder<bool>(
                  stream: _controller.speakingStream,
                  initialData: _controller.isSpeaking,
                  builder: (context, snapshot) {
                    final isSpeaking = snapshot.data ?? false;
                    return ElevatedButton.icon(
                      onPressed: isSpeaking
                          ? () => _controller.stop()
                          : () {
                              _controller.text = _textController.text;
                              _controller.speak();
                            },
                      icon: Icon(isSpeaking ? Icons.stop : Icons.play_arrow),
                      label: Text(isSpeaking ? 'Stop' : 'Speak'),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              StreamBuilder<bool>(
                stream: _controller.pausedStream,
                initialData: _controller.isPaused,
                builder: (context, snapshot) {
                  final isPaused = snapshot.data ?? false;
                  return StreamBuilder<bool>(
                    stream: _controller.speakingStream,
                    initialData: _controller.isSpeaking,
                    builder: (context, speakingSnapshot) {
                      final isSpeaking = speakingSnapshot.data ?? false;
                      return ElevatedButton.icon(
                        onPressed: isSpeaking
                            ? (isPaused
                                  ? () => _controller.resume()
                                  : () => _controller.pause())
                            : null,
                        icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                        label: Text(isPaused ? 'Resume' : 'Pause'),
                      );
                    },
                  );
                },
              ),
            ],
          ),

          // Error display using unified UI library component
          StreamBuilder<String?>(
            stream: _controller.errorStream,
            initialData: _controller.errorMessage,
            builder: (context, snapshot) {
              final error = snapshot.data;
              if (error != null) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ErrorDisplayWidget(
                    error: UnifiedError.tts(message: error),
                    onRetry: () => _controller.clearError(),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
