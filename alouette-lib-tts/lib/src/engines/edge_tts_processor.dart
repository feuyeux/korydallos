import 'dart:io';
import 'dart:typed_data';

import 'base_processor.dart';
import '../models/voice.dart';
import '../models/tts_error.dart';
import '../utils/file_utils.dart';
import '../utils/resource_manager.dart';

/// Edge TTS 处理器实现
/// 参照 hello-tts-dart 的 TTSProcessor 设计模式
/// 简化命令行调用逻辑，移除复杂的环境变量处理
class EdgeTTSProcessor extends BaseTTSProcessorImpl {
  @override
  String get backend => 'edge';

  @override
  Future<List<Voice>> getVoices() async {
    return getVoicesWithCache(() async {
      // 简化的命令行调用，不依赖复杂的环境变量处理
      final result = await Process.run('edge-tts', ['--list-voices']);
      
      if (result.exitCode != 0) {
        final errorMessage = result.stderr.toString().trim();
        throw TTSError(
          'Failed to get voices from edge-tts: $errorMessage',
          code: TTSErrorCodes.voiceListFailed,
          originalError: result.stderr,
        );
      }

      return _parseVoicesFromOutput(result.stdout.toString());
    });
  }

  @override
  Future<Uint8List> synthesizeText(
    String text,
    String voiceName, {
    String format = 'mp3',
  }) async {
    return synthesizeTextWithCache(text, voiceName, format, () async {
      // 使用资源管理器的 withTempFile 方法自动管理临时文件
      return await ResourceManager.instance.withTempFile(
        (tempFile) async {
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
              'Edge TTS synthesis failed: $errorMessage',
              code: TTSErrorCodes.synthesisFailed,
              originalError: result.stderr,
            );
          }

          // 检查输出文件是否存在
          if (!await tempFile.exists()) {
            throw TTSError(
              'Output file was not created by edge-tts',
              code: TTSErrorCodes.outputFileNotCreated,
            );
          }

          // 读取音频数据
          final audioData = await tempFile.readAsBytes();
          return Uint8List.fromList(audioData);
        },
        prefix: 'edge_tts_',
        suffix: '.$format',
      );
    });
  }

  @override
  Future<void> stop() async {
    // Edge TTS 通过命令行运行，无法直接停止正在进行的合成
    // 这里只是一个占位符实现
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    // Edge TTS 通过命令行参数控制语速，在synthesizeText时使用
    // 这里不需要存储状态，因为每次合成时都会传入新的参数
  }

  @override
  Future<void> setPitch(double pitch) async {
    // Edge TTS 通过命令行参数控制音调，在synthesizeText时使用
    // 这里不需要存储状态，因为每次合成时都会传入新的参数
  }

  @override
  Future<void> setVolume(double volume) async {
    // Edge TTS 通过命令行参数控制音量，在synthesizeText时使用
    // 这里不需要存储状态，因为每次合成时都会传入新的参数
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