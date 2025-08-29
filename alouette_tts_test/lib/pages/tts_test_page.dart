import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';

class TTSTestPage extends StatefulWidget {
  const TTSTestPage({super.key});

  @override
  State<TTSTestPage> createState() => _TTSTestPageState();
}

class _TTSTestPageState extends State<TTSTestPage> {
  late final Future<List<TTSService>> _ttsServicesFuture;
  final TextEditingController _textController = TextEditingController(
    text: 'Hello, this is a test message.',
  );

  String? _currentVoiceId;
  List<Voice>? _voices;
  TTSService? _currentTTS;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _ttsServicesFuture = _initTTSServices();
  }

  Future<List<TTSService>> _initTTSServices() async {
    final services = <TTSService>[];

    try {
      final edgeTTS = await TTSFactory.create(TTSType.edge);
      services.add(edgeTTS);
    } catch (e) {
      debugPrint('Failed to initialize Edge TTS: $e');
    }

    try {
      final flutterTTS = await TTSFactory.create(TTSType.flutter);
      services.add(flutterTTS);
    } catch (e) {
      debugPrint('Failed to initialize Flutter TTS: $e');
    }

    if (services.isEmpty) {
      throw Exception('No TTS service available');
    }

    return services;
  }

  Future<void> _switchTTS(TTSService tts) async {
    setState(() {
      _currentTTS = tts;
      _voices = null;
      _currentVoiceId = null;
    });

    try {
      final voices = await tts.getVoices();
      setState(() {
        _voices = voices;
        if (voices.isNotEmpty) {
          _currentVoiceId = voices.first.id;
          tts.setVoice(_currentVoiceId!);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get voices: $e')),
      );
    }
  }

  Future<void> _speak() async {
    if (_currentTTS == null || _currentVoiceId == null) return;

    setState(() => _isPlaying = true);
    try {
      await _currentTTS!.speak(_textController.text);
    } finally {
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _stop() async {
    if (_currentTTS == null) return;
    await _currentTTS!.stop();
    setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TTS Test')),
      body: FutureBuilder<List<TTSService>>(
        future: _ttsServicesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final services = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TTS Service selector
                DropdownButton<TTSService>(
                  value: _currentTTS ?? services.first,
                  items: services.map((tts) {
                    final isEdge = tts is EdgeTTSService;
                    return DropdownMenuItem(
                      value: tts,
                      child: Text(isEdge ? 'Edge TTS' : 'Flutter TTS'),
                    );
                  }).toList(),
                  onChanged: (tts) {
                    if (tts != null) _switchTTS(tts);
                  },
                ),

                const SizedBox(height: 16),

                // Voice selector
                if (_voices != null) ...[
                  DropdownButton<String>(
                    value: _currentVoiceId,
                    items: _voices!.map((voice) {
                      return DropdownMenuItem(
                        value: voice.id,
                        child: Text('${voice.name} (${voice.languageCode})'),
                      );
                    }).toList(),
                    onChanged: (voiceId) {
                      if (voiceId != null && _currentTTS != null) {
                        setState(() => _currentVoiceId = voiceId);
                        _currentTTS!.setVoice(voiceId);
                      }
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
                  ),
                ),

                const SizedBox(height: 16),

                // Play/Stop button
                ElevatedButton(
                  onPressed: _isPlaying ? _stop : _speak,
                  child: Text(_isPlaying ? 'Stop' : 'Speak'),
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
