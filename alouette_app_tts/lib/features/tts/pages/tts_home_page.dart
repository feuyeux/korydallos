import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import 'tts_page.dart';
import '../../../config/tts_app_config.dart';

/// Home page for the TTS application
class TTSHomePage extends StatefulWidget {
  const TTSHomePage({super.key});

  @override
  State<TTSHomePage> createState() => _TTSHomePageState();
}

class _TTSHomePageState extends State<TTSHomePage> with AutoControllerDisposal {
  late ITTSController _ttsController;
  final TextEditingController _textController = TextEditingController(
    text: TTSAppConfig.defaultText,
  );
  
  // Explicit language selection - no guessing
  String _selectedLanguage = 'zh-CN'; // Default language
  
  // Available languages for TTS
  static const List<Map<String, String>> _availableLanguages = [
    {'code': 'zh-CN', 'name': '中文 (简体)'},
    {'code': 'en-US', 'name': 'English (US)'},
    {'code': 'en-GB', 'name': 'English (UK)'},
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
    _ttsController = createTTSController();
    _ttsController.text = _textController.text;
    // Set initial language
    _ttsController.setLanguageCode(_selectedLanguage);
    // Sync text controller with TTS controller
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    _ttsController.text = _textController.text;
  }

  void _onLanguageChanged(String? newLanguage) {
    if (newLanguage != null && newLanguage != _selectedLanguage) {
      setState(() {
        _selectedLanguage = newLanguage;
        // Set language code directly to TTS controller
        _ttsController.setLanguageCode(newLanguage);
      });
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  // Removed duplicate error handling - using UI library's unified error handling

  Future<void> _showTTSSettings() async {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('TTS Settings'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Available Voices: ${_ttsController.availableVoices.length}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Selected Voice: ${_ttsController.selectedVoice ?? 'None'}',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Voice Parameters:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rate: ${(_ttsController.speechRate * 2).toStringAsFixed(1)}x',
                ),
                Text(
                  'Pitch: ${(_ttsController.speechPitch * 2).toStringAsFixed(1)}x',
                ),
                Text('Volume: ${(_ttsController.speechVolume * 100).toInt()}%'),
                const SizedBox(height: 16),
                const Text(
                  'Status:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Speaking: ${_ttsController.isSpeaking ? 'Yes' : 'No'}'),
                Text('Paused: ${_ttsController.isPaused ? 'Yes' : 'No'}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Error handling is now managed by the UI library's unified error system

    return Scaffold(
      appBar: ModernAppBar(
        title: TTSAppConfig.appTitle,
        showLogo: true,
        statusWidget: StreamBuilder<bool>(
          stream: _ttsController.speakingStream,
          initialData: _ttsController.isSpeaking,
          builder: (context, speakingSnapshot) {
            return StreamBuilder<String?>(
              stream: _ttsController.errorStream,
              initialData: _ttsController.errorMessage,
              builder: (context, errorSnapshot) {
                final isPlaying = speakingSnapshot.data ?? false;
                final error = errorSnapshot.data;

                if (error != null) {
                  return CompactStatusIndicator(
                    status: StatusType.error,
                    message: 'TTS Error',
                  );
                }

                if (isPlaying) {
                  return CompactStatusIndicator(
                    status: StatusType.info,
                    message: 'Speaking...',
                  );
                }

                return CompactStatusIndicator(
                  status: StatusType.success,
                  message: 'Ready',
                );
              },
            );
          },
        ),
        actions: [
          // Language selector
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  isDense: true,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                  dropdownColor: Colors.grey[800],
                  items: _availableLanguages.map((lang) {
                    return DropdownMenuItem<String>(
                      value: lang['code'],
                      child: Text(
                        lang['code']!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                  onChanged: _onLanguageChanged,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showTTSSettings,
              tooltip: 'TTS Settings',
            ),
          ),
        ],
      ),
      body: TTSPage(
        controller: _ttsController,
        textController: _textController,
        language: _selectedLanguage, // Explicitly pass selected language
      ),
    );
  }
}
