import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'package:alouette_lib_tts/alouette_tts.dart' as tts_lib;
import '../constants/language_constants.dart';
import '../tokens/dimension_tokens.dart';
import '../tokens/typography_tokens.dart';

class TranslationResultWidget extends StatefulWidget {
  final TranslationService translationService;
  final tts_lib.TTSService? ttsService;
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
  tts_lib.AudioPlayer? _audioPlayer;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Listen to translation service changes
    widget.translationService.addListener(_onTranslationChanged);
  }

  @override
  void dispose() {
    widget.translationService.removeListener(_onTranslationChanged);
    _audioPlayer?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTranslationChanged() {
    if (mounted) {
      setState(() {
        // Trigger rebuild when translation changes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final translation = widget.translationService.currentTranslation;

    if (translation == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: SpacingTokens.l),
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
                  fontSize: widget.isCompactMode ? 12 : 14,
                  color: Colors.grey.shade600,
                ),
              ),
              if (!widget.isCompactMode) ...[
                const SizedBox(height: 8),
                Text(
                  'Enter text and select languages to get started',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // 紧凑模式：直接返回可滚动布局，不添加额外的 Padding
    if (widget.isCompactMode) {
      return _buildCompactLayout(translation);
    }

    // 标准模式：添加 padding
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.s),
      child: _buildStandardLayout(translation),
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
            Text('Translations', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            // _buildActionButtons(context, translation), // Removed
          ],
        ),
        const SizedBox(height: 8),

        // Translations - 使用 Expanded 和 ListView 确保可滚动
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              itemCount: translation.languages.length,
              itemBuilder: (context, index) {
                final language = translation.languages[index];
                final translatedText = translation.translations[language] ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildTranslationItem(context, language, translatedText),
                );
              },
            ),
          ),
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
    // 根据设备类型动态调整模型名称显示
    String getShortModelName(String fullName, {required bool isCompact}) {
      // 移除常见的后缀如 :latest
      String name = fullName.replaceFirst(':latest', '');
      
      if (isCompact) {
        // 移动设备：激进简化，限制在20个字符
        if (name.length > 20) {
          // 例: "qwen2.5-coder:7b-instruct" -> "qwen2.5-coder:7b"
          name = name.split('-').take(2).join('-');
          if (name.length > 20) {
            // 如果还是太长，只保留主要部分
            name = name.split(':').first;
          }
        }
      } else {
        // 桌面/Web：保留更多信息，限制在40个字符
        if (name.length > 40) {
          name = name.substring(0, 37) + '...';
        }
      }
      
      return name;
    }

    final shortModel = getShortModelName(
      translation.config.selectedModel,
      isCompact: widget.isCompactMode,
    );
    final shortProvider = translation.config.provider.toLowerCase();
    final timestamp = _formatTimestamp(translation.timestamp);

    // 移动设备使用紧凑格式，桌面使用完整格式
    final displayText = widget.isCompactMode
        ? '$shortProvider $shortModel • $timestamp'
        : 'Model: $shortModel | Provider: $shortProvider | Generated: $timestamp';

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: TypographyTokens.titleLargeStyle.fontSize!,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: TypographyTokens.bodyMediumStyle.fontSize!,
                color: Colors.grey.shade700,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalText(
    BuildContext context,
    TranslationResult translation,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.article_outlined,
              size: DimensionTokens.iconM,
              color: Colors.grey.shade600,
            ),
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
            style: TextStyle(
              fontSize: TypographyTokens.titleLargeStyle.fontSize!,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTranslations(
    BuildContext context,
    TranslationResult translation,
  ) {
    // 标准模式：显示完整信息，带固定高度滚动
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.language,
              size: DimensionTokens.iconM,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              'Translations:',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 4), // Reduced from 8 to 4
        SizedBox(
          height: 400, // 增加高度从 300 到 400，给翻译结果更多空间
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: translation.languages.length,
              itemBuilder: (context, index) {
                final language = translation.languages[index];
                final translatedText = translation.translations[language] ?? '';
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 8,
                  ), // Reduced from 12 to 8
                  child: _buildTranslationItem(
                    context,
                    language,
                    translatedText,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTranslationItem(
    BuildContext context,
    String language,
    String translatedText,
  ) {
    final isPlaying = _playingStates[language] ?? false;
    final languageCode = _getLanguageCode(language);
    final hasTTS =
        widget.ttsService != null &&
        widget.isTTSInitialized &&
        languageCode != null &&
        languageCode.isNotEmpty;
    final isCompactStyle = widget.isCompactMode;

    return Container(
      width: double.infinity,
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
            padding: EdgeInsets.symmetric(
              horizontal: isCompactStyle ? 8 : 12,
              vertical: isCompactStyle ? 4 : 8,
            ),
            decoration: BoxDecoration(
              color: isCompactStyle
                  ? Colors.green.shade100
                  : Colors.grey.shade100,
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
                    fontSize: isCompactStyle ? 11 : 14,
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
            padding: EdgeInsets.all(
              isCompactStyle ? 8 : 12,
            ), // Slightly reduced padding
            child: Text(
              translatedText,
              style: TextStyle(
                fontSize: isCompactStyle
                    ? TypographyTokens.bodySmallStyle.fontSize!
                    : TypographyTokens.bodyLargeStyle.fontSize!,
              ),
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
      _audioPlayer ??= tts_lib.AudioPlayer();

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
        // 使用智能语音选择策略，选择最高质量的人声
        final matchingVoice = _selectBestVoice(availableVoices, languageCode);

        debugPrint('🎤 Selected voice for $language: ${matchingVoice.name} (${matchingVoice.locale})');

        // Synthesize text to audio data
        final audioData = await widget.ttsService!.synthesizeText(
          text,
          matchingVoice.name,
        );

        // Check if this is minimal audio data (direct playback mode)
        // In direct playback mode (Web/macOS), the TTS engine plays directly
        // and returns a minimal placeholder (≤10 bytes)
        if (audioData.length <= 10) {
          debugPrint('TTS: Direct playback mode - audio already played for $language');
          // Wait a bit to ensure playback completes
          await Future.delayed(const Duration(milliseconds: 500));
        } else {
          // Play the audio file for desktop/mobile platforms
          try {
            await _audioPlayer!.playBytes(audioData);
            debugPrint('TTS: File playback completed for $language');
          } catch (playbackError) {
            // If playback fails, clear cache and rethrow
            debugPrint('❌ Playback failed for $language, clearing cache: $playbackError');
            // Clear cache for this specific text+voice combination to allow retry
            widget.ttsService!.clearAudioCacheItem(
              text,
              matchingVoice.name,
              format: 'mp3',
            );
            rethrow;
          }
        }

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
    } on tts_lib.TTSError catch (e) {
      debugPrint('TTS Error for $language: ${e.message}');

      // Clear cache on synthesis errors to allow retry
      if (e.code == tts_lib.TTSErrorCodes.synthesisError ||
          e.code == tts_lib.TTSErrorCodes.voiceNotFound ||
          e.code == tts_lib.TTSErrorCodes.platformNotSupported) {
        widget.ttsService?.clearAudioCacheItem(text, '', format: 'mp3');
        debugPrint('🗑️ Cleared cache due to TTS error');
      }

      if (mounted) {
        String userMessage;
        if (e.code == tts_lib.TTSErrorCodes.voiceNotFound) {
          userMessage = '$language voice not available on this platform';
        } else if (e.code == tts_lib.TTSErrorCodes.platformNotSupported) {
          userMessage = '$language not supported in web browser';
        } else if (e.code == tts_lib.TTSErrorCodes.synthesisError) {
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
      debugPrint('❌ Unexpected error playing $language TTS: $error');
      // Only show error if it's not related to minimal audio data playback
      if (mounted && !error.toString().contains('minimal') && !error.toString().contains('Direct playback')) {
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
      debugPrint('🔍 Processing language key: $languageKey');

      // First check if it's already a language code format (e.g., zh-CN, en-US, ru-RU)
      if (languageKey.contains('-')) {
        final parts = languageKey.split('-');
        if (parts.length == 2 && parts[0].length == 2) {
          debugPrint('✅ Language key $languageKey is already a language code');
          return languageKey.toLowerCase();
        }
      }

      // If not a language code format, try to find from language name mapping
      final map = LanguageConstants.translationLanguageNames;
      debugPrint(
        '📋 Available language mappings: ${map.entries.take(3).map((e) => '${e.key}: ${e.value}').join(', ')}...',
      );

      final entry = map.entries.firstWhere(
        (e) => e.value.toLowerCase() == languageKey.toLowerCase(),
        orElse: () => const MapEntry('', ''),
      );

      if (entry.key.isEmpty) {
        debugPrint('❌ No language code found for: $languageKey');
        return null;
      }

      // Normalize to BCP-47 (xx-YY)
      final parts = entry.key.replaceAll('_', '-').split('-');
      final lang = parts[0].toLowerCase();
      if (parts.length == 1) {
        debugPrint('✅ Language code for $languageKey: $lang');
        return lang;
      }
      final region = parts[1].toUpperCase();
      final result = '$lang-$region';
      debugPrint('✅ Language code for $languageKey: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Error getting language code for $languageKey: $e');
      return null;
    }
  }

  /// 选择最佳语音 - 针对每种语言选择最高质量的人声
  /// 同时支持 Flutter TTS (iOS/Android) 和 Edge TTS (Desktop)
  tts_lib.VoiceModel _selectBestVoice(
    List<tts_lib.VoiceModel> voices,
    String languageCode,
  ) {
    if (voices.isEmpty) {
      throw Exception('No voices available');
    }

    // 检查是否是 Edge TTS（通过语音名称模式识别）
    final isEdgeTTS = voices.any((v) => 
      v.name.contains('-') && 
      (v.name.contains('Neural') || v.name.toLowerCase().contains('neural'))
    );

    if (isEdgeTTS) {
      return _selectBestEdgeVoice(voices, languageCode);
    } else {
      return _selectBestFlutterVoice(voices, languageCode);
    }
  }

  /// 选择最佳 Edge TTS 语音（桌面平台）
  /// Edge TTS 提供高质量的神经网络语音
  tts_lib.VoiceModel _selectBestEdgeVoice(
    List<tts_lib.VoiceModel> voices,
    String languageCode,
  ) {
    // Edge TTS 首选神经网络语音（Neural）
    final preferredEdgeVoices = {
      'en-us': ['en-US-AriaNeural', 'en-US-JennyNeural', 'en-US-GuyNeural'],
      'en-gb': ['en-GB-SoniaNeural', 'en-GB-RyanNeural'],
      'zh-cn': ['zh-CN-XiaoxiaoNeural', 'zh-CN-YunxiNeural', 'zh-CN-YunjianNeural'],
      'zh-tw': ['zh-TW-HsiaoChenNeural', 'zh-TW-YunJheNeural'],
      'ja-jp': ['ja-JP-NanamiNeural', 'ja-JP-KeitaNeural'],
      'ko-kr': ['ko-KR-SunHiNeural', 'ko-KR-InJoonNeural'],
      'fr-fr': ['fr-FR-DeniseNeural', 'fr-FR-HenriNeural'],
      'de-de': ['de-DE-KatjaNeural', 'de-DE-ConradNeural'],
      'es-es': ['es-ES-ElviraNeural', 'es-ES-AlvaroNeural'],
      'it-it': ['it-IT-ElsaNeural', 'it-IT-DiegoNeural'],
      'ru-ru': ['ru-RU-SvetlanaNeural', 'ru-RU-DmitryNeural'],
      'ar-sa': ['ar-SA-ZariyahNeural', 'ar-SA-HamedNeural'],
      'pt-br': ['pt-BR-FranciscaNeural', 'pt-BR-AntonioNeural'],
    };

    final langKey = languageCode.toLowerCase();
    final preferredNames = preferredEdgeVoices[langKey] ?? [];

    // 第一轮：精确匹配首选神经网络语音
    for (final preferredName in preferredNames) {
      final exactMatch = voices.firstWhere(
        (v) => v.name == preferredName,
        orElse: () => voices.first,
      );
      if (exactMatch.name == preferredName) {
        debugPrint('✅ Found preferred Edge TTS voice: ${exactMatch.name}');
        return exactMatch;
      }
    }

    // 第二轮：选择该语言的任意神经网络语音
    final neuralVoices = voices.where(
      (v) => v.locale.toLowerCase().startsWith(langKey.split('-')[0]) && 
             (v.name.contains('Neural') || v.isNeural),
    ).toList();

    if (neuralVoices.isNotEmpty) {
      // 优先女声（通常更清晰自然）
      final femaleNeural = neuralVoices.firstWhere(
        (v) => v.gender.toString().toLowerCase().contains('female'),
        orElse: () => neuralVoices.first,
      );
      debugPrint('✅ Selected Edge TTS neural voice: ${femaleNeural.name}');
      return femaleNeural;
    }

    // 第三轮：任何匹配语言的语音
    final langMatches = voices.where(
      (v) => v.locale.toLowerCase().startsWith(langKey.split('-')[0]),
    ).toList();

    if (langMatches.isNotEmpty) {
      debugPrint('⚠️ Using Edge TTS fallback voice: ${langMatches.first.name}');
      return langMatches.first;
    }

    debugPrint('⚠️ Using first available voice: ${voices.first.name}');
    return voices.first;
  }

  /// 选择最佳 Flutter TTS 语音（iOS/Android/移动平台）
  /// 优先选择系统增强版和高质量人声
  tts_lib.VoiceModel _selectBestFlutterVoice(
    List<tts_lib.VoiceModel> voices,
    String languageCode,
  ) {
    // iOS/Android 系统语音首选列表
    final preferredFlutterVoices = {
      'en-us': ['Samantha', 'Ava (Enhanced)', 'Ava', 'Nicky', 'Susan'],
      'en-gb': ['Kate', 'Serena', 'Daniel'],
      'zh-cn': ['Tingting', 'Sinji'],
      'zh-tw': ['Meijia', 'Sinji'],
      'ja-jp': ['Kyoko', 'O-Ren'],
      'ko-kr': ['Yuna', 'Sora'],
      'fr-fr': ['Thomas', 'Amélie'],
      'de-de': ['Anna', 'Helena'],
      'es-es': ['Monica', 'Paulina'],
      'it-it': ['Alice', 'Luca'],
      'ru-ru': ['Milena', 'Yuri'],
      'ar-sa': ['Maged', 'Laila'],
      'pt-br': ['Luciana', 'Joana'],
    };

    final langKey = languageCode.toLowerCase();
    final preferredNames = preferredFlutterVoices[langKey] ?? [];

    // 第一轮：精确匹配首选系统语音
    for (final preferredName in preferredNames) {
      final exactMatch = voices.firstWhere(
        (v) => v.name.toLowerCase() == preferredName.toLowerCase(),
        orElse: () => voices.first,
      );
      if (exactMatch.name.toLowerCase() == preferredName.toLowerCase()) {
        debugPrint('✅ Found preferred Flutter TTS voice: ${exactMatch.name}');
        return exactMatch;
      }
    }

    // 第二轮：选择精确匹配语言代码的语音
    final exactLocaleMatches = voices.where(
      (v) => v.locale.toLowerCase() == langKey,
    ).toList();

    if (exactLocaleMatches.isNotEmpty) {
      // 优先增强版
      final enhanced = exactLocaleMatches.firstWhere(
        (v) => v.name.toLowerCase().contains('enhanced'),
        orElse: () => exactLocaleMatches.first,
      );
      if (enhanced.name.toLowerCase().contains('enhanced')) {
        debugPrint('✅ Found enhanced Flutter TTS voice: ${enhanced.name}');
        return enhanced;
      }

      // 优先女声
      final female = exactLocaleMatches.firstWhere(
        (v) => v.gender.toString().toLowerCase().contains('female'),
        orElse: () => exactLocaleMatches.first,
      );
      debugPrint('✅ Selected Flutter TTS voice: ${female.name}');
      return female;
    }

    // 第三轮：语言匹配的第一个语音
    debugPrint('⚠️ Using Flutter TTS fallback voice: ${voices.first.name}');
    return voices.first;
  }

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
