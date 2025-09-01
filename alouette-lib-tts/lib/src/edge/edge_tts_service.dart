import '../core/tts_service.dart';
import '../core/audio_player.dart';
import '../models/voice.dart';
import '../models/tts_error.dart';
import 'edge_tts_processor.dart';

/// Edge TTS 的实现类
/// 重构后使用新的 EdgeTTSProcessor 和 AudioPlayer
class EdgeTTSService implements TTSService {
  EdgeTTSProcessor? _processor;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentVoice;
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    try {
      // 简化初始化逻辑，使用统一的命令行检查
      _processor = EdgeTTSProcessor();
      
      // 通过尝试获取语音列表来验证 edge-tts 是否可用
      await _processor!.getVoices();
      
      _initialized = true;
    } catch (e) {
      _processor = null;
      
      if (e is TTSError) {
        throw TTSError(
          'Failed to initialize Edge TTS: ${e.message}',
          code: TTSErrorCodes.initializationFailed,
          originalError: e,
        );
      }
      
      throw TTSError(
        'Failed to initialize Edge TTS: $e. '
        'Please ensure edge-tts is installed and accessible. '
        'Install it using "pip install edge-tts" and verify it works by running "edge-tts --list-voices".',
        code: TTSErrorCodes.initializationFailed,
        originalError: e,
      );
    }
  }

  @override
  Future<List<Voice>> getVoices() async {
    _checkInitialized();

    try {
      // 使用新的 EdgeTTSProcessor 获取语音列表
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
      // 使用新的 EdgeTTSProcessor 进行语音合成
      final audioData = await _processor!.synthesizeText(text, _currentVoice!);
      
      // 使用 AudioPlayer 播放音频数据
      await _audioPlayer.playBytes(audioData);
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

  @override
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
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
        'Edge TTS service disposal completed with errors: ${errors.join('; ')}. '
        'Some resources may not have been properly cleaned up.',
        code: TTSErrorCodes.disposePartialFailure,
        originalError: errors,
      );
    }
  }

  void _checkInitialized() {
    if (!_initialized || _processor == null) {
      throw TTSError(
        'Edge TTS service not initialized. Please call initialize() before using the service.',
        code: TTSErrorCodes.notInitialized,
      );
    }
  }
}
