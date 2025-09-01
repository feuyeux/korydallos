import 'dart:io';
import '../models/tts_error.dart';

/// Edge TTS 音频播放器
/// 更新为使用统一的 TTSError 错误处理
class EdgeTTSPlayer {
  Process? _currentProcess;

  /// 播放音频文件
  Future<void> play(String filePath) async {
    try {
      await stop();

      // 验证文件是否存在
      if (!await File(filePath).exists()) {
        throw TTSError(
          'Audio file not found: $filePath',
          code: TTSErrorCodes.fileNotFound,
        );
      }

      final player = await _findPlayer();
      if (player == null) {
        throw TTSError(
          'No suitable audio player found on this system. '
          'Please install one of the following audio players: mpv, ffplay, paplay, aplay, or ensure xdg-open is available.',
          code: TTSErrorCodes.noPlayerFound,
        );
      }

      _currentProcess = await Process.start(
        player.executable,
        player.getArgs(filePath),
      );

      // 等待播放完成
      final exitCode = await _currentProcess!.exitCode;
      _currentProcess = null;
      
      if (exitCode != 0) {
        throw TTSError(
          'Audio playback failed with exit code: $exitCode. '
          'This may indicate an unsupported audio format or corrupted audio file. '
          'Try using a different audio format or check if the audio player is working correctly.',
          code: TTSErrorCodes.playbackFailed,
        );
      }
    } catch (e) {
      _currentProcess = null;
      
      if (e is TTSError) {
        rethrow;
      }
      
      throw TTSError(
        'Failed to play audio: $e',
        code: TTSErrorCodes.playbackError,
        originalError: e,
      );
    }
  }

  /// 停止播放
  Future<void> stop() async {
    if (_currentProcess != null) {
      try {
        _currentProcess!.kill();
      } catch (e) {
        // 进程可能已经结束，记录但不抛出错误
      } finally {
        _currentProcess = null;
      }
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    try {
      await stop();
    } catch (e) {
      throw TTSError(
        'Failed to dispose audio player: $e. '
        'Some audio processes may still be running in the background.',
        code: TTSErrorCodes.disposeFailed,
        originalError: e,
      );
    }
  }

  /// 查找可用的音频播放器
  Future<_AudioPlayer?> _findPlayer() async {
    final players = [
      _AudioPlayer(
        'mpv',
        (path) => ['--no-terminal', path],
      ),
      _AudioPlayer(
        'ffplay',
        (path) => ['-nodisp', '-autoexit', path],
      ),
      _AudioPlayer(
        'paplay',
        (path) => [path],
      ),
      _AudioPlayer(
        'aplay',
        (path) => [path],
      ),
      _AudioPlayer(
        'xdg-open',
        (path) => [path],
      ),
    ];

    for (final player in players) {
      try {
        final result = await Process.run('which', [player.executable]);
        if (result.exitCode == 0) {
          return player;
        }
      } catch (_) {}
    }

    return null;
  }
}

/// 音频播放器配置
class _AudioPlayer {
  final String executable;
  final List<String> Function(String path) getArgs;

  const _AudioPlayer(this.executable, this.getArgs);
}
