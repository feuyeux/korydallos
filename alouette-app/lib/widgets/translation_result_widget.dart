import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import '../services/translation_service.dart';
import '../models/app_models.dart';
import '../constants/app_constants.dart';

class TranslationResultWidget extends StatefulWidget {
  final TranslationService translationService;
  final AlouetteTTSService? ttsService;

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
      // 获取当前TTS配置
      final currentConfig = widget.ttsService!.currentConfig;

      // 获取语言代码并直接播放
      final languageCode = _getLanguageCode(language);
      if (languageCode == null) return;

      // Normalize language code to hyphen form and format to BCP-47 (xx-YY)
      String toBCP47(String raw) {
        final parts = raw.replaceAll('_', '-').split('-');
        if (parts.isEmpty) return raw;
        final lang = parts[0].toLowerCase();
        if (parts.length == 1) return lang;
        final region = parts[1].toUpperCase();
        return '$lang-$region';
      }

      final normalizedLang = languageCode.replaceAll('_', '-');
      final bcp47Lang = toBCP47(normalizedLang);
      final normalizedLangLower = bcp47Lang.toLowerCase();

      // Determine default voice name consistent with alouette-tts mapping
      String? defaultVoice;
      switch (normalizedLangLower) {
        case 'zh-cn':
          defaultVoice = 'zh-CN-XiaoxiaoNeural';
          break;
        case 'en-us':
          defaultVoice = 'en-US-AriaNeural';
          break;
        case 'de-de':
          defaultVoice = 'de-DE-KatjaNeural';
          break;
        case 'fr-fr':
          defaultVoice = 'fr-FR-DeniseNeural';
          break;
        case 'es-es':
          defaultVoice = 'es-ES-ElviraNeural';
          break;
        case 'it-it':
          defaultVoice = 'it-IT-ElsaNeural';
          break;
        case 'ru-ru':
          defaultVoice = 'ru-RU-SvetlanaNeural';
          break;
        case 'el-gr':
          defaultVoice = 'el-GR-AthinaNeural';
          break;
        case 'ar-sa':
          defaultVoice = 'ar-SA-ZariyahNeural';
          break;
        case 'hi-in':
          defaultVoice = 'hi-IN-SwaraNeural';
          break;
        case 'ja-jp':
          defaultVoice = 'ja-JP-NanamiNeural';
          break;
        case 'ko-kr':
          defaultVoice = 'ko-KR-SunHiNeural';
          break;
        default:
          defaultVoice = 'en-US-AriaNeural';
      }

      // If the current config's language matches the requested language, prefer its voice name
      final voiceNameToUse = (currentConfig.voiceName != null &&
              (currentConfig.languageCode.toLowerCase() == normalizedLangLower))
          ? currentConfig.voiceName
          : defaultVoice;

      final config = AlouetteTTSConfig(
        speechRate: currentConfig.speechRate,
        volume: currentConfig.volume,
        pitch: currentConfig.pitch,
        languageCode: bcp47Lang, // BCP-47 style (e.g. fr-FR)
        voiceName: voiceNameToUse,
      );

      await widget.ttsService!.speak(text, config: config);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TTS Error for $language: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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
    if (widget.ttsService == null) return;

    await widget.ttsService!.stop();
    setState(() {
      _playingStates[language] = false;
    });
  }

  /// 根据语言名称获取语言代码
  String? _getLanguageCode(String languageName) {
    // Reverse lookup LanguageConstants.translationLanguageNames which maps
    // language code -> language display name. We find the code by name.
    try {
      final map = LanguageConstants.translationLanguageNames;
      final entry = map.entries.firstWhere(
        (e) => e.value.toLowerCase() == languageName.toLowerCase(),
        orElse: () => const MapEntry('', ''),
      );

      if (entry.key.isEmpty) return null;

      // Normalize to BCP-47 (xx-YY)
      final parts = entry.key.replaceAll('_', '-').split('-');
      final lang = parts[0].toLowerCase();
      if (parts.length == 1) return lang;
      final region = parts[1].toUpperCase();
      return '$lang-$region';
    } catch (e) {
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
    final hasTTS =
        widget.ttsService != null && _getLanguageCode(language) != null;

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
                // TTS播放按钮
                if (hasTTS) ...[
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.stop : Icons.volume_up,
                      size: 16,
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
