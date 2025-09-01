import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import '../services/translation_service.dart';
import '../models/app_models.dart';
import '../constants/app_constants.dart';

class TranslationResultWidget extends StatefulWidget {
  final TranslationService translationService;
  final UnifiedTTSService? ttsService;

  const TranslationResultWidget({
    super.key,
    required this.translationService,
    this.ttsService,
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
              Icon(Icons.translate, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Translation results will appear here',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter text and select languages to get started',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和操作按钮
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
                  _buildActionButtons(context, translation),
                ],
              ),

              const SizedBox(height: 8),

              // 元数据
              _buildMetadata(context, translation),

              const SizedBox(height: 16),

              // 原文
              _buildOriginalText(context, translation),

              const SizedBox(height: 16),

              // 翻译结果
              _buildTranslations(context, translation),
            ],
          ),
        ),
      ),
    );
  }

  /// 播放TTS
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
          (voice) =>
              voice.locale.toLowerCase() == languageCode.toLowerCase(),
          orElse: () => availableVoices.first,
        );

        debugPrint('TTS: Using voice ${matchingVoice.name} for $language');

        // Synthesize text to audio data
        final audioData = await widget.ttsService!.synthesizeText(text, matchingVoice.name);
        
        // Play the audio (if audio data is not empty)
        if (audioData.isNotEmpty) {
          await _audioPlayer!.playBytes(audioData);
        }
        // If audioData is empty, it means the TTS engine played directly (e.g., Flutter TTS on web/windows)
        
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
      
      // 只显示用户友好的错误信息，不显示技术细节
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
      
      // 对于意外错误，显示简化的消息
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

  /// 停止TTS
  Future<void> _stopTTS(String language) async {
    try {
      // 停止音频播放器
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
      }
      
      // 如果是Flutter TTS直接播放，尝试停止
      if (widget.ttsService != null) {
        try {
          // 尝试停止TTS服务（如果支持）
          await widget.ttsService!.stop();
        } catch (e) {
          // 某些TTS引擎可能不支持停止，忽略错误
          debugPrint('TTS stop not supported: $e');
        }
      }
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    } finally {
      // 更新UI状态
      if (mounted) {
        setState(() {
          _playingStates[language] = false;
        });
      }
    }
  }

  /// 根据语言键获取语言代码（语言键可能是语言代码或语言名称）
  String? _getLanguageCode(String languageKey) {
    try {
      debugPrint('Processing language key: $languageKey');
      
      // 首先检查是否已经是语言代码格式（如 zh-CN, en-US）
      if (languageKey.contains('-') && languageKey.length >= 2) {
        final parts = languageKey.split('-');
        if (parts.length == 2 && parts[0].length == 2 && parts[1].length == 2) {
          debugPrint('Language key $languageKey is already a language code');
          return languageKey.toLowerCase();
        }
      }
      
      // 如果不是语言代码格式，尝试从语言名称映射中查找
      final map = LanguageConstants.translationLanguageNames;
      debugPrint('Available language mappings: ${map.entries.take(5).map((e) => '${e.key}: ${e.value}').join(', ')}...');
      
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

  /// 构建操作按钮
  Widget _buildActionButtons(
    BuildContext context,
    TranslationResult translation,
  ) {
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

  /// 构建元数据
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
          Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Model: ${translation.config.selectedModel} | '
              'Provider: ${translation.config.provider} | '
              'Generated: ${_formatTimestamp(translation.timestamp)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建原文显示
  Widget _buildOriginalText(
    BuildContext context,
    TranslationResult translation,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.article_outlined, size: 16, color: Colors.grey.shade600),
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
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  /// 构建翻译结果列表
  Widget _buildTranslations(
    BuildContext context,
    TranslationResult translation,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.language, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              'Translations:',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 直接使用 Column 列出所有翻译项
        ...translation.translations.entries.map((entry) {
          final language = entry.key;
          final translatedText = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTranslationItem(context, language, translatedText),
          );
        }),
      ],
    );
  }

  /// 构建单个翻译项
  Widget _buildTranslationItem(
    BuildContext context,
    String language,
    String translatedText,
  ) {
    final isPlaying = _playingStates[language] ?? false;
    final languageCode = _getLanguageCode(language);
    final hasTTS = widget.ttsService != null && languageCode != null && languageCode.isNotEmpty;
    
    // 调试信息
    debugPrint('Translation item for $language:');
    debugPrint('  - TTS Service: ${widget.ttsService != null ? 'Available' : 'Null'}');
    debugPrint('  - Language Code: $languageCode');
    debugPrint('  - Has TTS: $hasTTS');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 语言标题栏
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                Text(
                  language,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                // TTS播放按钮 - 强制显示用于调试
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.stop : Icons.volume_up,
                    size: 16,
                    color: hasTTS 
                        ? (isPlaying ? Colors.red : Colors.blue)
                        : Colors.grey,
                  ),
                  tooltip: hasTTS 
                      ? (isPlaying ? 'Stop speaking' : 'Play with TTS')
                      : 'TTS not available',
                  onPressed: hasTTS
                      ? (isPlaying
                          ? () => _stopTTS(language)
                          : () => _playTTS(language, translatedText))
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                // 复制按钮
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  tooltip: 'Copy translation',
                  onPressed: () =>
                      _copyTranslation(context, language, translatedText),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // 翻译文本
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              translatedText,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// 复制单个翻译
  void _copyTranslation(
    BuildContext context,
    String language,
    String translatedText,
  ) {
    Clipboard.setData(ClipboardData(text: translatedText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$language translation copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 复制所有翻译
  void _copyAllTranslations(
    BuildContext context,
    TranslationResult translation,
  ) {
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

  /// 格式化时间戳
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
