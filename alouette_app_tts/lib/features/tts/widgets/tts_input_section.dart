import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
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
    if (widget.controller.isInitialized && widget.controller.availableVoices.isNotEmpty) {
      // Find current voice and set language accordingly
      final currentVoice = widget.controller.availableVoices
          .where((voice) => voice.id == widget.controller.currentVoice)
          .firstOrNull;
      
      if (currentVoice != null) {
        setState(() {
          _selectedLanguage = currentVoice.languageCode;
          _selectedVoice = currentVoice.id;
        });
      } else {
        // Set default to first available language and voice
        final firstVoice = widget.controller.availableVoices.first;
        setState(() {
          _selectedLanguage = firstVoice.languageCode;
          _selectedVoice = firstVoice.id;
        });
        widget.controller.changeVoice(firstVoice.id);
      }
    }
  }

  /// Get unique languages from available voices
  List<String> get _availableLanguages {
    if (!widget.controller.isInitialized) return [];
    
    final languages = widget.controller.availableVoices
        .map((voice) => voice.languageCode)
        .toSet()
        .toList();
    
    languages.sort();
    return languages;
  }

  /// Get voices for selected language
  List<VoiceModel> get _voicesForSelectedLanguage {
    if (!widget.controller.isInitialized || _selectedLanguage == null) return [];
    
    return widget.controller.availableVoices
        .where((voice) => voice.languageCode == _selectedLanguage)
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
  String _getVoiceDisplayName(VoiceModel voice) {
    final parts = <String>[];
    
    if (voice.displayName.isNotEmpty) {
      parts.add(voice.displayName);
    } else {
      parts.add(voice.id);
    }
    
    // Add gender info
    if (voice.gender.name != 'unknown') {
      parts.add('(${voice.gender.name})');
    }
    
    // Add neural indicator
    if (voice.isNeural) {
      parts.add('[Neural]');
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
        _selectedVoice = firstVoice.id;
      });
      widget.controller.changeVoice(firstVoice.id);
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
        
        return ModernCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.text_fields,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Text Input',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Text input field
          Expanded(
            child: ModernTextField(
              controller: widget.textController,
              hintText: 'Enter text to speak...',
              maxLines: null,
              expands: true,
              enabled: widget.controller.isInitialized,
            ),
          ),

          const SizedBox(height: 16),

          // Voice selection
          if (widget.controller.isInitialized && widget.controller.availableVoices.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Voice Selection',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                
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
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ModernDropdown<String>(
                            value: _selectedLanguage,
                            items: _availableLanguages
                                .map((languageCode) => DropdownMenuItem<String>(
                                      value: languageCode,
                                      child: Text(
                                        _getLanguageDisplayName(languageCode),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ))
                                .toList(),
                            onChanged: widget.controller.isInitialized ? _onLanguageChanged : null,
                            hint: 'Select Language',
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Voice selection (right side)
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Voice',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ModernDropdown<String>(
                            value: _selectedVoice,
                            items: _voicesForSelectedLanguage
                                .map((voice) => DropdownMenuItem<String>(
                                      value: voice.id,
                                      child: Text(
                                        _getVoiceDisplayName(voice),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ))
                                .toList(),
                            onChanged: widget.controller.isInitialized && _selectedLanguage != null 
                                ? _onVoiceChanged 
                                : null,
                            hint: 'Select Voice',
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
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Initializing TTS...'),
                  ],
                ),
              ),
            ),
            ],
          ),
        );
      },
    );
  }
}