import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';
import '../services/app_tts_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _textController = TextEditingController(
    text: '你好，我可以为你朗读。Hello, I can read for you.',
  );

  bool _isPlaying = false;
  bool _isInitialized = false;
  String? _currentVoice;
  VoiceService? _voiceService;
  TTSEngineType? _currentEngine;

  @override
  void initState() {
    super.initState();
    _initTTS();
  }

  Future<void> _initTTS() async {
    try {
      await AppTTSManager.initialize();
      _voiceService = AppTTSManager.voiceService;
      _currentEngine = AppTTSManager.currentEngine;
      
      // Load voices using VoiceService
      final voices = await _voiceService!.getAllVoices();
      
      if (mounted) {
        setState(() {
          if (voices.isNotEmpty) {
            _currentVoice = voices.first.name;
          }
          _isInitialized = true;
        });
      }
    } catch (e) {
      await _showDetailedError(e);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Show TTS configuration dialog
  Future<void> _showTTSConfig() async {
    await showDialog(
      context: context,
      builder: (context) => TTSConfigDialog(
        ttsService: AppTTSManager.service,
      ),
    );
  }

  /// Show detailed error information and diagnostic suggestions
  Future<void> _showDetailedError(dynamic error) async {
    final diagnostics = await TTSDiagnostics.runFullDiagnostics();
    final report = TTSDiagnostics.generateReadableReport(diagnostics);
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('TTS Initialization Failed'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Error:', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    error.toString(),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Diagnostic Report:', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    report,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _initTTS();
              },
              child: const Text('Retry'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _speak() async {
    if (_textController.text.isEmpty) {
      _showError('Please enter text to read');
      return;
    }

    if (!_isInitialized || _currentVoice == null || _voiceService == null) {
      _showError('TTS service not properly initialized');
      return;
    }

    try {
      setState(() => _isPlaying = true);
      
      final audioData = await AppTTSManager.service.synthesizeText(
        _textController.text,
        _currentVoice!,
      );
      
      // Check if we got actual audio data or if TTS engine played directly
      if (audioData.length > 100) {
        await AppTTSManager.audioPlayer.playBytes(audioData);
      } else {
        // TTS engine already played directly
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      setState(() => _isPlaying = false);
    } on TTSError catch (e) {
      setState(() => _isPlaying = false);
      _showError('Playback failed: ${e.message}');
    } catch (e) {
      setState(() => _isPlaying = false);
      _showError('Playback failed: $e');
    }
  }

  Future<void> _stop() async {
    if (!_isInitialized) return;

    try {
      await AppTTSManager.service.stop();
      setState(() => _isPlaying = false);
    } catch (e) {
      _showError('Failed to stop: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AlouetteAppBar(
        currentEngine: _currentEngine,
        ttsInitialized: _isInitialized,
      ),
      body: _isInitialized
          ? _buildMainContent()
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing TTS Service...'),
                ],
              ),
            ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // TTS Status Indicator
          TTSStatusIndicator(isPlaying: _isPlaying),
          
          const SizedBox(height: 24),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Voice Selector using VoiceService
                if (_voiceService != null)
                  ValueListenableBuilder<bool>(
                    valueListenable: _voiceService!.isLoadingNotifier,
                    builder: (context, isLoading, child) {
                      if (isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final voices = _voiceService!.cachedVoices;
                      
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Voice Selection',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              if (voices.isNotEmpty)
                                DropdownButton<String>(
                                  value: _currentVoice,
                                  isExpanded: true,
                                  items: voices.map((voice) {
                                    return DropdownMenuItem(
                                      value: voice.name,
                                      child: Text(
                                        '${voice.displayName} (${voice.locale})',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (voiceName) {
                                    if (voiceName != null) {
                                      setState(() => _currentVoice = voiceName);
                                    }
                                  },
                                )
                              else
                                const Text('No voices available'),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Available: ${voices.length} voices',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _showTTSConfig(),
                                    icon: const Icon(Icons.settings, size: 16),
                                    label: const Text('Settings'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 16),

                // Text Input
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Text to Read',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Enter text to read aloud...',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // TTS Control Buttons
          TTSControlButtons(
            isPlaying: _isPlaying,
            onPlayPause: _isPlaying ? _stop : _speak,
            onStop: _stop,
          ),
        ],
      ),
    );
  }
}
