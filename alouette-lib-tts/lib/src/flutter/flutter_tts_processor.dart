import 'dart:typed_data';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

import '../core/tts_processor.dart';
import '../models/voice.dart';
import '../models/tts_error.dart';
import '../utils/file_utils.dart';

/// Flutter TTS 处理器实现
/// 实现 TTSProcessor 接口，与 EdgeTTSProcessor 保持对称
/// 使用 FlutterTts 库进行语音合成，实现音频数据返回功能
class FlutterTTSProcessor implements TTSProcessor {
  final FlutterTts _tts = FlutterTts();
  List<Voice>? _cachedVoices;
  bool _initialized = false;

  @override
  String get backend => 'flutter';

  /// 初始化 Flutter TTS
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    try {
      // 配置 Flutter TTS
      await _tts.awaitSpeakCompletion(true);
      
      // 在支持的平台上设置音频会话
      try {
        if (!kIsWeb) {
          await _tts.setSharedInstance(true);
        }
      } catch (e) {
        // 某些平台可能不支持 setSharedInstance，忽略此错误
      }
      
      _initialized = true;
    } catch (e) {
      throw TTSError(
        'Failed to initialize Flutter TTS: $e. '
        'Please ensure the Flutter TTS plugin is properly configured for your platform.',
        code: TTSErrorCodes.initializationFailed,
        originalError: e,
      );
    }
  }

  @override
  Future<List<Voice>> getVoices() async {
    if (_cachedVoices != null) {
      return _cachedVoices!;
    }

    await _ensureInitialized();

    try {
      final voices = await _tts.getVoices as List<dynamic>?;
      
      if (voices == null || voices.isEmpty) {
        throw TTSError(
          'No voices available from Flutter TTS. '
          'This may indicate that the system TTS is not properly configured or no voices are installed.',
          code: TTSErrorCodes.voiceListFailed,
        );
      }

      final parsedVoices = voices
          .map((v) => _parseVoice(v))
          .where((voice) => voice != null)
          .cast<Voice>()
          .toList();



      if (parsedVoices.isEmpty) {
        throw TTSError(
          'Failed to parse any voices from Flutter TTS. '
          'The voice data format may be incompatible or corrupted. '
          'Raw voice data: $voices',
          code: TTSErrorCodes.voiceParseError,
        );
      }

      _cachedVoices = parsedVoices;
      return parsedVoices;
    } catch (e) {
      if (e is TTSError) rethrow;
      
      throw TTSError(
        'Error loading Flutter TTS voices: $e. '
        'This usually indicates a problem with the system TTS configuration.',
        code: TTSErrorCodes.voiceListError,
        originalError: e,
      );
    }
  }

  @override
  Future<Uint8List> synthesizeText(
    String text,
    String voiceName, {
    String format = 'mp3',
  }) async {
    if (text.trim().isEmpty) {
      throw TTSError(
        'Text cannot be empty. Please provide valid text content for synthesis.',
        code: TTSErrorCodes.emptyText,
      );
    }

    if (voiceName.trim().isEmpty) {
      throw TTSError(
        'Voice name cannot be empty. Please specify a valid voice name. '
        'Use getVoices() to see available voices.',
        code: TTSErrorCodes.emptyVoiceName,
      );
    }

    await _ensureInitialized();

    // Web 平台和不支持文件合成的平台：直接播放
    if (kIsWeb || Platform.isWindows) {
      return _synthesizeDirectPlay(text, voiceName);
    }

    // 桌面和移动平台处理
    File? tempFile;
    try {
      // 设置语音
      await _setVoice(voiceName);

      // 创建临时文件
      tempFile = await FileUtils.createTempFile(
        prefix: 'flutter_tts_',
        suffix: '.$format',
      );

      // 使用 synthesizeToFile 方法（如果可用）
      bool synthesisSuccess = false;
      
      try {
        // 尝试使用 synthesizeToFile 方法
        final result = await _tts.synthesizeToFile(text, tempFile.path);
        synthesisSuccess = result == 1; // Flutter TTS 返回 1 表示成功
      } catch (e) {
        // 如果 synthesizeToFile 不可用，回退到直接播放
        return _synthesizeDirectPlay(text, voiceName);
      }

      if (!synthesisSuccess) {
        // 回退到直接播放
        return _synthesizeDirectPlay(text, voiceName);
      }

      // 检查输出文件是否存在
      if (!await tempFile.exists()) {
        // 回退到直接播放
        return _synthesizeDirectPlay(text, voiceName);
      }

      // 读取音频数据
      final audioData = await tempFile.readAsBytes();
      return Uint8List.fromList(audioData);
    } catch (e) {
      if (e is TTSError) rethrow;
      
      // 最后的回退：直接播放
      return _synthesizeDirectPlay(text, voiceName);
    } finally {
      // 确保临时文件被清理
      if (tempFile != null) {
        try {
          await FileUtils.cleanupTempFile(tempFile);
        } catch (cleanupError) {
          // 记录清理错误但不抛出，避免掩盖原始错误
        }
      }
    }
  }

  /// 直接播放语音合成（不生成文件）
  /// 适用于 Web 平台和不支持文件合成的平台
  Future<Uint8List> _synthesizeDirectPlay(String text, String voiceName) async {
    try {
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
              'Arabic language is not supported by this browser\'s Web Speech API. '
              'Arabic TTS support varies by browser and operating system. '
              'Try using Chrome on Windows/Android or Safari on macOS/iOS for better Arabic support.',
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
    } catch (e) {
      
      // 特殊处理阿拉伯语错误
      if (voiceName.toLowerCase().contains('ar-') || 
          voiceName.toLowerCase().contains('arabic')) {
        throw TTSError(
          'Arabic text-to-speech failed. This browser may not support Arabic TTS. '
          'Arabic support varies by browser: Chrome (Windows/Android), Safari (macOS/iOS), '
          'and Edge (Windows) typically have better Arabic support. '
          'Error details: $e',
          code: TTSErrorCodes.voiceNotFound,
          originalError: e,
        );
      }
      
      // 如果是语音不可用的错误，提供更友好的错误信息
      if (e.toString().contains('not found') || e.toString().contains('not available')) {
        throw TTSError(
          'Voice "$voiceName" is not supported on this platform/browser. '
          'This commonly happens with Arabic, Hindi, or Greek voices on some browsers. '
          'Try using a different browser or the desktop version.',
          code: TTSErrorCodes.voiceNotFound,
          originalError: e,
        );
      }
      
      throw TTSError(
        'Failed to play text via Flutter TTS: $e. '
        'This may be due to platform limitations, unsupported language, or system configuration problems.',
        code: TTSErrorCodes.synthesisError,
        originalError: e,
      );
    }
  }

  /// 创建一个最小的有效音频数据
  /// 返回一个很短的静音 MP3 数据，避免 AudioPlayer 报错
  Uint8List _createMinimalAudioData() {
    // 最小的有效 MP3 文件头（静音）
    return Uint8List.fromList([
      0xFF, 0xFB, 0x90, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    ]);
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
    try {
      await _ensureInitialized();
      await _tts.stop();
    } catch (e) {
      // 不抛出错误，因为停止功能不是关键功能
    }
  }

  @override
  void dispose() {
    _cachedVoices = null;
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