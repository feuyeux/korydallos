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
  VoiceModel? _selectedVoice;
  LanguageOption? _selectedLanguageOption;
  List<VoiceModel> _availableVoicesForLanguage = [];

  @override
  void initState() {
    super.initState();
    // Initialize selected voice when controller is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSelection();
    });
  }

  void _initializeSelection() {
    if (widget.controller.isInitialized &&
        widget.controller.availableVoices.isNotEmpty) {
      // Always prioritize English as default
      _setDefaultEnglishVoice();
    }
  }

  void _setDefaultEnglishVoice() {
    setState(() {
      // 设置英文为默认语言选项
      _selectedLanguageOption = LanguageConstants.supportedLanguages.firstWhere(
        (lang) => lang.code.startsWith('en'),
        orElse: () => LanguageConstants.supportedLanguages[1],
      ); // Fallback to index 1 (English)

      // 查找英文语音
      final englishVoices = widget.controller.availableVoices
          .where((voice) => voice.languageCode.toLowerCase().startsWith('en'))
          .toList();

      if (englishVoices.isNotEmpty) {
        // 有英文语音，选择第一个英文语音
        _selectedVoice = englishVoices.first;
        _availableVoicesForLanguage = englishVoices;
        widget.controller.changeVoice(_selectedVoice!.id);
      } else {
        // 没有英文语音，使用第一个可用语音
        _selectedVoice = widget.controller.availableVoices.first;
        final voiceLanguagePrefix = _selectedVoice!.languageCode
            .split('-')
            .first
            .toLowerCase();
        _selectedLanguageOption =
            LanguageConstants.supportedLanguages.where((lang) {
              final langPrefix = lang.code.split('-').first.toLowerCase();
              return voiceLanguagePrefix == langPrefix;
            }).firstOrNull ??
            _selectedLanguageOption;

        final languagePrefix = _selectedLanguageOption!.code
            .split('-')
            .first
            .toLowerCase();
        _availableVoicesForLanguage = widget.controller.availableVoices
            .where(
              (voice) =>
                  voice.languageCode.toLowerCase().startsWith(languagePrefix),
            )
            .toList();
        widget.controller.changeVoice(_selectedVoice!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        // Update selection when controller state changes
        if (widget.controller.isInitialized &&
            widget.controller.availableVoices.isNotEmpty &&
            _selectedVoice == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeSelection();
          });
        }

        return ModernCard(
          child: Padding(
            padding: const EdgeInsets.all(6.0), // Reduced from 8 to 6
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.text_fields,
                      color: AppTheme.primaryColor,
                      size: 14, // Reduced from 16 to 14
                    ),
                    const SizedBox(width: 3), // Reduced from 4 to 3
                    const Text(
                      'Text Input',
                      style: TextStyle(
                        fontSize: 12, // Reduced from 13 to 12
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6), // Reduced from 8 to 6
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

                const SizedBox(height: 6), // Reduced from 8 to 6
                // Voice selection with language and voice dropdowns
                if (widget.controller.isInitialized &&
                    widget.controller.availableVoices.isNotEmpty)
                  _buildDualVoiceSelector(),

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

  Widget _buildDualVoiceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.record_voice_over,
              color: AppTheme.primaryColor,
              size: 14,
            ),
            const SizedBox(width: 3),
            const Text(
              'Voice Selection',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Language and Voice dropdowns
        Row(
          children: [
            // Language dropdown (left) - compact implementation
            Expanded(
              flex: 1,
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<LanguageOption>(
                    value: _selectedLanguageOption,
                    isExpanded: true,
                    isDense: true,
                    hint: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text('Language', style: TextStyle(fontSize: 11)),
                    ),
                    items: LanguageConstants.supportedLanguages
                        .map(
                          (lang) => DropdownMenuItem<LanguageOption>(
                            value: lang,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    lang.flag,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      lang.name,
                                      style: const TextStyle(fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (LanguageOption? language) {
                      setState(() {
                        _selectedLanguageOption = language;
                        if (language != null) {
                          final languagePrefix = language.code
                              .split('-')
                              .first
                              .toLowerCase();
                          _availableVoicesForLanguage = widget
                              .controller
                              .availableVoices
                              .where(
                                (voice) => voice.languageCode
                                    .toLowerCase()
                                    .startsWith(languagePrefix),
                              )
                              .toList();

                          // Auto-select first available voice for this language
                          if (_availableVoicesForLanguage.isNotEmpty) {
                            _selectedVoice = _availableVoicesForLanguage.first;
                            widget.controller.changeVoice(_selectedVoice!.id);
                          } else {
                            _selectedVoice = null;
                          }
                        } else {
                          _availableVoicesForLanguage = [];
                          _selectedVoice = null;
                        }
                      });
                    },
                    icon: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.arrow_drop_down, size: 16),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Voice dropdown (right) - compact implementation
            Expanded(
              flex: 2,
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<VoiceModel>(
                    value: _selectedVoice,
                    isExpanded: true,
                    isDense: true,
                    hint: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text('Voice', style: TextStyle(fontSize: 11)),
                    ),
                    items: _availableVoicesForLanguage
                        .map(
                          (voice) => DropdownMenuItem<VoiceModel>(
                            value: voice,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                '${voice.displayName} (${voice.gender.name})',
                                style: const TextStyle(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (_selectedLanguageOption != null)
                        ? (VoiceModel? voice) {
                            setState(() {
                              _selectedVoice = voice;
                            });
                            if (voice != null) {
                              widget.controller.changeVoice(voice.id);
                            }
                          }
                        : null,
                    icon: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.arrow_drop_down, size: 16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
