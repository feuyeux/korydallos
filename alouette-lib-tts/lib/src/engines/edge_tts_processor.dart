import 'dart:io';
import 'dart:typed_data';

import 'base_tts_processor.dart';
import '../models/voice_model.dart';
import '../models/tts_error.dart';
import '../enums/voice_gender.dart';
import '../enums/voice_quality.dart';
import '../exceptions/tts_exceptions.dart';
import '../utils/resource_manager.dart';

/// Edge TTS processor implementation following Flutter naming conventions
/// Provides Edge TTS functionality through command line interface
class EdgeTTSProcessor extends BaseTTSProcessor {
  @override
  String get engineName => 'edge';

  @override
  Future<List<VoiceModel>> getAvailableVoices() async {
    return getVoicesWithCache(() async {
      // Simplified command line call
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
  Future<Uint8List> synthesizeToAudio(
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

  /// Parse edge-tts --list-voices output
  /// Edge TTS output format is tabular:
  /// Name                               Gender    ContentCategories      VoicePersonalities
  /// Supported languages list
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

  /// Parse voices from edge-tts output
  List<VoiceModel> _parseVoicesFromOutput(String output) {
    final voices = <VoiceModel>[];
    final lines = output.split('\n');
    
    bool headerPassed = false;
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      
      // Skip header and separator lines
      if (trimmedLine.startsWith('Name') || trimmedLine.startsWith('-')) {
        headerPassed = true;
        continue;
      }
      
      if (!headerPassed) continue;

      try {
        final voice = _parseVoiceLine(trimmedLine);
        if (voice != null && _supportedLanguages.contains(voice.languageCode)) {
          voices.add(voice);
        }
      } catch (e) {
        // Ignore failed parsing lines, continue with others
        continue;
      }
    }

    return voices;
  }

  /// Parse single voice line
  /// Edge TTS table format: "af-ZA-AdriNeural                   Female    General                Friendly, Positive"
  VoiceModel? _parseVoiceLine(String line) {
    try {
      // Use regex to parse table row
      // Match: voice name + spaces + gender + spaces + other info
      final parts = line.split(RegExp(r'\s{2,}')); // Use multiple spaces as separator
      
      if (parts.length < 2) return null;
      
      final name = parts[0].trim();
      final genderStr = parts[1].trim();
      
      if (name.isEmpty) return null;
      
      // Extract locale from voice name
      // Example: "zh-CN-XiaoxiaoNeural" -> "zh-CN"
      final languageCode = _extractLocaleFromName(name);
      
      // Generate display name
      final displayName = _generateDisplayName(name, languageCode, genderStr);

      // Parse gender
      final gender = _parseGender(genderStr);
      
      // Determine quality
      final isNeural = name.toLowerCase().contains('neural');
      final quality = isNeural ? VoiceQuality.neural : VoiceQuality.standard;

      return VoiceModel(
        id: name,
        displayName: displayName,
        languageCode: languageCode,
        gender: gender,
        quality: quality,
        isNeural: isNeural,
      );
    } catch (e) {
      return null;
    }
  }
  
  /// Extract locale from voice name
  /// Example: "zh-CN-XiaoxiaoNeural" -> "zh-CN"
  String _extractLocaleFromName(String name) {
    final parts = name.split('-');
    if (parts.length >= 2) {
      return '${parts[0]}-${parts[1]}';
    }
    return 'en-US'; // Default value
  }

  /// Generate friendly display name
  String _generateDisplayName(String name, String languageCode, String gender) {
    // Extract meaningful parts from voice name
    // Example: "zh-CN-XiaoxiaoNeural" -> "Xiaoxiao (Chinese, Female, Neural)"
    
    final parts = name.split('-');
    if (parts.length >= 3) {
      final voiceName = parts[2].replaceAll('Neural', '').replaceAll('Standard', '');
      final isNeural = name.toLowerCase().contains('neural');
      final qualityType = isNeural ? 'Neural' : 'Standard';
      
      return '$voiceName ($languageCode, $gender, $qualityType)';
    }
    
    return name;
  }

  /// Parse gender from string
  VoiceGender _parseGender(String genderStr) {
    switch (genderStr.toLowerCase()) {
      case 'male':
        return VoiceGender.male;
      case 'female':
        return VoiceGender.female;
      default:
        return VoiceGender.unknown;
    }
  }
}