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
  // Internal parameters controlled by UI (0.0..1.0)
  double _speechRate = 0.5;   // baseline at 1.0x represented by 0.5 midpoint
  double _speechPitch = 0.5;
  double _speechVolume = 1.0;

  @override
  String get engineName => 'edge';

  @override
  Future<List<VoiceModel>> getAvailableVoices() async {
    return getVoicesWithCache(() async {
      // Call edge-tts with environment overrides to avoid proxy issues
      final result = await Process.run(
        'edge-tts',
        ['--list-voices'],
        environment: {
          'NO_PROXY': 'speech.platform.bing.com,.bing.com,*bing.com',
          'HTTP_PROXY': '',
          'HTTPS_PROXY': '',
          'ALL_PROXY': '',
          'http_proxy': '',
          'https_proxy': '',
          'all_proxy': '',
        },
        includeParentEnvironment: true,
      );

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
    return synthesizeTextWithCache(
      text,
      voiceName,
      format,
      () async {
      // 使用资源管理器的 withTempFile 方法自动管理临时文件
      return await ResourceManager.instance.withTempFile(
        (tempFile) async {
          // Call edge-tts with environment overrides to avoid proxy issues
          // Map controller parameters to edge-tts CLI options
          // Controller uses 0.0..1.0. Map rate/pitch to -50%..+50% around 0.5 midpoint; volume to 0%..100%.
          int ratePercent = (((_speechRate) - 0.5) * 100).round();
          // Pitch must be in Hz per edge-tts help (Default +0Hz)
          int pitchHz = (((_speechPitch) - 0.5) * 100).round();
          int volumePercent = ((_speechVolume) * 100).round();

          String fmtSigned(int p) => p >= 0 ? '+${p}%' : '${p}%';
          String fmtUnsigned(int p) => '${p}%';
          String fmtHzSigned(int h) => h >= 0 ? '+${h}Hz' : '${h}Hz';

          // Build args and log for diagnostics
          final args = <String>[
            '--voice',
            voiceName,
            '--text',
            text,
            // Use equals to avoid argparse treating negative values as options
            '--rate=${fmtSigned(ratePercent)}',
            '--pitch=${fmtHzSigned(pitchHz)}',
            '--volume=${fmtSigned(volumePercent)}',
            '--write-media',
            tempFile.path,
          ];
          // Print assembled args to verify actual values passed to edge-tts
          print('[EdgeTTS] Command args: ${args.join(' ')}');

          final result = await Process.run(
            'edge-tts',
            args,
            environment: {
              'NO_PROXY': 'speech.platform.bing.com,.bing.com,*bing.com',
              'HTTP_PROXY': '',
              'HTTPS_PROXY': '',
              'ALL_PROXY': '',
              'http_proxy': '',
              'https_proxy': '',
              'all_proxy': '',
            },
            includeParentEnvironment: true,
          );

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
    },
    cacheKeySuffix:
        '|r=${_speechRate.toStringAsFixed(2)}|p=${_speechPitch.toStringAsFixed(2)}|v=${_speechVolume.toStringAsFixed(2)}',
    );
  }

  @override
  Future<void> stop() async {
    // Edge TTS 通过命令行运行，无法直接停止正在进行的合成
    // 这里只是一个占位符实现
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
  }

  @override
  Future<void> setPitch(double pitch) async {
    _speechPitch = pitch.clamp(0.0, 1.0);
  }

  @override
  Future<void> setVolume(double volume) async {
    _speechVolume = volume.clamp(0.0, 1.0);
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
      final parts = line.split(
        RegExp(r'\s{2,}'),
      ); // Use multiple spaces as separator

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
      final voiceName = parts[2]
          .replaceAll('Neural', '')
          .replaceAll('Standard', '');
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
