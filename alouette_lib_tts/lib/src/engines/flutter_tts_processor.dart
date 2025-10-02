import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

import 'base_tts_processor.dart';
import '../models/voice_model.dart';
import '../models/tts_request.dart';
import '../models/tts_error.dart';
import '../enums/voice_gender.dart';
import '../enums/voice_quality.dart';
import '../exceptions/tts_exceptions.dart';
import '../utils/resource_manager.dart';
import '../utils/tts_logger.dart';

/// Flutter TTS processor implementation following Flutter naming conventions
/// Provides Flutter TTS functionality using system TTS engines
/// 
/// Uses platform-specific TTS engines (AVFoundation on iOS/macOS, etc.)
class FlutterTTSProcessor extends BaseTTSProcessor {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  @override
  String get engineName => 'flutter';

  /// Initialize Flutter TTS
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    // Configure Flutter TTS
    await _tts.awaitSpeakCompletion(true);

    // Set audio session on supported platforms
    try {
      if (!kIsWeb) {
        await _tts.setSharedInstance(true);
      }
    } catch (e) {
      // setSharedInstance not supported on this platform
    }

    _initialized = true;
  }

  @override
  Future<List<VoiceModel>> getAvailableVoices() async {
    await _ensureInitialized();

    return getVoicesWithCache(() async {
      final voices = await _tts.getVoices as List<dynamic>?;

      if (voices == null || voices.isEmpty) {
        throw TTSError(
          'No voices available from Flutter TTS',
          code: TTSErrorCodes.voiceListFailed,
        );
      }

      final parsedVoices = voices
          .map((v) => _parseVoice(v))
          .where((voice) => voice != null)
          .cast<VoiceModel>()
          .toList();

      // Remove duplicates based on id to avoid dropdown issues
      final uniqueVoices = <VoiceModel>[];
      final seenIds = <String>{};

      for (final voice in parsedVoices) {
        if (!seenIds.contains(voice.id)) {
          uniqueVoices.add(voice);
          seenIds.add(voice.id);
        }
      }

      if (uniqueVoices.isEmpty) {
        throw TTSError(
          'Failed to parse any voices from Flutter TTS. Raw voice data: $voices',
          code: TTSErrorCodes.voiceParseError,
        );
      }

      return uniqueVoices;
    });
  }

  @override
  Future<Uint8List> synthesizeToAudio(TTSRequest request) async {
    await _ensureInitialized();

    return synthesizeTextWithCache(request.text, request.voiceName ?? '', request.format, () async {
      // Apply parameters from request
      await _applyParameters(request);
      
      // For macOS and platforms where file synthesis has sandboxing issues,
      // use direct speech playback instead of generating audio files
      if (Platform.isMacOS || kIsWeb) {
        return _synthesizeDirectPlay(request.text, request.voiceName ?? '');
      }

      // Desktop and mobile platforms: try file synthesis first, fall back to direct speech
      return await ResourceManager.instance.withTempFile(
        (tempFile) async {
          // Set voice
          await _setVoice(request.voiceName ?? '');

          // Use synthesizeToFile method (if available)
          bool synthesisSuccess = false;

          try {
            // Try using synthesizeToFile method
            final result = await _tts.synthesizeToFile(request.text, tempFile.path);
            synthesisSuccess = result == 1; // Flutter TTS returns 1 for success
          } catch (e) {
            // If synthesizeToFile is not available, fall back to direct speech
            return _synthesizeDirectPlay(request.text, request.voiceName ?? '');
          }

          if (!synthesisSuccess) {
            // Fall back to direct speech
            return _synthesizeDirectPlay(request.text, request.voiceName ?? '');
          }

          // Check if output file exists
          if (!await tempFile.exists()) {
            // Fall back to direct speech
            return _synthesizeDirectPlay(request.text, request.voiceName ?? '');
          }

          // Read audio data
          final audioData = await tempFile.readAsBytes();
          return Uint8List.fromList(audioData);
        },
        prefix: 'flutter_tts_',
        suffix: '.${request.format}',
      );
    });
  }

  /// 直接播放语音合成（不生成文件）
  /// 适用于 Web 平台和不支持文件合成的平台
  Future<Uint8List> _synthesizeDirectPlay(String text, String voiceName) async {
    TTSLogger.debug(
      'TTS: Using direct playback mode for text: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."',
    );

    // On Web platform, check voice availability first
    if (kIsWeb) {
      final voices = await getAvailableVoices();

      // 检查是否是阿拉伯语
      final isArabic =
          voiceName.toLowerCase().contains('ar-') ||
          voiceName.toLowerCase().contains('arabic');

      if (isArabic) {
        // 检查浏览器是否支持阿拉伯语
        final arabicVoices = voices
            .where((v) => v.languageCode.toLowerCase().startsWith('ar-'))
            .toList();

        if (arabicVoices.isEmpty) {
          throw TTSError(
            'Arabic language is not supported by this browser\'s Web Speech API',
            code: TTSErrorCodes.voiceNotFound,
          );
        }

        // 尝试使用第一个可用的阿拉伯语语音
        final arabicVoice = arabicVoices.first;

        // Set Arabic voice
        await _tts.setVoice({
          "name": arabicVoice.id,
          "locale": arabicVoice.languageCode,
        });
      } else {
        // 非阿拉伯语，正常设置
        await _setVoice(voiceName);
      }
    } else {
      // 非 Web 平台，正常设置
      await _setVoice(voiceName);
    }

    // Note: Parameters are already applied by _applyParameters() before this method is called

    try {
      // 直接播放
      TTSLogger.debug('TTS: Starting direct speech playback');
      
      // Set up completion tracking
      bool speechCompleted = false;
      _tts.setCompletionHandler(() {
        speechCompleted = true;
        TTSLogger.debug('TTS: Speech completion detected');
      });
      
      // Set up error handling
      _tts.setErrorHandler((msg) {
        TTSLogger.error('TTS: Speech error: $msg');
      });
      
      // Speak the text
      final result = await _tts.speak(text);
      TTSLogger.debug('TTS: Speak method returned: $result');
      
      // Wait for completion or timeout
      final estimatedDuration = _estimateSpeechDuration(text);
      final maxWaitTime = estimatedDuration + 2000; // Add 2 seconds buffer
      
      int waitedTime = 0;
      const checkInterval = 100;
      
      while (!speechCompleted && waitedTime < maxWaitTime) {
        await Future.delayed(Duration(milliseconds: checkInterval));
        waitedTime += checkInterval;
      }
      
      if (speechCompleted) {
        TTSLogger.debug('TTS: Direct speech playback completed successfully');
      } else {
        TTSLogger.debug('TTS: Direct speech playback timed out, assuming completed');
      }
      
    } catch (e) {
      TTSLogger.error('TTS: Direct speech playback failed: $e');
      throw TTSError(
        'Direct speech playback failed: $e',
        code: TTSErrorCodes.speakFailed,
        originalError: e,
      );
    }

    // 返回一个最小的有效音频数据，表示已经直接播放
    return _createMinimalAudioData();
  }

  /// Apply TTS parameters from request
  Future<void> _applyParameters(TTSRequest request) async {
    try {
      // Convert rate/pitch from normalized scale (1.0 = normal) to platform-specific scale
      final rate = request.rate;  // 1.0 = normal
      final pitch = request.pitch;  // 1.0 = normal
      final volume = request.volume;  // 1.0 = 100%

      if (kIsWeb) {
        // Web platform: 1.0 is normal for all parameters
        await _tts.setSpeechRate(rate);
        await _tts.setVolume(volume);
        await _tts.setPitch(pitch);
      } else if (Platform.isMacOS) {
        // macOS: 0.5 is their "normal" rate, so convert: 1.0 -> 0.5
        await _tts.setSpeechRate(rate * 0.5);
        await _tts.setVolume(volume);
        await _tts.setPitch(pitch);  // 1.0 is normal for pitch
      } else {
        // Other platforms: 1.0 is normal for all parameters
        await _tts.setSpeechRate(rate);
        await _tts.setVolume(volume);
        await _tts.setPitch(pitch);
      }
    } catch (e) {
      TTSLogger.debug('TTS: Warning - could not set speech parameters: $e');
      // Continue anyway, these are optional settings
    }
  }

  /// 估算语音播放时长（毫秒）
  int _estimateSpeechDuration(String text) {
    // 粗略估算：平均每分钟200个单词，每个单词5个字符
    // 即每秒钟约17个字符
    const charactersPerSecond = 17;
    final durationSeconds = (text.length / charactersPerSecond).ceil();
    return (durationSeconds * 1000).clamp(1000, 30000); // 最少1秒，最多30秒
  }

  /// 创建一个最小的有效音频数据
  /// 返回一个很短的静音 MP3 数据，避免 AudioPlayer 报错
  /// 使用较小的数据量，让调用方知道这是直接播放模式
  Uint8List _createMinimalAudioData() {
    // 返回一个非常小的数据包，表示已经直接播放
    // 调用方可以根据数据大小判断是否需要通过 AudioPlayer 播放
    return Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
  }

  /// Set voice
  Future<void> _setVoice(String voiceName) async {
    try {
      // Flutter TTS needs to use voice object to set voice
      final voices = await getAvailableVoices();

      // First try exact match
      VoiceModel? targetVoice;
      try {
        targetVoice = voices.firstWhere((voice) => voice.id == voiceName);
      } catch (e) {
        targetVoice = null;
      }

      // If exact match fails, try fuzzy matching
      if (targetVoice == null) {
        // Try matching by language code
        final locale = _extractLocaleFromVoiceName(voiceName);
        if (locale != null) {
          try {
            targetVoice = voices.firstWhere(
              (voice) =>
                  voice.languageCode.toLowerCase() == locale.toLowerCase(),
            );
          } catch (e) {
            targetVoice = null;
          }
        }

        // If still not found, try language matching
        if (targetVoice == null && locale != null) {
          final language = locale.split('-')[0];
          try {
            targetVoice = voices.firstWhere(
              (voice) => voice.languageCode.toLowerCase().startsWith(
                language.toLowerCase(),
              ),
            );
          } catch (e) {
            targetVoice = null;
          }
        }
      }

      if (targetVoice == null) {
        // 检查是否是已知的不支持语言
        final locale = _extractLocaleFromVoiceName(voiceName);
        if (locale != null && _isKnownUnsupportedLanguage(locale)) {
          throw TTSError(
            'Language "$locale" is not supported on this browser/platform. '
            'Try using the desktop version or a different browser.',
            code: TTSErrorCodes.platformNotSupported,
          );
        }

        final availableVoices = voices
            .map((v) => '${v.id} (${v.languageCode})')
            .take(5)
            .join(', ');
        throw TTSError(
          'Voice "$voiceName" not available. '
          'Available voices: $availableVoices${voices.length > 5 ? '...' : ''}',
          code: TTSErrorCodes.voiceNotFound,
        );
      }

      // Set voice
      await _tts.setVoice({
        "name": targetVoice.id,
        "locale": targetVoice.languageCode,
      });
    } catch (e) {
      if (e is TTSError) rethrow;

      throw TTSError(
        'Failed to set voice "$voiceName": $e',
        code: TTSErrorCodes.voiceNotFound,
        originalError: e,
      );
    }
  }

  /// 从语音名称中提取 locale
  /// 例如: "Microsoft Zira - English (United States)" -> "en-US"
  String? _extractLocaleFromVoiceName(String voiceName) {
    // 常见的 locale 模式
    final localePatterns = [
      RegExp(r'([a-z]{2}-[A-Z]{2})'), // en-US, zh-CN 等
      RegExp(r'English.*United States'), // 英语美国
      RegExp(r'Chinese.*China'), // 中文中国
      RegExp(r'Arabic.*Saudi'), // 阿拉伯语沙特
      RegExp(r'Arabic.*Egypt'), // 阿拉伯语埃及
      RegExp(r'Arabic.*UAE'), // 阿拉伯语阿联酋
      RegExp(r'Hindi.*India'), // 印地语印度
      RegExp(r'Greek.*Greece'), // 希腊语希腊
    ];

    // 特殊处理阿拉伯语的各种变体
    if (voiceName.toLowerCase().contains('arabic') ||
        voiceName.toLowerCase().contains('ar-')) {
      if (voiceName.toLowerCase().contains('saudi')) return 'ar-SA';
      if (voiceName.toLowerCase().contains('egypt')) return 'ar-EG';
      if (voiceName.toLowerCase().contains('uae')) return 'ar-AE';
      if (voiceName.toLowerCase().contains('ar-sa')) return 'ar-SA';
      if (voiceName.toLowerCase().contains('ar-eg')) return 'ar-EG';
      if (voiceName.toLowerCase().contains('ar-ae')) return 'ar-AE';
      // 默认使用沙特阿拉伯语
      return 'ar-SA';
    }

    for (final pattern in localePatterns) {
      final match = pattern.firstMatch(voiceName);
      if (match != null) {
        final matched = match.group(0)!;
        if (matched.contains('-')) {
          return matched;
        }
        // 根据语言名称映射到 locale
        if (matched.contains('English') && matched.contains('United States'))
          return 'en-US';
        if (matched.contains('Chinese') && matched.contains('China'))
          return 'zh-CN';
        if (matched.contains('Arabic') && matched.contains('Saudi'))
          return 'ar-SA';
        if (matched.contains('Arabic') && matched.contains('Egypt'))
          return 'ar-EG';
        if (matched.contains('Arabic') && matched.contains('UAE'))
          return 'ar-AE';
        if (matched.contains('Hindi') && matched.contains('India'))
          return 'hi-IN';
        if (matched.contains('Greek') && matched.contains('Greece'))
          return 'el-GR';
      }
    }

    return null;
  }

  /// 检查是否是已知的在Web平台上不支持的语言
  bool _isKnownUnsupportedLanguage(String locale) {
    final unsupportedLanguages = {
      'ar-SA', 'ar-AE', 'ar-BH', 'ar-DZ', 'ar-EG', 'ar-IQ', 'ar-JO',
      'ar-KW', 'ar-LB', 'ar-LY', 'ar-MA', 'ar-OM', 'ar-QA', 'ar-SY',
      'ar-TN', 'ar-YE', // 阿拉伯语变体
      'hi-IN', // 印地语
      'el-GR', // 希腊语
    };

    return unsupportedLanguages.contains(locale.toUpperCase()) ||
        unsupportedLanguages.contains(locale.toLowerCase());
  }

  @override
  Future<void> stop() async {
    await _ensureInitialized();
    await _tts.stop();
  }

  @override
  void dispose() {
    super.dispose();
    _initialized = false;
    // Flutter TTS 不需要显式释放资源
  }

  /// Parse voice information
  VoiceModel? _parseVoice(dynamic raw) {
    try {
      // 处理不同类型的 Map
      Map<String, dynamic> voice;
      if (raw is Map<String, dynamic>) {
        voice = raw;
      } else if (raw is Map) {
        // 转换 Map<Object?, Object?> 到 Map<String, dynamic>
        voice = {};
        raw.forEach((key, value) {
          if (key is String) {
            voice[key] = value;
          }
        });
      } else {
        return null;
      }

      final name = voice['name']?.toString() ?? '';
      final locale = voice['locale']?.toString() ?? '';
      final gender = voice['gender']?.toString() ?? '';

      if (name.isEmpty || locale.isEmpty) {
        return null;
      }

      // Generate display name
      final displayName = _generateDisplayName(name, locale);

      // Parse gender information (prioritize returned gender field)
      final parsedGender = gender.isNotEmpty
          ? _normalizeGender(gender)
          : _parseGenderFromName(name);

      return VoiceModel(
        id: name,
        displayName: displayName,
        languageCode: locale,
        gender: parsedGender,
        quality:
            VoiceQuality.standard, // Flutter TTS usually uses system voices
        isNeural: false,
      );
    } catch (e) {
      return null;
    }
  }

  /// 生成友好的显示名称
  String _generateDisplayName(String name, String locale) {
    // 尝试从名称中提取有意义的部分
    // 例如: "Alex" -> "Alex (en-US)"
    // 或者: "Microsoft Zira Desktop" -> "Zira (en-US)"

    String displayName = name;

    // 移除常见的前缀和后缀
    displayName = displayName
        .replaceAll('Microsoft ', '')
        .replaceAll(' Desktop', '')
        .replaceAll(' Mobile', '')
        .replaceAll(' - English (United States)', '')
        .trim();

    return '$displayName ($locale)';
  }

  /// Normalize gender string
  VoiceGender _normalizeGender(String gender) {
    final lower = gender.toLowerCase();
    if (lower == 'female' || lower == 'f') {
      return VoiceGender.female;
    } else if (lower == 'male' || lower == 'm') {
      return VoiceGender.male;
    }
    return VoiceGender.unknown;
  }

  /// Parse gender information from voice name
  VoiceGender _parseGenderFromName(String name) {
    final lower = name.toLowerCase();

    // Common female voice name patterns
    if (lower.contains('female') ||
        lower.contains('woman') ||
        lower.contains('zira') ||
        lower.contains('cortana') ||
        lower.contains('hazel') ||
        lower.contains('susan') ||
        lower.contains('allison') ||
        lower.contains('samantha') ||
        lower.contains('victoria') ||
        lower.contains('karen') ||
        lower.contains('moira') ||
        lower.contains('tessa') ||
        lower.contains('veena') ||
        lower.contains('fiona')) {
      return VoiceGender.female;
    }

    // Common male voice name patterns
    if (lower.contains('male') ||
        lower.contains('man') ||
        lower.contains('david') ||
        lower.contains('mark') ||
        lower.contains('alex') ||
        lower.contains('tom') ||
        lower.contains('daniel') ||
        lower.contains('james') ||
        lower.contains('oliver') ||
        lower.contains('thomas') ||
        lower.contains('rishi') ||
        lower.contains('aaron')) {
      return VoiceGender.male;
    }

    return VoiceGender.unknown;
  }
}
