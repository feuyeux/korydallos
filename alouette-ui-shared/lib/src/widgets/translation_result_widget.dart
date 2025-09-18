import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import '../constants/language_constants.dart';
import '../tokens/dimension_tokens.dart';
import '../tokens/typography_tokens.dart';

class TranslationResultWidget extends StatefulWidget {
  final TranslationService translationService;
  final UnifiedTTSService? ttsService;
  final bool isCompactMode;
  final bool isTTSInitialized;

  const TranslationResultWidget({
    super.key,
    required this.translationService,
    this.ttsService,
    this.isCompactMode = false,
    this.isTTSInitialized = false,
  });

  @override
  State<TranslationResultWidget> createState() =>
      _TranslationResultWidgetState();
}

class _TranslationResultWidgetState extends State<TranslationResultWidget> {
  final Map<String, bool> _playingStates = {};
  AudioPlayer? _audioPlayer;

  @override
  Widget build(BuildContext context) {
    final translation = widget.translationService.currentTranslation;

    if (translation == null) {
      return Card(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.translate,
                size: widget.isCompactMode ? 32 : 48,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: widget.isCompactMode ? 8 : 16),
              Text(
                'Translation results will appear here',
                style: TextStyle(
                  fontSize: widget.isCompactMode
                      ? TypographyTokens.titleLargeStyle.fontSize!
                      : DimensionTokens.iconM,
                  color: Colors.grey.shade600,
                ),
              ),
              if (!widget.isCompactMode) ...[
                const SizedBox(height: 8),
                Text(
                  'Enter text and select languages to get started',
                  style: TextStyle(
                    fontSize: TypographyTokens.titleLargeStyle.fontSize!,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.l),
        child: widget.isCompactMode
            ? _buildCompactLayout(translation)
            : _buildStandardLayout(translation),
      ),
    );
  }

  Widget _buildStandardLayout(TranslationResult translation) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and action buttons
          Row(
            children: [
              const Icon(Icons.translate, size: 20),
              const SizedBox(width: 8),
              Text(
                'Translation Results',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              // _buildActionButtons(context, translation), // Removed
            ],
          ),

          const SizedBox(height: 8),

          // Metadata
          _buildMetadata(context, translation),

          const SizedBox(height: SpacingTokens.l),

          // Original text
          _buildOriginalText(context, translation),

          const SizedBox(height: SpacingTokens.l),

          // Translation results
          _buildTranslations(context, translation),
        ],
      ),
    );
  }

  Widget _buildCompactLayout(TranslationResult translation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact header with action buttons
        Row(
          children: [
            Icon(Icons.language, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              'Translations',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            // _buildActionButtons(context, translation), // Removed
          ],
        ),

        // Translations - 使用 Expanded 确保剩余空间被占用
        Expanded(
          child: _buildTranslations(context, translation),
        ),
      ],
    );
  }

  /* 
  Widget _buildActionButtons(
      BuildContext context, TranslationResult translation) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.copy),
          tooltip: 'Copy all translations',
          onPressed: () => _copyAllTranslations(context, translation),
        ),
        IconButton(
          icon: const Icon(Icons.clear),
          tooltip: 'Clear results',
          onPressed: () => widget.translationService.clearTranslation(),
        ),
      ],
    );
  }
  */

  Widget _buildMetadata(BuildContext context, TranslationResult translation) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              size: TypographyTokens.titleLargeStyle.fontSize!,
              color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Model: ${translation.config.selectedModel} | '
              'Provider: ${translation.config.provider} | '
              'Generated: ${_formatTimestamp(translation.timestamp)}',
              style: TextStyle(
                  fontSize: TypographyTokens.bodyMediumStyle.fontSize!,
                  color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalText(
      BuildContext context, TranslationResult translation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.article_outlined,
                size: DimensionTokens.iconM, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              'Original Text:',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            translation.original,
            style:
                TextStyle(fontSize: TypographyTokens.titleLargeStyle.fontSize!),
          ),
        ),
      ],
    );
  }

  Widget _buildTranslations(
      BuildContext context, TranslationResult translation) {
    if (widget.isCompactMode) {
      // 极简紧凑模式，直接显示列表
      return ListView.builder(
        itemCount: translation.languages.length,
        itemBuilder: (context, index) {
          final language = translation.languages[index];
          final translatedText = translation.translations[language] ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildTranslationItem(context, language, translatedText),
          );
        },
      );
    }

    // 标准模式保持原来的结构
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.language,
                size: DimensionTokens.iconM, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              'Translations:',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 300, // 可根据实际需求调整高度
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView.builder(
              itemCount: translation.languages.length,
              itemBuilder: (context, index) {
                final language = translation.languages[index];
                final translatedText = translation.translations[language] ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child:
                      _buildTranslationItem(context, language, translatedText),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTranslationItem(
      BuildContext context, String language, String translatedText) {
    final isPlaying = _playingStates[language] ?? false;
    final languageCode = _getLanguageCode(language);
    final hasTTS = widget.ttsService != null &&
        widget.isTTSInitialized &&
        languageCode != null &&
        languageCode.isNotEmpty;
    final isCompactStyle = widget.isCompactMode;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompactStyle ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language title bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isCompactStyle ? Colors.green.shade100 : Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                Text(
                  language,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: TypographyTokens.titleLargeStyle.fontSize!,
                    color: isCompactStyle ? Colors.green.shade800 : null,
                  ),
                ),
                const Spacer(),
                // TTS play button (always show if TTS available)
                if (hasTTS) ...[
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.stop : Icons.volume_up,
                      size: DimensionTokens.iconM,
                      color: isPlaying ? Colors.red : Colors.blue,
                    ),
                    tooltip: isPlaying ? 'Stop speaking' : 'Play with TTS',
                    onPressed: isPlaying
                        ? () => _stopTTS(language)
                        : () => _playTTS(language, translatedText),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                ],
                // Copy button
                IconButton(
                  icon: Icon(
                    Icons.copy,
                    size: DimensionTokens.iconM,
                    color: isCompactStyle ? Colors.green.shade700 : null,
                  ),
                  tooltip: 'Copy translation',
                  onPressed: () =>
                      _copyTranslation(context, language, translatedText),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Translation text
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              translatedText,
              style: TextStyle(
                  fontSize: TypographyTokens.titleLargeStyle.fontSize!),
            ),
          ),
        ],
      ),
    );
  }

  /// Play TTS for the given language and text
  Future<void> _playTTS(String language, String text) async {
    if (widget.ttsService == null) return;

    setState(() {
      _playingStates[language] = true;
    });

    try {
      // Initialize audio player if needed
      _audioPlayer ??= AudioPlayer();

      // Get language code and find matching voice
      final languageCode = _getLanguageCode(language);
      if (languageCode == null) return;

      final voices = await widget.ttsService!.getVoices();
      final availableVoices = voices
          .where(
            (voice) => voice.locale.toLowerCase().startsWith(
                  languageCode.toLowerCase().split('-')[0],
                ),
          )
          .toList();

      if (availableVoices.isNotEmpty) {
        // Prefer exact match for language code, fallback to first available
        final matchingVoice = availableVoices.firstWhere(
          (voice) => voice.locale.toLowerCase() == languageCode.toLowerCase(),
          orElse: () => availableVoices.first,
        );

        debugPrint('TTS: Using voice ${matchingVoice.name} for $language');

        // Synthesize text to audio data
        final audioData =
            await widget.ttsService!.synthesizeText(text, matchingVoice.name);

        // Play the audio (if audio data is not empty)
        if (audioData.isNotEmpty) {
          await _audioPlayer!.playBytes(audioData);
        }
        // If audioData is empty, it means the TTS engine played directly

        debugPrint('TTS: Playback completed for $language');
      } else {
        debugPrint('TTS: No voices available for language code: $languageCode');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No voices available for $language'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } on TTSError catch (e) {
      debugPrint('TTS Error for $language: ${e.message}');

      if (mounted) {
        String userMessage;
        if (e.code == TTSErrorCodes.voiceNotFound) {
          userMessage = '$language voice not available on this platform';
        } else if (e.code == TTSErrorCodes.platformNotSupported) {
          userMessage = '$language not supported in web browser';
        } else if (e.code == TTSErrorCodes.synthesisError) {
          userMessage = 'Failed to play $language audio';
        } else {
          userMessage = 'Cannot play $language on this device';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      debugPrint('Unexpected TTS error for $language: $error');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot play $language audio'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _playingStates[language] = false;
        });
      }
    }
  }

  /// Stop TTS playback
  Future<void> _stopTTS(String language) async {
    try {
      // Stop audio player
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
      }

      // Try to stop TTS service if supported
      if (widget.ttsService != null) {
        try {
          await widget.ttsService!.stop();
        } catch (e) {
          // Some TTS engines may not support stopping, ignore errors
          debugPrint('TTS stop not supported: $e');
        }
      }
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    } finally {
      // Update UI state
      if (mounted) {
        setState(() {
          _playingStates[language] = false;
        });
      }
    }
  }

  /// Get language code from language key (which may be code or name)
  String? _getLanguageCode(String languageKey) {
    try {
      debugPrint('Processing language key: $languageKey');

      // First check if it's already a language code format (e.g., zh-CN, en-US)
      if (languageKey.contains('-') && languageKey.length >= 2) {
        final parts = languageKey.split('-');
        if (parts.length == 2 && parts[0].length == 2 && parts[1].length == 2) {
          debugPrint('Language key $languageKey is already a language code');
          return languageKey.toLowerCase();
        }
      }

      // If not a language code format, try to find from language name mapping
      final map = LanguageConstants.translationLanguageNames;
      debugPrint(
          'Available language mappings: ${map.entries.take(5).map((e) => '${e.key}: ${e.value}').join(', ')}...');

      final entry = map.entries.firstWhere(
        (e) => e.value.toLowerCase() == languageKey.toLowerCase(),
        orElse: () => const MapEntry('', ''),
      );

      if (entry.key.isEmpty) {
        debugPrint('No language code found for: $languageKey');
        return null;
      }

      // Normalize to BCP-47 (xx-YY)
      final parts = entry.key.replaceAll('_', '-').split('-');
      final lang = parts[0].toLowerCase();
      if (parts.length == 1) {
        debugPrint('Language code for $languageKey: $lang');
        return lang;
      }
      final region = parts[1].toUpperCase();
      final result = '$lang-$region';
      debugPrint('Language code for $languageKey: $result');
      return result;
    } catch (e) {
      debugPrint('Error getting language code for $languageKey: $e');
      return null;
    }
  }

  void _copyTranslation(
      BuildContext context, String language, String translatedText) {
    Clipboard.setData(ClipboardData(text: translatedText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$language translation copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /*
  void _copyAllTranslations(
      BuildContext context, TranslationResult translation) {
    final buffer = StringBuffer();
    buffer.writeln('Translation Results');
    buffer.writeln('=' * 50);
    buffer.writeln('Generated: ${translation.timestamp}');
    buffer.writeln('Model: ${translation.config.selectedModel}');
    buffer.writeln('Provider: ${translation.config.provider}');
    buffer.writeln();
    buffer.writeln('Original Text:');
    buffer.writeln(translation.original);
    buffer.writeln();
    buffer.writeln('Translations:');

    for (final language in translation.languages) {
      final translatedText = translation.translations[language] ?? '';
      buffer.writeln();
      buffer.writeln('$language:');
      buffer.writeln(translatedText);
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All translations copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  */

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.month}/${timestamp.day} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
