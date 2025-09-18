import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart' as tts_lib;
import 'tts_controller.dart';

class TTSPage extends StatefulWidget {
  const TTSPage({super.key});

  @override
  State<TTSPage> createState() => _TTSPageState();
}

class _TTSPageState extends State<TTSPage> {
  late final TTSController _controller;
  final TextEditingController _textController = TextEditingController(
    text: 'Hello, this is a test message.',
  );

  @override
  void initState() {
    super.initState();
    _controller = TTSController();
    _controller.initialize();
  }

  @override
  void dispose() {
    _textController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _controller.isInitializedNotifier,
      builder: (context, isInitialized, child) {
        if (!isInitialized) {
          return ValueListenableBuilder<String?>(
            valueListenable: _controller.errorMessageNotifier,
            builder: (context, errorMessage, child) {
              if (errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _controller.initialize(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Initializing TTS Service...'),
                  ],
                ),
              );
            },
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Current engine info
              ValueListenableBuilder<tts_lib.TTSEngineType?>(
                valueListenable: _controller.currentEngineNotifier,
                builder: (context, currentEngine, child) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Engine: ${currentEngine?.name ?? 'Unknown'}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Platform: ${tts_lib.PlatformUtils.isDesktop
                                ? 'Desktop'
                                : tts_lib.PlatformUtils.isMobile
                                ? 'Mobile'
                                : 'Web'}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Engine selector
              ValueListenableBuilder<tts_lib.TTSEngineType?>(
                valueListenable: _controller.currentEngineNotifier,
                builder: (context, currentEngine, child) {
                  return Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: currentEngine == tts_lib.TTSEngineType.edge
                              ? null
                              : () => _controller.switchEngine(tts_lib.TTSEngineType.edge),
                          child: const Text('Edge TTS'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: currentEngine == tts_lib.TTSEngineType.flutter
                              ? null
                              : () => _controller.switchEngine(tts_lib.TTSEngineType.flutter),
                          child: const Text('Flutter TTS'),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              // Voice selector
              ValueListenableBuilder<bool>(
                valueListenable: _controller.isLoadingVoicesNotifier,
                builder: (context, isLoading, child) {
                  if (isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ValueListenableBuilder<List<tts_lib.VoiceModel>>(
                    valueListenable: _controller.availableVoicesNotifier,
                    builder: (context, voices, child) {
                      if (voices.isEmpty) {
                        return const Text('No voices available');
                      }

                      return Column(
                        children: [
                          ValueListenableBuilder<String?>(
                            valueListenable: _controller.currentVoiceNameNotifier,
                            builder: (context, currentVoiceName, child) {
                              return DropdownButton<String>(
                                value: currentVoiceName,
                                isExpanded: true,
                                items: voices.map((voice) {
                                  return DropdownMenuItem(
                                    value: voice.name,
                                    child: Text(
                                      '${voice.displayName} (${voice.locale}, ${voice.gender})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (voiceName) {
                                  if (voiceName != null) {
                                    _controller.setCurrentVoice(voiceName);
                                  }
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Available voices: ${voices.length} (Neural: ${voices.where((v) => v.isNeural).length})',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      );
                    },
                  );
                },
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
              ),

              const SizedBox(height: 16),

              // Play/Stop button
              ValueListenableBuilder<bool>(
                valueListenable: _controller.isPlayingNotifier,
                builder: (context, isPlaying, child) {
                  return ValueListenableBuilder<String?>(
                    valueListenable: _controller.currentVoiceNameNotifier,
                    builder: (context, currentVoiceName, child) {
                      return ElevatedButton.icon(
                        onPressed: isPlaying
                            ? _controller.stop
                            : (currentVoiceName != null 
                                ? () => _controller.speak(_textController.text)
                                : null),
                        icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                        label: Text(isPlaying ? 'Stop' : 'Speak'),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}