import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart' as ap;
import '../models/tts_error.dart';
import '../utils/tts_logger.dart';
import '../utils/resource_manager.dart';

/// 播放状态枚举
enum PlaybackState { idle, playing, paused, stopped, error }

/// 跨平台音频播放器
/// 使用 audioplayers 进行应用内播放
class AudioPlayer {
  PlaybackState _state = PlaybackState.idle;
  final ap.AudioPlayer _audioPlayer = ap.AudioPlayer();
  final ResourceManager _resourceManager = ResourceManager.instance;
  final List<File> _tempFiles = [];

  /// 获取当前播放状态
  PlaybackState get state => _state;

  AudioPlayer() {
    // 监听播放状态变化
    _audioPlayer.onPlayerStateChanged.listen((ap.PlayerState state) {
      switch (state) {
        case ap.PlayerState.playing:
          _state = PlaybackState.playing;
          break;
        case ap.PlayerState.paused:
          _state = PlaybackState.paused;
          break;
        case ap.PlayerState.stopped:
          _state = PlaybackState.stopped;
          break;
        case ap.PlayerState.completed:
          _state = PlaybackState.idle;
          break;
        case ap.PlayerState.disposed:
          _state = PlaybackState.idle;
          break;
      }
    });
  }

  /// 播放音频文件
  ///
  /// [filePath] 音频文件路径
  Future<void> play(String filePath) async {
    TTSLogger.debug('Starting audio playback for: $filePath');

    if (!File(filePath).existsSync()) {
      _state = PlaybackState.error;
      throw TTSError('Audio file not found: $filePath', code: 'FILE_NOT_FOUND');
    }

    try {
      _state = PlaybackState.playing;

      // 使用 audioplayers 进行应用内播放
      await _audioPlayer.play(ap.DeviceFileSource(filePath));

      // 等待播放完成
      await _audioPlayer.onPlayerComplete.first;

      _state = PlaybackState.idle;
      TTSLogger.debug('Audio playback completed successfully');
    } catch (e) {
      _state = PlaybackState.error;
      await _cleanup();
      TTSLogger.error('Audio playback failed', e);

      if (e is TTSError) {
        rethrow;
      }
      throw TTSError(
        'Failed to play audio: $e',
        code: 'PLAYBACK_FAILED',
        originalError: e,
      );
    }
  }

  /// 播放音频字节数据
  ///
  /// [audioData] 音频数据字节数组
  /// [format] 音频格式，默认为 'mp3'
  Future<void> playBytes(Uint8List audioData, {String format = 'mp3'}) async {
    // 使用资源管理器的 withTempFile 方法自动管理临时文件
    await _resourceManager.withTempFile(
      (tempFile) async {
        TTSLogger.debug(
          'Playing audio bytes: ${audioData.length} bytes for format $format',
        );

        await tempFile.writeAsBytes(audioData);
        await play(tempFile.path);
      },
      prefix: 'temp_audio_${DateTime.now().millisecondsSinceEpoch}',
      suffix: '.$format',
    );
  }

  /// 停止当前播放
  Future<void> stop() async {
    TTSLogger.debug('Stopping audio playback');
    await _audioPlayer.stop();
    _state = PlaybackState.stopped;
  }

  /// 释放资源和清理临时文件
  Future<void> dispose() async {
    TTSLogger.debug('Disposing audio player');
    await stop();
    await _audioPlayer.dispose();
    await _cleanup();
  }

  /// 清理所有临时文件和资源
  Future<void> _cleanup() async {
    // 清理所有临时文件
    for (final file in _tempFiles) {
      await _cleanupTempFile(file);
    }
    _tempFiles.clear();
  }

  /// 清理单个临时文件
  Future<void> _cleanupTempFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        TTSLogger.debug('Temporary file cleaned up: ${file.path}');
      }
      _tempFiles.remove(file);
    } catch (e) {
      TTSLogger.warning(
        'Failed to cleanup temporary file: ${file.path}, error: $e',
      );
    }
  }
}
