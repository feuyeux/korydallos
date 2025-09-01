import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../core/tts_processor.dart';
import '../models/voice.dart';
import '../models/tts_error.dart';
import '../utils/file_utils.dart';

/// Edge TTS 处理器实现
/// 参照 hello-tts-dart 的 TTSProcessor 设计模式
/// 简化命令行调用逻辑，移除复杂的环境变量处理
class EdgeTTSProcessor implements TTSProcessor {
  List<Voice>? _cachedVoices;
  
  @override
  String get backend => 'edge';

  @override
  Future<List<Voice>> getVoices() async {
    if (_cachedVoices != null) {
      return _cachedVoices!;
    }

    try {
      // 简化的命令行调用，不依赖复杂的环境变量处理
      final result = await Process.run('edge-tts', ['--list-voices']);
      
      if (result.exitCode != 0) {
        final errorMessage = result.stderr.toString().trim();
        throw TTSError(
          'Failed to get voices from edge-tts: $errorMessage. '
          'Please ensure edge-tts is properly installed and accessible. '
          'Try running "pip install edge-tts" to install or update it.',
          code: TTSErrorCodes.voiceListFailed,
          originalError: result.stderr,
        );
      }

      final voices = _parseVoicesFromOutput(result.stdout.toString());
      _cachedVoices = voices;
      return voices;
    } catch (e) {
      if (e is TTSError) rethrow;
      
      throw TTSError(
        'Error loading Edge TTS voices: $e. '
        'This usually indicates that edge-tts is not installed or not accessible. '
        'Please install edge-tts using "pip install edge-tts" and ensure it\'s in your PATH.',
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

    File? tempFile;
    try {
      // 创建临时文件
      tempFile = await FileUtils.createTempFile(
        prefix: 'edge_tts_',
        suffix: '.$format',
      );

      // 简化的命令行调用
      final result = await Process.run('edge-tts', [
        '--voice',
        voiceName,
        '--text',
        text,
        '--write-media',
        tempFile.path,
      ]);

      if (result.exitCode != 0) {
        final errorMessage = result.stderr.toString().trim();
        throw TTSError(
          'Edge TTS synthesis failed: $errorMessage. '
          'Please check that the voice name "$voiceName" is valid and supported. '
          'Use getVoices() to see available voices.',
          code: TTSErrorCodes.synthesisFailed,
          originalError: result.stderr,
        );
      }

      // 检查输出文件是否存在
      if (!await tempFile.exists()) {
        throw TTSError(
          'Output file was not created by edge-tts. '
          'This may indicate insufficient disk space or permission issues. '
          'Please check your temporary directory permissions and available disk space.',
          code: TTSErrorCodes.outputFileNotCreated,
        );
      }

      // 读取音频数据
      final audioData = await tempFile.readAsBytes();
      return Uint8List.fromList(audioData);
    } catch (e) {
      if (e is TTSError) rethrow;
      
      throw TTSError(
        'Failed to synthesize text via Edge TTS: $e. '
        'This may be due to network issues, invalid parameters, or system configuration problems.',
        code: TTSErrorCodes.synthesisError,
        originalError: e,
      );
    } finally {
      // 确保临时文件被清理，即使在错误情况下也要执行
      if (tempFile != null) {
        try {
          await FileUtils.cleanupTempFile(tempFile);
        } catch (cleanupError) {
          // 记录清理错误但不抛出，避免掩盖原始错误
        }
      }
    }
  }

  @override
  Future<void> stop() async {
    // Edge TTS 通过命令行运行，无法直接停止正在进行的合成
    // 这里只是一个占位符实现
  }

  @override
  void dispose() {
    _cachedVoices = null;
  }

  /// 解析 edge-tts --list-voices 的输出
  /// Edge TTS 输出格式为表格形式:
  /// Name                               Gender    ContentCategories      VoicePersonalities
  /// 支持的语言列表（基于 hello-tts README 中的描述）
  static const Set<String> _supportedLanguages = {
    'zh-CN', // 🇨🇳 Chinese
    'en-US', // 🇺🇸 English
    'de-DE', // 🇩🇪 German
    'fr-FR', // 🇫🇷 French
    'es-ES', // 🇪🇸 Spanish
    'it-IT', // 🇮🇹 Italian
    'ru-RU', // 🇷🇺 Russian
    'el-GR', // 🇬🇷 Greek
    'ar-SA', // 🇸🇦 Arabic
    'hi-IN', // 🇮🇳 Hindi
    'ja-JP', // 🇯🇵 Japanese
    'ko-KR', // 🇰🇷 Korean
  };

  /// ---------------------------------  --------  ---------------------  --------------------------------------
  /// af-ZA-AdriNeural                   Female    General                Friendly, Positive
  List<Voice> _parseVoicesFromOutput(String output) {
    final voices = <Voice>[];
    final lines = output.split('\n');
    
    bool headerPassed = false;
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      
      // 跳过表头和分隔线
      if (trimmedLine.startsWith('Name') || trimmedLine.startsWith('-')) {
        headerPassed = true;
        continue;
      }
      
      if (!headerPassed) continue;

      try {
        final voice = _parseVoiceLine(trimmedLine);
        if (voice != null && _supportedLanguages.contains(voice.locale)) {
          voices.add(voice);
        }
      } catch (e) {
        // 忽略解析失败的行，继续处理其他行
        continue;
      }
    }

    return voices;
  }

  /// 解析单行语音信息
  /// Edge TTS 表格格式: "af-ZA-AdriNeural                   Female    General                Friendly, Positive"
  Voice? _parseVoiceLine(String line) {
    try {
      // 使用正则表达式解析表格行
      // 匹配: 语音名称 + 空格 + 性别 + 空格 + 其他信息
      final parts = line.split(RegExp(r'\s{2,}')); // 使用多个空格作为分隔符
      
      if (parts.length < 2) return null;
      
      final name = parts[0].trim();
      final gender = parts[1].trim();
      
      if (name.isEmpty) return null;
      
      // 从语音名称中提取 locale
      // 例如: "zh-CN-XiaoxiaoNeural" -> "zh-CN"
      final locale = _extractLocaleFromName(name);
      final language = locale.split('-')[0];
      
      // 生成显示名称
      final displayName = _generateDisplayName(name, locale, gender);

      return Voice(
        name: name,
        displayName: displayName,
        language: language,
        gender: gender,
        locale: locale,
        isNeural: name.toLowerCase().contains('neural'),
        isStandard: !name.toLowerCase().contains('neural'),
      );
    } catch (e) {
      return null;
    }
  }
  
  /// 从语音名称中提取 locale
  /// 例如: "zh-CN-XiaoxiaoNeural" -> "zh-CN"
  String _extractLocaleFromName(String name) {
    final parts = name.split('-');
    if (parts.length >= 2) {
      return '${parts[0]}-${parts[1]}';
    }
    return 'en-US'; // 默认值
  }

  /// 生成友好的显示名称
  String _generateDisplayName(String name, String locale, String gender) {
    // 从语音名称中提取有意义的部分
    // 例如: "zh-CN-XiaoxiaoNeural" -> "Xiaoxiao (Chinese, Female, Neural)"
    
    final parts = name.split('-');
    if (parts.length >= 3) {
      final voiceName = parts[2].replaceAll('Neural', '').replaceAll('Standard', '');
      final isNeural = name.toLowerCase().contains('neural');
      final qualityType = isNeural ? 'Neural' : 'Standard';
      
      return '$voiceName ($locale, $gender, $qualityType)';
    }
    
    return name;
  }
}