import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';

class TTSConfigDialog extends StatefulWidget {
  final UnifiedTTSService? ttsService;

  const TTSConfigDialog({super.key, this.ttsService});

  @override
  State<TTSConfigDialog> createState() => _TTSConfigDialogState();
}

class _TTSConfigDialogState extends State<TTSConfigDialog> {
  bool _isInitialized = false;
  List<Voice> _voices = [];
  String? _currentVoice;
  AudioPlayer? _audioPlayer;
  TTSEngineType? _currentEngine;

  @override
  void initState() {
    super.initState();
    _initializeTTSSettings();
  }

  Future<void> _initializeTTSSettings() async {
    if (widget.ttsService != null) {
      try {
        // Initialize audio player
        _audioPlayer = AudioPlayer();
        
        // Get current engine type
        _currentEngine = widget.ttsService!.currentEngine;
        
        // 获取可用的语音列表
        final voices = await widget.ttsService!.getVoices();

        if (mounted) {
          setState(() {
            _voices = voices;
            _currentVoice = voices.isNotEmpty ? voices.first.name : null;
            _isInitialized = true;
          });
        }
      } catch (e, stack) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('TTS Error: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 10),
              action: SnackBarAction(
                label: 'Details',
                textColor: Colors.white,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('TTS Error Details'),
                      content: SingleChildScrollView(
                        child: Text('$e\n\n$stack'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    } else {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _testTTS() async {
    if (widget.ttsService == null || _currentVoice == null || _audioPlayer == null) return;

    try {
      final audioData = await widget.ttsService!.synthesizeText(
        "Hello, this is a test of the text to speech settings.",
        _currentVoice!,
      );
      await _audioPlayer!.playBytes(audioData);
    } on TTSError catch (e) {
      if (mounted) {
        String errorMessage = 'TTS Test Failed: ${e.message}';
        if (e.code != null) {
          errorMessage += ' (Code: ${e.code})';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected TTS Test Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopTTS() async {
    // Note: The new unified API doesn't have a stop method at the service level
    // Audio playback is handled by the AudioPlayer
  }

  Future<void> _switchEngine(TTSEngineType engineType) async {
    if (widget.ttsService == null) return;

    try {
      await widget.ttsService!.switchEngine(engineType);
      setState(() {
        _currentEngine = engineType;
        _voices = [];
        _currentVoice = null;
      });
      
      // Reload voices for the new engine
      final voices = await widget.ttsService!.getVoices();
      setState(() {
        _voices = voices;
        _currentVoice = voices.isNotEmpty ? voices.first.name : null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch engine: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  const Icon(Icons.record_voice_over, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'TTS Configuration',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        if (_isInitialized) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.ttsService != null
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: widget.ttsService != null
                                    ? Colors.green.shade200
                                    : Colors.orange.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  widget.ttsService != null
                                      ? Icons.check_circle
                                      : Icons.warning,
                                  color: widget.ttsService != null
                                      ? Colors.green.shade600
                                      : Colors.orange.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.ttsService != null
                                      ? 'TTS Service Available'
                                      : 'TTS Service Not Available',
                                  style: TextStyle(
                                    color: widget.ttsService != null
                                        ? Colors.green.shade800
                                        : Colors.orange.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Engine Selection
                          Text(
                            'TTS Engine',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _currentEngine == TTSEngineType.edge 
                                      ? null 
                                      : () => _switchEngine(TTSEngineType.edge),
                                  child: Text('Edge TTS'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _currentEngine == TTSEngineType.edge 
                                        ? Theme.of(context).primaryColor 
                                        : null,
                                    foregroundColor: _currentEngine == TTSEngineType.edge 
                                        ? Colors.white 
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _currentEngine == TTSEngineType.flutter 
                                      ? null 
                                      : () => _switchEngine(TTSEngineType.flutter),
                                  child: Text('Flutter TTS'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _currentEngine == TTSEngineType.flutter 
                                        ? Theme.of(context).primaryColor 
                                        : null,
                                    foregroundColor: _currentEngine == TTSEngineType.flutter 
                                        ? Colors.white 
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          Text(
                            'Current Engine: ${_currentEngine?.name ?? 'Unknown'}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          if (_voices.isNotEmpty) ...[
                            Text(
                              'Available Voices (${_voices.length})',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _currentVoice,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: _voices.map((voice) {
                                return DropdownMenuItem<String>(
                                  value: voice.name,
                                  child: Text(
                                    '${voice.displayName} (${voice.locale}, ${voice.gender})',
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _currentVoice = newValue;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Neural voices: ${_voices.where((v) => v.isNeural).length}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: (widget.ttsService != null && _currentVoice != null) 
                                    ? _testTTS 
                                    : null,
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Test'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed:
                                    widget.ttsService != null ? _stopTTS : null,
                                icon: const Icon(Icons.stop),
                                label: const Text('Stop'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: Visibility(
                      visible: !_isInitialized,
                      maintainState: true,
                      maintainAnimation: true,
                      maintainSize: true,
                      child: Container(
                        color: Colors.transparent,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
