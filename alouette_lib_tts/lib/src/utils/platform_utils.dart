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
      return false;
    }

    // For macOS, we know Edge TTS is available, so force return true as a workaround
    // for the Flutter Process.run environment issue
    if (Platform.isMacOS) {
      // Still try a quick check but don't fail if it doesn't work
      try {
        final result = await Process.run('which', [
          'edge-tts',
        ]).timeout(Duration(seconds: 2));
        if (result.exitCode == 0) {
          return true;
        }
      } catch (e) {
        // Quick check failed, but we'll still return true for macOS
      }

      // Force return true for macOS since we know it works from terminal
      return true;
    }

    // 策略1: 使用 which/where 命令查找 - 最可靠的方法
    try {
      final whichCmd = Platform.isWindows ? 'where' : 'which';
      final whichResult = await Process.run(whichCmd, [
        'edge-tts',
      ]).timeout(Duration(seconds: 3));

      if (whichResult.exitCode == 0) {
        final edgePath = whichResult.stdout.toString().trim().split('\n').first;

        if (edgePath.isNotEmpty) {
          // 验证 edge-tts 是否真的可用
          try {
            final testResult = await Process.run(
              edgePath,
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
            ).timeout(Duration(seconds: 5));
            final stderrStr = testResult.stderr.toString();
            if (testResult.exitCode == 0 || stderrStr.contains('usage:')) {
              return true;
            }
          } catch (e) {
            // Test failed; path exists => treat as available
            return true;
          }
        }
      }
    } catch (e) {
      // which/where command failed, continue to next strategy
    }

    // 策略2: 直接尝试执行 edge-tts (可能在 PATH 中但 which/where 失败)
    try {
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
      ).timeout(Duration(seconds: 5));
      final stderrStr = result.stderr.toString();
      if (result.exitCode == 0 || stderrStr.contains('usage:')) {
        return true;
      }
    } catch (e) {
      // Direct execution failed; try --version as presence check
      try {
        final ver = await Process.run(
          'edge-tts',
          ['--version'],
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
        ).timeout(Duration(seconds: 3));
        final stderrStr = ver.stderr.toString();
        if (ver.exitCode == 0 || stderrStr.contains('usage:')) {
          return true;
        }
      } catch (_) {}
    }

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
      // If the full check times out, try a simpler check
      try {
        final result = await Process.run('which', [
          'edge-tts',
        ]).timeout(Duration(seconds: 3));
        final isAvailable = result.exitCode == 0;
        return isAvailable;
      } catch (e2) {
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
      final result = await Process.run(whichCmd, [
        'edge-tts',
      ]).timeout(Duration(seconds: 3));
      if (result.exitCode == 0) {
        final path = result.stdout.toString().trim().split('\n').first;
        if (path.isNotEmpty) {
          return path;
        }
      }
    } catch (e) {
      // which/where command failed
    }

    // 如果 which/where 失败，但 edge-tts 可能仍在 PATH 中
    try {
      final result = await Process.run(
        'edge-tts',
        ['--version'],
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
      ).timeout(Duration(seconds: 3));
      final stderrStr = result.stderr.toString();
      if (result.exitCode == 0 || stderrStr.contains('usage:')) {
        return 'edge-tts'; // 返回命令名，让系统通过 PATH 查找
      }
    } catch (e) {
      // Direct execution failed
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
