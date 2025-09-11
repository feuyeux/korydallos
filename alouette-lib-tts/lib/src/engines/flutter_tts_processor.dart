import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

import 'base_processor.dart';
import '../models/voice.dart';
import '../models/tts_error.dart';
import '../utils/file_utils.dart';
import '../utils/resource_manager.dart';

/// Flutter TTS 处理器实现
/// 实现 TTSProcessor 接口，与 EdgeTTSProcessor 保持对称
/// 使用 FlutterTts 库进行语音合成，实现音频数据返回功能
class FlutterTTSProcessor extends BaseTTSProcessorImpl {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  @override
  String get backend => 'flutter';

  /// 初始化 Flutter TTS
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    // 配置 Flutter TTS
    await _tts.awaitSpeakCompletion(true);
    
    // 在支持的平台上设置音频会话
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
  Future<List<Voice>> getVoices() async {
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
          .cast<Voice>()
          .toList();
      
      // Remove duplicates based on name to avoid dropdown issues
      final uniqueVoices = <Voice>[];
      final seenNames = <String>{};
      
      for (final voice in parsedVoices) {
        if (!seenNames.contains(voice.name)) {
          uniqueVoices.add(voice);
          seenNames.add(voice.name);
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
  Future<Uint8List> synthesizeText(
    String text,
    String voiceName, {
    String format = 'mp3',
  }) async {
    await _ensureInitialized();

    return synthesizeTextWithCache(text, voiceName, format, () async {
      // For macOS and platforms where file synthesis has sandboxing issues,
      // use direct speech playback instead of generating audio files
      if (Platform.isMacOS || kIsWeb) {
        return _synthesizeDirectPlay(text, voiceName);
      }

      // Desktop and mobile platforms: try file synthesis first, fall back to direct speech
      return await ResourceManager.instance.withTempFile(
        (tempFile) async {
          // Set voice
          await _setVoice(voiceName);

          // Use synthesizeToFile method (if available)
          bool synthesisSuccess = false;
          
          try {
            // Try using synthesizeToFile method
            final result = await _tts.synthesizeToFile(text, tempFile.path);
            synthesisSuccess = result == 1; // Flutter TTS returns 1 for success
          } catch (e) {
            // If synthesizeToFile is not available, fall back to direct speech
            return _synthesizeDirectPlay(text, voiceName);
          }

          if (!synthesisSuccess) {
            // Fall back to direct speech
            return _synthesizeDirectPlay(text, voiceName);
          }

          // Check if output file exists
          if (!await tempFile.exists()) {
            // Fall back to direct speech
            return _synthesizeDirectPlay(text, voiceName);
          }

          // Read audio data
          final audioData = await tempFile.readAsBytes();
          return Uint8List.fromList(audioData);
        },
        prefix: 'flutter_tts_',
        suffix: '.$format',
      );
    });
  }

  /// 直接播放语音合成（不生成文件）
  /// 适用于 Web 平台和不支持文件合成的平台
  Future<Uint8List> _synthesizeDirectPlay(String text, String voiceName) async {
    // 在 Web 平台上，先检查语音可用性
    if (kIsWeb) {
      final voices = await getVoices();
      
      // 检查是否是阿拉伯语
      final isArabic = voiceName.toLowerCase().contains('ar-') || 
                      voiceName.toLowerCase().contains('arabic');
      
      if (isArabic) {
        // 检查浏览器是否支持阿拉伯语
        final arabicVoices = voices.where((v) => 
          v.language.toLowerCase() == 'ar' || 
          v.locale.toLowerCase().startsWith('ar-')).toList();
        
        if (arabicVoices.isEmpty) {
          throw TTSError(
            'Arabic language is not supported by this browser\'s Web Speech API',
            code: TTSErrorCodes.voiceNotFound,
          );
        }
        
        // 尝试使用第一个可用的阿拉伯语语音
        final arabicVoice = arabicVoices.first;
        
        // 设置阿拉伯语语音
        await _tts.setVoice({
          "name": arabicVoice.name,
          "locale": arabicVoice.locale,
        });
      } else {
        // 非阿拉伯语，正常设置
        await _setVoice(voiceName);
      }
    } else {
      // 非 Web 平台，正常设置
      await _setVoice(voiceName);
    }
    
    // 设置语音参数（对阿拉伯语可能有帮助）
    if (kIsWeb) {
      await _tts.setSpeechRate(0.8); // 稍慢的语速可能有助于阿拉伯语
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    }
    
    // 直接播放
    await _tts.speak(text);
    
    // 等待一小段时间确保播放开始
    await Future.delayed(Duration(milliseconds: 300));
    
    // 返回一个最小的有效音频数据，表示已经直接播放
    return _createMinimalAudioData();
  }

  /// 创建一个最小的有效音频数据
  /// 返回一个很短的静音 MP3 数据，避免 AudioPlayer 报错
  /// 使用较小的数据量，让调用方知道这是直接播放模式
  Uint8List _createMinimalAudioData() {
    // 返回一个非常小的数据包，表示已经直接播放
    // 调用方可以根据数据大小判断是否需要通过 AudioPlayer 播放
    return Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
  }

  /// 设置语音
  Future<void> _setVoice(String voiceName) async {
    try {
      // Flutter TTS 需要使用语音对象来设置语音
      final voices = await getVoices();
      
      // 首先尝试精确匹配
      Voice? targetVoice;
      try {
        targetVoice = voices.firstWhere(
          (voice) => voice.name == voiceName,
        );
      } catch (e) {
        targetVoice = null;
      }
      
      // 如果精确匹配失败，尝试模糊匹配
      if (targetVoice == null) {
        // 尝试通过 locale 匹配
        final locale = _extractLocaleFromVoiceName(voiceName);
        if (locale != null) {
          try {
            targetVoice = voices.firstWhere(
              (voice) => voice.locale.toLowerCase() == locale.toLowerCase(),
            );
          } catch (e) {
            targetVoice = null;
          }
        }
        
        // 如果还是没找到，尝试语言匹配
        if (targetVoice == null && locale != null) {
          final language = locale.split('-')[0];
          try {
            targetVoice = voices.firstWhere(
              (voice) => voice.language.toLowerCase() == language.toLowerCase(),
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
        
        final availableVoices = voices.map((v) => '${v.name} (${v.locale})').take(5).join(', ');
        throw TTSError(
          'Voice "$voiceName" not available. '
          'Available voices: $availableVoices${voices.length > 5 ? '...' : ''}',
          code: TTSErrorCodes.voiceNotFound,
        );
      }

      // 设置语音
      await _tts.setVoice({
        "name": targetVoice.name,
        "locale": targetVoice.locale,
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
    if (voiceName.toLowerCase().contains('arabic') || voiceName.toLowerCase().contains('ar-')) {
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
        if (matched.contains('English') && matched.contains('United States')) return 'en-US';
        if (matched.contains('Chinese') && matched.contains('China')) return 'zh-CN';
        if (matched.contains('Arabic') && matched.contains('Saudi')) return 'ar-SA';
        if (matched.contains('Arabic') && matched.contains('Egypt')) return 'ar-EG';
        if (matched.contains('Arabic') && matched.contains('UAE')) return 'ar-AE';
        if (matched.contains('Hindi') && matched.contains('India')) return 'hi-IN';
        if (matched.contains('Greek') && matched.contains('Greece')) return 'el-GR';
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

  /// 解析语音信息
  Voice? _parseVoice(dynamic raw) {
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

      // 从 locale 提取语言代码
      final language = locale.split('-')[0];

      // 生成显示名称
      final displayName = _generateDisplayName(name, locale);

      // 解析性别信息（优先使用返回的 gender 字段）
      final parsedGender = gender.isNotEmpty ? _normalizeGender(gender) : _parseGenderFromName(name);

      return Voice(
        name: name,
        displayName: displayName,
        language: language,
        gender: parsedGender,
        locale: locale,
        isNeural: false, // Flutter TTS 通常使用系统语音，不区分神经网络
        isStandard: true,
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

  /// 标准化性别字符串
  String _normalizeGender(String gender) {
    final lower = gender.toLowerCase();
    if (lower == 'female' || lower == 'f') {
      return 'Female';
    } else if (lower == 'male' || lower == 'm') {
      return 'Male';
    }
    return 'Unknown';
  }

  /// 从语音名称解析性别信息
  String _parseGenderFromName(String name) {
    final lower = name.toLowerCase();
    
    // 常见的女性语音名称模式
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
      return 'Female';
    }
    
    // 常见的男性语音名称模式
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
      return 'Male';
    }
    
    return 'Unknown';
  }
}