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
    text: '你好，这是一个测试消息。',
  );
  
  // Language selection
  String? _selectedLanguage = 'zh-CN';
  static const List<Map<String, String>> _availableLanguages = [
    {'code': 'zh-CN', 'name': '中文 (简体)'},
    {'code': 'en-US', 'name': 'English (US)'},
    {'code': 'ja-JP', 'name': '日本語'},
    {'code': 'ko-KR', 'name': '한국어'},
    {'code': 'fr-FR', 'name': 'Français'},
    {'code': 'de-DE', 'name': 'Deutsch'},
    {'code': 'es-ES', 'name': 'Español'},
    {'code': 'ru-RU', 'name': 'Русский'},
    {'code': 'ar-SA', 'name': 'العربية'},
    {'code': 'hi-IN', 'name': 'हिन्दी'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = createTTSController();
    _controller.text = _textController.text;
    if (_selectedLanguage != null) {
      _controller.setLanguageCode(_selectedLanguage!);
    }
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

  void _onLanguageChanged(String? newLanguage) {
    setState(() {
      if (newLanguage == null) {
        // Deselect language
        _selectedLanguage = null;
      } else if (newLanguage == _selectedLanguage) {
        // Toggle off current selection
        _selectedLanguage = null;
      } else {
        // Select new language
        _selectedLanguage = newLanguage;
        _controller.setLanguageCode(newLanguage);
        _ensureVoiceMatchesLanguage();
      }
    });
  }

  void _clearText() {
    // Temporarily remove listener to prevent interference
    _textController.removeListener(_onTextChanged);
    
    // Clear both controllers
    _textController.clear();
    _controller.text = '';
    
    // Re-add listener
    _textController.addListener(_onTextChanged);
    
    // Force UI update
    setState(() {});
  }

  void _ensureVoiceMatchesLanguage() {
    final voices = _controller.availableVoices;
    if (voices.isEmpty || _selectedLanguage == null) return;

    final prefix = '$_selectedLanguage-';
    final current = _controller.selectedVoice;
    if (current != null && current.startsWith(prefix)) return;

    final match = voices.firstWhere(
      (v) => v.startsWith(prefix),
      orElse: () => '',
    );
    if (match.isNotEmpty && match != current) {
      _controller.setVoice(match);
    }
  }

  List<String> _getFilteredVoices() {
    if (_selectedLanguage == null) return [];
    final allVoices = _controller.availableVoices;
    final prefix = '$_selectedLanguage-';
    return allVoices.where((voice) => voice.startsWith(prefix)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Language selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Language Selection',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _selectedLanguage,
                isExpanded: true,
                items: [
                  // Add "No Selection" option
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text(
                      'No Language Selected',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                  // Add all available languages
                  ..._availableLanguages.map((lang) {
                    return DropdownMenuItem<String>(
                      value: lang['code'],
                      child: Text('${lang['code']} - ${lang['name']}'),
                    );
                  }),
                ],
                onChanged: _onLanguageChanged,
              ),
              const SizedBox(height: 16),
            ],
          ),

          // Voice selector (filtered by language)
          if (_controller.availableVoices.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Voice Selection (${_selectedLanguage ?? 'No Language'})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      '${_getFilteredVoices().length}/${_controller.availableVoices.length}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _controller.selectedVoice != null &&
                          _getFilteredVoices().contains(_controller.selectedVoice)
                      ? _controller.selectedVoice
                      : null,
                  isExpanded: true,
                  hint: Text(_getFilteredVoices().isEmpty 
                      ? 'No voices for $_selectedLanguage'
                      : 'Select Voice'),
                  items: [
                    // Add "No Selection" option
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text(
                        'No Voice Selected',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    // Add filtered voices
                    ..._getFilteredVoices().map((voice) {
                      // Remove language prefix for cleaner display
                      final displayName = _selectedLanguage != null && voice.startsWith('$_selectedLanguage-')
                          ? voice.substring(_selectedLanguage!.length + 1)
                          : voice;
                      return DropdownMenuItem(
                        value: voice, 
                        child: Text(displayName),
                      );
                    }),
                  ],
                  onChanged: _getFilteredVoices().isEmpty ? null : (voiceName) {
                    // Allow null selection (deselection)
                    if (voiceName != null) {
                      _controller.setVoice(voiceName);
                    } else {
                      // Handle deselection - set to first available voice or empty
                      final filteredVoices = _getFilteredVoices();
                      if (filteredVoices.isNotEmpty) {
                        _controller.setVoice(filteredVoices.first);
                      }
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
                    'Rate: ${_controller.speechRate.toStringAsFixed(1)}x',
                  ),
                  Slider(
                    value: _controller.speechRate,
                    onChanged: (value) => _controller.setSpeechRate(value),
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                  ),

                  // Speech Pitch
                  Text(
                    'Pitch: ${_controller.speechPitch.toStringAsFixed(1)}x',
                  ),
                  Slider(
                    value: _controller.speechPitch,
                    onChanged: (value) => _controller.setSpeechPitch(value),
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
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
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _clearText,
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                ),
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
