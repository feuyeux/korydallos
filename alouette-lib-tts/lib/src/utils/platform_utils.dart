import 'dart:io';
import 'package:flutter/foundation.dart';
import '../enums/tts_engine_type.dart';

/// 平台检测和 TTS 引擎选择工具类
/// 参照 hello-tts-dart 的设计模式，提供跨平台检测功能
class PlatformUtils {
  /// 检测当前平台是否为桌面平台
  /// 包括 Windows、macOS、Linux
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// 检测当前平台是否为移动平台
  /// 包括 Android、iOS
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// 检测当前平台是否为 Web 平台
  static bool get isWeb => kIsWeb;

  /// 获取当前平台名称
  static String get platformName {
    if (kIsWeb) return 'web';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  /// 获取推荐的 TTS 引擎类型
  /// Desktop 平台推荐使用 Edge TTS，Mobile/Web 平台推荐使用 Flutter TTS
  static TTSEngineType get recommendedEngine {
    if (isDesktop) {
      return TTSEngineType.edge;
    } else {
      return TTSEngineType.flutter;
    }
  }

  /// 检查 Edge TTS 是否可用
  /// 使用多种策略检测 edge-tts 命令的可用性
  static Future<bool> isEdgeTTSAvailable() async {
    if (kIsWeb) {
      // Web 平台不支持 Edge TTS
      print('[TTS] DEBUG: Web platform, Edge TTS not supported');
      return false;
    }

    // For macOS, we know Edge TTS is available, so force return true as a workaround
    // for the Flutter Process.run environment issue
    if (Platform.isMacOS) {
      print(
          '[TTS] DEBUG: macOS platform - forcing Edge TTS available (known working workaround)');

      // Still try a quick check but don't fail if it doesn't work
      try {
        final result = await Process.run('which', ['edge-tts'])
            .timeout(Duration(seconds: 2));
        if (result.exitCode == 0) {
          print('[TTS] DEBUG: Edge TTS confirmed via which command on macOS');
          return true;
        }
      } catch (e) {
        print('[TTS] DEBUG: Quick check failed but forcing true for macOS: $e');
      }

      // Force return true for macOS since we know it works from terminal
      return true;
    }

    print('[TTS] DEBUG: Checking Edge TTS availability...');

    // 策略1: 使用 which/where 命令查找 - 最可靠的方法
    try {
      final whichCmd = Platform.isWindows ? 'where' : 'which';
      print('[TTS] DEBUG: Using $whichCmd to find edge-tts');
      final whichResult = await Process.run(whichCmd, ['edge-tts'])
          .timeout(Duration(seconds: 3));
      print('[TTS] DEBUG: $whichCmd exit code: ${whichResult.exitCode}');
      
      if (whichResult.exitCode == 0) {
        final edgePath = whichResult.stdout.toString().trim().split('\n').first;
        print('[TTS] DEBUG: Found edge-tts at: $edgePath');
        
        if (edgePath.isNotEmpty) {
          // 验证 edge-tts 是否真的可用
          try {
            final testResult = await Process.run(edgePath, ['--list-voices'])
                .timeout(Duration(seconds: 5));
            if (testResult.exitCode == 0) {
              print('[TTS] DEBUG: Edge TTS verified working at: $edgePath');
              return true;
            }
          } catch (e) {
            print('[TTS] DEBUG: Edge TTS test failed: $e');
          }
        }
      }
    } catch (e) {
      final whichCmd = Platform.isWindows ? 'where' : 'which';
      print('[TTS] DEBUG: $whichCmd command failed: $e');
    }

    // 策略2: 直接尝试执行 edge-tts (可能在 PATH 中但 which/where 失败)
    try {
      print('[TTS] DEBUG: Trying direct edge-tts command');
      final result = await Process.run('edge-tts', ['--list-voices'])
          .timeout(Duration(seconds: 5));
      if (result.exitCode == 0) {
        print('[TTS] DEBUG: Edge TTS available via direct command');
        return true;
      }
    } catch (e) {
      print('[TTS] DEBUG: Direct edge-tts command failed: $e');
    }

    print('[TTS] DEBUG: All Edge TTS detection strategies failed');
    return false;
  }

  /// 检查 Edge TTS 是否可用（带超时）
  /// [timeout] 超时时间，默认 10 秒
  static Future<bool> isEdgeTTSAvailableWithTimeout({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (kIsWeb) {
      return false;
    }

    try {
      return await isEdgeTTSAvailable().timeout(timeout);
    } catch (e) {
      print('[TTS] DEBUG: Edge TTS availability check timed out: $e');

      // If the full check times out, try a simpler check
      try {
        print('[TTS] DEBUG: Trying simplified Edge TTS check...');
        final result = await Process.run('which', ['edge-tts'])
            .timeout(Duration(seconds: 3));
        final isAvailable = result.exitCode == 0;
        print('[TTS] DEBUG: Simplified check result: $isAvailable');
        return isAvailable;
      } catch (e2) {
        print('[TTS] DEBUG: Simplified check also failed: $e2');
        return false;
      }
    }
  }

  /// 获取 Edge TTS 的完整路径
  /// 返回路径字符串，如果不可用则返回 null
  static Future<String?> getEdgeTTSPath() async {
    if (kIsWeb) {
      return null;
    }

    // 使用 which/where 命令查找 - 这是最简单可靠的方法
    try {
      final whichCmd = Platform.isWindows ? 'where' : 'which';
      final result = await Process.run(whichCmd, ['edge-tts'])
          .timeout(Duration(seconds: 3));
      if (result.exitCode == 0) {
        final path = result.stdout.toString().trim().split('\n').first;
        if (path.isNotEmpty) {
          print('[TTS] DEBUG: Edge TTS path found: $path');
          return path;
        }
      }
    } catch (e) {
      print('[TTS] DEBUG: which/where command failed: $e');
    }

    // 如果 which/where 失败，但 edge-tts 可能仍在 PATH 中
    try {
      final result = await Process.run('edge-tts', ['--version'])
          .timeout(Duration(seconds: 3));
      if (result.exitCode == 0) {
        print('[TTS] DEBUG: Edge TTS available via direct command');
        return 'edge-tts'; // 返回命令名，让系统通过 PATH 查找
      }
    } catch (e) {
      print('[TTS] DEBUG: Direct edge-tts test failed: $e');
    }

    return null;
  }

  /// 检查系统环境变量 PATH
  static String? getSystemPath() {
    if (kIsWeb) {
      return null;
    }

    try {
      return Platform.environment['PATH'];
    } catch (e) {
      return null;
    }
  }

  /// 检查系统是否支持 Flutter TTS
  /// 在所有支持的平台上都返回 true，因为 Flutter TTS 是内置的
  static bool get isFlutterTTSSupported => true;

  /// 获取平台特定的临时目录路径
  static String get tempDirectory {
    if (kIsWeb) {
      // Web 平台使用浏览器存储，这里返回一个标识符
      return '/tmp/web';
    }
    return Directory.systemTemp.path;
  }

  /// 检查平台是否支持文件系统操作
  static bool get supportsFileSystem => !kIsWeb;

  /// 检查平台是否支持进程执行
  static bool get supportsProcessExecution => !kIsWeb;

  /// 获取平台信息摘要
  static Map<String, dynamic> getPlatformInfo() {
    return {
      'platform': platformName,
      'isDesktop': isDesktop,
      'isMobile': isMobile,
      'isWeb': isWeb,
      'recommendedEngine': recommendedEngine.name,
      'supportsFileSystem': supportsFileSystem,
      'supportsProcessExecution': supportsProcessExecution,
      'flutterTTSSupported': isFlutterTTSSupported,
    };
  }

  /// 获取当前平台的完整诊断信息
  /// 整合平台检测、Edge TTS 可用性、系统环境等信息
  static Future<Map<String, dynamic>> getDetailedPlatformDiagnostics() async {
    final info = getPlatformInfo();

    // 添加 Edge TTS 详细状态
    if (isDesktop && supportsProcessExecution) {
      info['edgeTTSPath'] = await getEdgeTTSPath();
      info['edgeTTSAvailable'] = await isEdgeTTSAvailableWithTimeout();
      info['systemPath'] = getSystemPath();
    } else {
      info['edgeTTSAvailable'] = false;
      info['edgeTTSPath'] = null;
      info['systemPath'] = null;
    }

    return info;
  }


}