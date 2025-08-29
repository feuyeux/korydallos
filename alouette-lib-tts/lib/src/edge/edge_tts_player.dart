import 'dart:io';

/// Edge TTS 音频播放器
class EdgeTTSPlayer {
  Process? _currentProcess;

  /// 播放音频文件
  Future<void> play(String filePath) async {
    await stop();

    final player = await _findPlayer();
    if (player == null) {
      throw Exception('No suitable audio player found');
    }

    _currentProcess = await Process.start(
      player.executable,
      player.getArgs(filePath),
    );

    // 等待播放完成
    await _currentProcess!.exitCode;
    _currentProcess = null;
  }

  /// 停止播放
  Future<void> stop() async {
    if (_currentProcess != null) {
      _currentProcess!.kill();
      _currentProcess = null;
    }
  }

  /// 释放资源
  Future<void> dispose() => stop();

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
