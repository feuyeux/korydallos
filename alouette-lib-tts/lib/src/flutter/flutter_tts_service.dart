import 'package:flutter_tts/flutter_tts.dart';

import '../core/tts_service.dart';
import '../core/audio_player.dart';
import '../models/voice.dart';
import '../models/tts_error.dart';
import 'flutter_tts_processor.dart';

/// Flutter TTS 的实现类
/// 重构后使用新的 FlutterTTSProcessor，保持与 EdgeTTSService 相同的接口结构
/// 集成统一错误处理和资源管理
class FlutterTTSService implements TTSService {
  FlutterTTSProcessor? _processor;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentVoice;
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    try {
      // 使用新的 FlutterTTSProcessor 进行初始化
      _processor = FlutterTTSProcessor();
      
      // 通过尝试获取语音列表来验证 Flutter TTS 是否可用
      await _processor!.getVoices();
      
      _initialized = true;
    } catch (e) {
      _processor = null;
      
      if (e is TTSError) {
        throw TTSError(
          'Failed to initialize Flutter TTS: ${e.message}',
          code: TTSErrorCodes.initializationFailed,
          originalError: e,
        );
      }
      
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
    _checkInitialized();

    try {
      // 使用新的 FlutterTTSProcessor 获取语音列表
      return await _processor!.getVoices();
    } catch (e) {
      if (e is TTSError) {
        rethrow;
      }
      
      throw TTSError(
        'Failed to get voices: $e',
        code: TTSErrorCodes.voiceListFailed,
        originalError: e,
      );
    }
  }

  @override
  Future<List<Voice>> getVoicesByLanguage(String languageCode) async {
    final voices = await getVoices();
    return voices.where((v) => v.locale == languageCode).toList();
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
      throw TTSError(
        'No voice selected. Please call setVoice() with a valid voice ID before speaking. '
        'Use getVoices() to see available voices.',
        code: TTSErrorCodes.noVoiceSelected,
      );
    }

    if (text.trim().isEmpty) {
      return;
    }

    try {
      // 对于 Flutter TTS，我们有两种选择：
      // 1. 直接使用 Flutter TTS 的 speak 方法（推荐，因为它更适合实时播放）
      // 2. 使用 FlutterTTSProcessor 生成音频文件然后播放（适合需要音频文件的场景）
      
      // 这里我们使用直接播放的方式，因为它更高效且是 Flutter TTS 的主要用途
      await _speakDirectly(text);
    } catch (e) {
      if (e is TTSError) {
        rethrow;
      }
      
      throw TTSError(
        'Failed to speak text: $e',
        code: TTSErrorCodes.speakFailed,
        originalError: e,
      );
    }
  }

  /// 直接使用 Flutter TTS 播放文本（推荐方式）
  Future<void> _speakDirectly(String text) async {
    try {
      // 创建一个临时的 FlutterTts 实例用于直接播放
      final tts = FlutterTts();
      await tts.awaitSpeakCompletion(true);
      
      // 设置语音
      final voices = await getVoices();
      final targetVoice = voices.firstWhere(
        (voice) => voice.name == _currentVoice,
        orElse: () => throw TTSError(
          'Voice "$_currentVoice" not found. Available voices: ${voices.map((v) => v.name).join(", ")}',
          code: TTSErrorCodes.voiceNotFound,
        ),
      );

      await tts.setVoice({
        "name": targetVoice.name,
        "locale": targetVoice.locale,
      });

      // 播放文本
      await tts.speak(text);
    } catch (e) {
      if (e is TTSError) rethrow;
      
      throw TTSError(
        'Failed to speak text directly: $e',
        code: TTSErrorCodes.speakFailed,
        originalError: e,
      );
    }
  }

  /// 使用音频文件播放的方式（备用方案）
  Future<void> _speakViaAudioFile(String text) async {
    try {
      // 使用 FlutterTTSProcessor 生成音频数据
      final audioData = await _processor!.synthesizeText(text, _currentVoice!);
      
      // 使用 AudioPlayer 播放音频数据
      await _audioPlayer.playBytes(audioData);
    } catch (e) {
      if (e is TTSError) rethrow;
      
      throw TTSError(
        'Failed to speak text via audio file: $e',
        code: TTSErrorCodes.speakFailed,
        originalError: e,
      );
    }
  }

  @override
  Future<void> stop() async {
    try {
      // 停止 AudioPlayer（如果正在使用）
      await _audioPlayer.stop();
      
      // 停止 Flutter TTS（如果正在使用）
      final tts = FlutterTts();
      await tts.stop();
    } catch (e) {
      throw TTSError(
        'Failed to stop playback: $e',
        code: TTSErrorCodes.stopFailed,
        originalError: e,
      );
    }
  }

  @override
  Future<void> dispose() async {
    final errors = <String>[];
    
    // 尝试停止播放，收集错误但继续清理其他资源
    try {
      await stop();
    } catch (e) {
      errors.add('Failed to stop playback: $e');
    }
    
    // 尝试释放音频播放器
    try {
      await _audioPlayer.dispose();
    } catch (e) {
      errors.add('Failed to dispose audio player: $e');
    }
    
    // 尝试释放处理器
    try {
      _processor?.dispose();
    } catch (e) {
      errors.add('Failed to dispose processor: $e');
    }
    
    // 清理状态
    _processor = null;
    _initialized = false;
    _currentVoice = null;
    
    // 如果有错误发生，抛出包含所有错误信息的异常
    if (errors.isNotEmpty) {
      throw TTSError(
        'Flutter TTS service disposal completed with errors: ${errors.join('; ')}. '
        'Some resources may not have been properly cleaned up.',
        code: TTSErrorCodes.disposePartialFailure,
        originalError: errors,
      );
    }
  }

  void _checkInitialized() {
    if (!_initialized || _processor == null) {
      throw TTSError(
        'Flutter TTS service not initialized. Please call initialize() before using the service.',
        code: TTSErrorCodes.notInitialized,
      );
    }
  }
}
