import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import '../models/tts_error.dart';

/// 播放状态枚举
enum PlaybackState {
  idle,
  playing,
  paused,
  stopped,
  error,
}

/// 跨平台音频播放器
/// 参照 hello-tts-dart 的 AudioPlayer 实现
class AudioPlayer {
  PlaybackState _state = PlaybackState.idle;
  final List<File> _tempFiles = [];
  Process? _currentProcess;

  /// 获取当前播放状态
  PlaybackState get state => _state;
  /// 播放音频文件
  /// 
  /// [filePath] 音频文件路径
  Future<void> play(String filePath) async {
    if (!File(filePath).existsSync()) {
      _state = PlaybackState.error;
      throw TTSError('Audio file not found: $filePath', code: 'FILE_NOT_FOUND');
    }

    try {
      _state = PlaybackState.playing;
      
      // 根据平台选择不同的音频播放器
      if (Platform.isLinux) {
        await _playOnLinux(filePath);
      } else if (Platform.isMacOS) {
        await _playOnMacOS(filePath);
      } else if (Platform.isWindows) {
        await _playOnWindows(filePath);
      } else {
        _state = PlaybackState.error;
        throw TTSError('Unsupported platform for audio playback', code: 'UNSUPPORTED_PLATFORM');
      }
      
      _state = PlaybackState.idle;
    } catch (e) {
      _state = PlaybackState.error;
      await _cleanup();
      
      if (e is TTSError) {
        rethrow;
      }
      throw TTSError('Failed to play audio: $e', code: 'PLAYBACK_FAILED', originalError: e);
    }
  }

  /// 播放音频字节数据
  /// 
  /// [audioData] 音频数据字节数组
  /// [format] 音频格式，默认为 'mp3'
  Future<void> playBytes(Uint8List audioData, {String format = 'mp3'}) async {
    // 创建临时文件
    final tempDir = Directory.systemTemp;
    final tempFile = File(path.join(tempDir.path, 'temp_audio_${DateTime.now().millisecondsSinceEpoch}.$format'));
    
    try {
      // 注册临时文件以便后续清理
      _tempFiles.add(tempFile);
      await tempFile.writeAsBytes(audioData);
      await play(tempFile.path);
    } catch (e) {
      // 确保在错误情况下清理临时文件
      await _cleanupTempFile(tempFile);
      rethrow;
    } finally {
      // 播放完成后清理临时文件
      await _cleanupTempFile(tempFile);
    }
  }

  /// 停止当前播放
  Future<void> stop() async {
    if (_currentProcess != null) {
      _currentProcess!.kill();
      _currentProcess = null;
    }
    _state = PlaybackState.stopped;
    await _cleanup();
  }

  /// 释放资源和清理临时文件
  Future<void> dispose() async {
    await stop();
    await _cleanup();
  }

  /// 清理所有临时文件和资源
  Future<void> _cleanup() async {
    // 清理所有临时文件
    for (final file in _tempFiles) {
      await _cleanupTempFile(file);
    }
    _tempFiles.clear();
    
    // 终止当前进程
    if (_currentProcess != null) {
      _currentProcess!.kill();
      _currentProcess = null;
    }
  }

  /// 清理单个临时文件
  Future<void> _cleanupTempFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
      _tempFiles.remove(file);
    } catch (e) {
      // 忽略清理错误
    }
  }

  Future<void> _playOnLinux(String filePath) async {
    // 尝试不同的 Linux 音频播放器
    final players = ['paplay', 'aplay', 'mpg123', 'ffplay'];
    
    for (final player in players) {
      try {
        final result = await Process.run('which', [player]);
        if (result.exitCode == 0) {
          _currentProcess = await Process.start(player, [filePath]);
          final exitCode = await _currentProcess!.exitCode;
          _currentProcess = null;
          
          if (exitCode == 0) {
            return;
          }
        }
      } catch (e) {
        // 尝试下一个播放器
        _currentProcess = null;
        continue;
      }
    }
    
    throw TTSError('No suitable audio player found on Linux', code: 'NO_PLAYER_FOUND');
  }

  Future<void> _playOnMacOS(String filePath) async {
    try {
      _currentProcess = await Process.start('afplay', [filePath]);
      final exitCode = await _currentProcess!.exitCode;
      _currentProcess = null;
      
      if (exitCode != 0) {
        throw TTSError('Failed to play audio on macOS', code: 'MACOS_PLAYBACK_FAILED');
      }
    } catch (e) {
      _currentProcess = null;
      if (e is TTSError) {
        rethrow;
      }
      throw TTSError('Failed to play audio on macOS: $e', code: 'MACOS_PLAYBACK_FAILED', originalError: e);
    }
  }

  Future<void> _playOnWindows(String filePath) async {
    // 转换为绝对路径并处理路径中的特殊字符
    final absolutePath = path.isAbsolute(filePath) ? filePath : path.absolute(filePath);
    final escapedPath = absolutePath.replaceAll('"', '""');
    
    // 方法 1: 使用 ffplay (如果可用，最可靠)
    try {
      final result = await Process.run('where', ['ffplay']);
      if (result.exitCode == 0) {
        _currentProcess = await Process.start('ffplay', [
          '-nodisp',
          '-autoexit',
          '-loglevel', 'quiet',
          absolutePath
        ]);
        
        final exitCode = await _currentProcess!.exitCode;
        _currentProcess = null;
        
        if (exitCode == 0) {
          return; // 成功
        }
      }
    } catch (e) {
      _currentProcess = null;
      // 继续下一个方法
    }
    
    // 方法 2: 使用 PowerShell 的 SoundPlayer (对 WAV 文件)
    if (absolutePath.toLowerCase().endsWith('.wav')) {
      try {
        _currentProcess = await Process.start('powershell', [
          '-Command',
          '''
          Add-Type -AssemblyName System.Windows.Forms;
          \$player = New-Object System.Media.SoundPlayer("$escapedPath");
          \$player.PlaySync();
          '''
        ]);
        
        final exitCode = await _currentProcess!.exitCode;
        _currentProcess = null;
        
        if (exitCode == 0) {
          return; // 成功
        }
      } catch (e) {
        _currentProcess = null;
        // 继续下一个方法
      }
    }
    
    // 方法 3: 使用 Windows Media Player COM 对象
    try {
      _currentProcess = await Process.start('powershell', [
        '-Command',
        '''
        \$player = New-Object -ComObject WMPlayer.OCX;
        \$media = \$player.newMedia("$escapedPath");
        \$player.currentPlaylist.appendItem(\$media);
        \$player.controls.play();
        while (\$player.playState -ne 1) { Start-Sleep -Milliseconds 100 };
        \$player.close();
        '''
      ]);
      
      final exitCode = await _currentProcess!.exitCode;
      _currentProcess = null;
      
      if (exitCode == 0) {
        return; // 成功
      }
    } catch (e) {
      _currentProcess = null;
      // 继续下一个方法
    }
    
    // 方法 4: 使用系统默认程序 (非阻塞)
    try {
      _currentProcess = await Process.start('cmd', [
        '/c',
        'start',
        '""',
        '"$absolutePath"'
      ]);
      
      final exitCode = await _currentProcess!.exitCode;
      _currentProcess = null;
      
      if (exitCode == 0) {
        // 给音频播放一些时间 (估算)
        await Future.delayed(Duration(seconds: 2));
        return;
      }
    } catch (e) {
      _currentProcess = null;
    }
    
    throw TTSError('Failed to play audio on Windows: All playback methods failed. Please ensure you have a media player installed.', code: 'WINDOWS_PLAYBACK_FAILED');
  }
}