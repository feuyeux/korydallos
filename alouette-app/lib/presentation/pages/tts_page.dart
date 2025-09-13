import 'package:alouette_lib_tts/alouette_tts.dart';
import 'package:flutter/material.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';

class TTSPage extends StatefulWidget {
  const TTSPage({super.key});

  @override
  State<TTSPage> createState() => _TTSPageState();
}

class _TTSPageState extends State<TTSPage> {
  late final Future<VoiceService> _voiceServiceFuture;
  final TextEditingController _textController = TextEditingController(
    text: 'Hello, this is a test message.',
  );

  String? _currentVoiceName;
  VoiceService? _voiceService;
  TTSService? _ttsService;
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  TTSEngineType? _currentEngine;

  @override
  void initState() {
    super.initState();
    _voiceServiceFuture = _initServices();
  }

  Future<VoiceService> _initServices() async {
    try {
      _ttsService = await SharedTTSManager.getService();
      _voiceService = await SharedTTSManager.getVoiceService();
      _audioPlayer = SharedTTSManager.getAudioPlayer();
      
      setState(() {
        _currentEngine = _ttsService!.currentEngine;
      });
      
      await _loadVoices();
      return _voiceService!;
    } catch (e) {
      debugPrint('Failed to initialize services: $e');
      rethrow;
    }
  }

  Future<void> _loadVoices() async {
    if (_voiceService == null) return;
    
    try {
      final voices = await _voiceService!.getAllVoices();
      setState(() {
        if (voices.isNotEmpty) {
          _currentVoiceName = voices.first.name;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get voices: $e')),
        );
      }
    }
  }

  Future<void> _switchEngine(TTSEngineType engineType) async {
    if (_ttsService == null) return;

    try {
      setState(() => _isPlaying = true);
      await _ttsService!.switchEngine(engineType);
      setState(() {
        _currentEngine = engineType;
        _currentVoiceName = null;
      });
      await _loadVoices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to switch engine: $e')),
        );
      }
    } finally {
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _speak() async {
    if (_ttsService == null || _currentVoiceName == null || _audioPlayer == null) return;

    setState(() => _isPlaying = true);
    try {
      final audioData = await _ttsService!.synthesizeText(
        _textController.text, 
        _currentVoiceName!,
      );
      await _audioPlayer!.playBytes(audioData);
    } on TTSError catch (e) {
      if (mounted) {
        String errorMessage = 'TTS Error: ${e.message}';
        if (e.code != null) {
          errorMessage += ' (Code: ${e.code})';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error: $e')),
        );
      }
    } finally {
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _stop() async {
    // Note: The new API doesn't have a stop method on the service level
    // Audio playback is handled by the AudioPlayer
    setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'TTS - Unified API',
      ),
      body: FutureBuilder<VoiceService>(
        future: _voiceServiceFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _voiceServiceFuture = _initServices();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
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
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Current engine info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Engine: ${_currentEngine?.name ?? 'Unknown'}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Platform: ${PlatformUtils.isDesktop ? 'Desktop' : PlatformUtils.isMobile ? 'Mobile' : 'Web'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Engine selector
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _currentEngine == TTSEngineType.edge ? null : () => _switchEngine(TTSEngineType.edge),
                        child: const Text('Edge TTS'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _currentEngine == TTSEngineType.flutter ? null : () => _switchEngine(TTSEngineType.flutter),
                        child: const Text('Flutter TTS'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Voice selector
                if (_voiceService != null) ...[
                  ValueListenableBuilder<bool>(
                    valueListenable: _voiceService!.isLoadingNotifier,
                    builder: (context, isLoading, child) {
                      if (isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final voices = _voiceService!.cachedVoices;
                      if (voices.isEmpty) {
                        return const Text('No voices available');
                      }
                      
                      return Column(
                        children: [
                          DropdownButton<String>(
                            value: _currentVoiceName,
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
                                setState(() => _currentVoiceName = voiceName);
                              }
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
                  ),
                  const SizedBox(height: 16),
                ],

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
                ElevatedButton.icon(
                  onPressed: _isPlaying ? _stop : (_currentVoiceName != null ? _speak : null),
                  icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                  label: Text(_isPlaying ? 'Stop' : 'Speak'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}