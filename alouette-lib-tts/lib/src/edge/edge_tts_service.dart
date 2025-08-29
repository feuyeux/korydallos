import 'dart:io';
import '../core/tts_service.dart';
import '../models/voice.dart';
import '../enums/voice_gender.dart';
import '../enums/voice_quality.dart';

import 'edge_tts_player.dart';

/// Edge TTS 的实现类
class EdgeTTSService implements TTSService {
  final EdgeTTSPlayer _player = EdgeTTSPlayer();
  String? _currentVoice;
  bool _initialized = false;
  String _command = 'edge-tts';
  String _workDir = '';

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    try {
      // Use full path from environment
      final homeDir = Platform.environment['HOME'];
      if (homeDir == null) {
        throw EdgeTTSException('HOME environment variable not set');
      }

      final edgeTTSPath = '$homeDir/miniconda3/bin/edge-tts';
      final workDir = '$homeDir/miniconda3/bin';

      if (!await File(edgeTTSPath).exists()) {
        throw EdgeTTSException('edge-tts not found at $edgeTTSPath');
      }

      final result = await Process.run(
        edgeTTSPath,
        ['--list-voices'],
        workingDirectory: workDir,
        environment: {
          'PATH': '$workDir:${Platform.environment['PATH'] ?? ''}',
          'HOME': homeDir,
          'PYTHONPATH': Platform.environment['PYTHONPATH'] ?? '',
        },
      );

      if (result.exitCode != 0) {
        throw EdgeTTSException(
            'edge-tts initialization failed: ${result.stderr}');
      }

      // Store the working command path and directory for future use
      _command = edgeTTSPath;
      _workDir = workDir;
      _initialized = true;
    } catch (e) {
      throw EdgeTTSException('Failed to initialize edge-tts: $e');
    }
  }

  @override
  Future<List<Voice>> getVoices() async {
    _checkInitialized();

    try {
      final result = await Process.run(
        _command,
        ['--list-voices'],
        workingDirectory: _workDir,
        environment: {
          'PATH': '$_workDir:${Platform.environment['PATH'] ?? ''}',
          'HOME': Platform.environment['HOME'] ?? '',
          'PYTHONPATH': Platform.environment['PYTHONPATH'] ?? '',
        },
      );
      if (result.exitCode != 0) {
        throw EdgeTTSException('Failed to get voices: ${result.stderr}');
      }

      final lines = result.stdout.toString().split('\n');
      final voices = <Voice>[];

      for (var line in lines) {
        if (line.trim().isEmpty) continue;

        final voice = _parseVoiceLine(line);
        if (voice != null) {
          voices.add(voice);
        }
      }

      return voices;
    } catch (e) {
      throw EdgeTTSException('Failed to get voices: $e');
    }
  }

  @override
  Future<List<Voice>> getVoicesByLanguage(String languageCode) async {
    final voices = await getVoices();
    return voices.where((v) => v.languageCode == languageCode).toList();
  }

  @override
  Future<void> setVoice(String voiceId) async {
    _checkInitialized();
    _currentVoice = voiceId;
  }

  @override
  Future<void> speak(String text) async {
    _checkInitialized();

    if (_currentVoice == null) {
      throw EdgeTTSException('No voice selected');
    }

    if (text.isEmpty) {
      return;
    }

    final tempFile = await _synthesize(text, _currentVoice!);
    try {
      await _player.play(tempFile.path);
    } finally {
      await tempFile.delete();
    }
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() async {
    await stop();
    await _player.dispose();
    _initialized = false;
  }

  void _checkInitialized() {
    if (!_initialized) {
      throw EdgeTTSException('EdgeTTS not initialized');
    }
  }

  Voice? _parseVoiceLine(String line) {
    final parts = line.split('\t');
    if (parts.length < 2) return null;

    final nameParts = parts[0].split(' ');
    if (nameParts.length < 2) return null;

    final locale = nameParts[0];
    final name = nameParts.sublist(1).join(' ');

    return Voice(
      id: parts[0],
      name: name,
      languageCode: locale,
      gender: _parseGender(name),
      quality: VoiceQuality.neural,
      metadata: {
        'edgeTTSName': parts[0],
      },
    );
  }

  VoiceGender _parseGender(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('female') || lower.contains('woman')) {
      return VoiceGender.female;
    } else if (lower.contains('male') || lower.contains('man')) {
      return VoiceGender.male;
    }
    return VoiceGender.neutral;
  }

  Future<File> _synthesize(String text, String voice) async {
    final temp = await Directory.systemTemp.createTemp('edge_tts_');
    final output = File('${temp.path}/output.mp3');

    final result = await Process.run(
      _command,
      [
        '--voice',
        voice,
        '--text',
        text,
        '--write-media',
        output.path,
      ],
      workingDirectory: _workDir,
      environment: {
        'PATH': '$_workDir:${Platform.environment['PATH'] ?? ''}',
        'HOME': Platform.environment['HOME'] ?? '',
        'PYTHONPATH': Platform.environment['PYTHONPATH'] ?? '',
      },
    );

    if (result.exitCode != 0) {
      throw EdgeTTSException('Synthesis failed: ${result.stderr}');
    }

    return output;
  }
}

/// Edge TTS 相关异常
class EdgeTTSException implements Exception {
  final String message;
  EdgeTTSException(this.message);

  @override
  String toString() => 'EdgeTTSException: $message';
}
