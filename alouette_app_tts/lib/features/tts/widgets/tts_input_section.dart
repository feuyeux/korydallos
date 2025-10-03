import 'package:flutter/material.dart';
// Uses TTSVoice via controller; no direct package import needed here
import 'package:alouette_ui/alouette_ui.dart';
import '../controllers/tts_controller.dart' as local;

/// Widget for text input and voice selection
class TTSInputSection extends StatefulWidget {
  final local.TTSController controller;
  final TextEditingController textController;

  const TTSInputSection({
    super.key,
    required this.controller,
    required this.textController,
  });

  @override
  State<TTSInputSection> createState() => _TTSInputSectionState();
}

class _TTSInputSectionState extends State<TTSInputSection> {
  String? _selectedLanguage;
  String? _selectedVoice;

  @override
  void initState() {
    super.initState();
    // Initialize selected language and voice when controller is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSelection();
    });
  }

  void _initializeSelection() {
    if (widget.controller.isInitialized &&
        widget.controller.availableVoices.isNotEmpty) {
      // Find current voice and set language accordingly
      final currentVoice = widget.controller.availableVoices
          .where((voice) => voice.name == widget.controller.currentVoice)
          .firstOrNull;

      if (currentVoice != null) {
        setState(() {
          _selectedLanguage = currentVoice.language;
          _selectedVoice = currentVoice.name;
        });
      } else {
        // Set default to first available language and voice
        final firstVoice = widget.controller.availableVoices.first;
        setState(() {
          _selectedLanguage = firstVoice.language;
          _selectedVoice = firstVoice.name;
        });
        widget.controller.changeVoice(firstVoice.name);
      }
    }
  }

  /// Get unique languages from available voices
  List<String> get _availableLanguages {
    if (!widget.controller.isInitialized) return [];

    final languages = widget.controller.availableVoices
        .map((voice) => voice.language)
        .toSet()
        .toList();

    languages.sort();
    return languages;
  }

  /// Get voices for selected language
  List<TTSVoice> get _voicesForSelectedLanguage {
    if (!widget.controller.isInitialized || _selectedLanguage == null) {
      return [];
    }

    return widget.controller.availableVoices
        .where((voice) => voice.language == _selectedLanguage)
        .toList();
  }

  /// Get language display name
  String _getLanguageDisplayName(String languageCode) {
    // Map common language codes to display names
    const languageNames = {
      'en-US': 'English (US)',
      'en-GB': 'English (UK)',
      'en-AU': 'English (Australia)',
      'en-CA': 'English (Canada)',
      'zh-CN': '中文 (简体)',
      'zh-TW': '中文 (繁體)',
      'zh-HK': '中文 (香港)',
      'ja-JP': '日本語',
      'ko-KR': '한국어',
      'fr-FR': 'Français (France)',
      'fr-CA': 'Français (Canada)',
      'de-DE': 'Deutsch',
      'es-ES': 'Español (España)',
      'es-MX': 'Español (México)',
      'it-IT': 'Italiano',
      'pt-BR': 'Português (Brasil)',
      'pt-PT': 'Português (Portugal)',
      'ru-RU': 'Русский',
      'ar-SA': 'العربية',
      'hi-IN': 'हिन्दी',
      'th-TH': 'ไทย',
      'vi-VN': 'Tiếng Việt',
    };

    return languageNames[languageCode] ?? languageCode;
  }

  /// Get voice display name with gender info
  String _getVoiceDisplayName(TTSVoice voice) {
    final parts = <String>[];

    parts.add(voice.name);

    // Add gender info
    // gender may be null
    if (voice.gender != null && voice.gender!.isNotEmpty) {
      parts.add('(${voice.gender})');
    }

    return parts.join(' ');
  }

  void _onLanguageChanged(String? languageCode) {
    if (languageCode == null || languageCode == _selectedLanguage) return;

    setState(() {
      _selectedLanguage = languageCode;
      _selectedVoice = null; // Reset voice selection
    });

    // Auto-select first voice for the new language
    final voicesForLanguage = _voicesForSelectedLanguage;
    if (voicesForLanguage.isNotEmpty) {
      final firstVoice = voicesForLanguage.first;
      setState(() {
        _selectedVoice = firstVoice.name;
      });
      widget.controller.changeVoice(firstVoice.name);
    }
  }

  void _onVoiceChanged(String? voiceId) {
    if (voiceId == null || voiceId == _selectedVoice) return;

    setState(() {
      _selectedVoice = voiceId;
    });

    widget.controller.changeVoice(voiceId);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        // Update selection when controller state changes
        if (widget.controller.isInitialized &&
            widget.controller.availableVoices.isNotEmpty &&
            (_selectedLanguage == null || _selectedVoice == null)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeSelection();
          });
        }

        return CustomCard(
          child: Padding(
            padding: const EdgeInsets.all(8.0), // Reduced from 12 to 8
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.text_fields,
                      color: AppTheme.primaryColor,
                      size: 16, // Reduced from 18 to 16
                    ),
                    const SizedBox(width: 4), // Reduced from 6 to 4
                    const Text(
                      'Text Input',
                      style: TextStyle(
                        fontSize: 13, // Reduced from 14 to 13
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8), // Reduced from 12 to 8
                // Text input field
                Expanded(
                  child: CustomTextField(
                    controller: widget.textController,
                    hintText: 'Enter text to speak...',
                    maxLines: null,
                    expands: true,
                    enabled: widget.controller.isInitialized,
                  ),
                ),

                const SizedBox(height: 8), // Reduced from 12 to 8
                // Voice selection
                if (widget.controller.isInitialized &&
                    widget.controller.availableVoices.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Voice Selection',
                        style: TextStyle(
                          fontSize: 11, // Reduced from 12 to 11
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4), // Reduced from 6 to 4
                      // Language and Voice selection row
                      Row(
                        children: [
                          // Language selection (left side)
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Language',
                                  style: TextStyle(
                                    fontSize: 9, // Reduced from 10 to 9
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(
                                  height: 1,
                                ), // Reduced from 2 to 1
                                CustomDropdown<String>(
                                  value: _selectedLanguage,
                                  items: _availableLanguages
                                      .map(
                                        (languageCode) =>
                                            DropdownMenuItem<String>(
                                              value: languageCode,
                                              child: Text(
                                                _getLanguageDisplayName(
                                                  languageCode,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                      )
                                      .toList(),
                                  onChanged: widget.controller.isInitialized
                                      ? _onLanguageChanged
                                      : null,
                                  hint: 'Select Language',
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical:
                                        4.0, // Much smaller vertical padding
                                  ),
                                  isDense: true,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 6), // Reduced from 8 to 6
                          // Voice selection (right side)
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Voice',
                                  style: TextStyle(
                                    fontSize: 9, // Reduced from 10 to 9
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(
                                  height: 1,
                                ), // Reduced from 2 to 1
                                CustomDropdown<String>(
                                  value: _selectedVoice,
                                  items: _voicesForSelectedLanguage
                                      .map(
                                        (voice) => DropdownMenuItem<String>(
                                          value: voice.name,
                                          child: Text(
                                            _getVoiceDisplayName(voice),
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged:
                                      widget.controller.isInitialized &&
                                          _selectedLanguage != null
                                      ? _onVoiceChanged
                                      : null,
                                  hint: 'Select Voice',
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical:
                                        4.0, // Much smaller vertical padding
                                  ),
                                  isDense: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                // Loading indicator when not initialized
                if (!widget.controller.isInitialized)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0), // Reduced from 12 to 8
                      child: Column(
                        children: [
                          SizedBox(
                            width: 16, // Smaller loading indicator
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(height: 4), // Reduced from 6 to 4
                          Text(
                            'Initializing TTS...',
                            style: TextStyle(
                              fontSize: 10,
                            ), // Reduced from 12 to 10
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
