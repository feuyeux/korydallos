import 'dart:io';
import 'package:flutter/foundation.dart';

/// TTS 引擎类型枚举
enum TTSEngineType {
  edge,
  flutter,
}

/// 平台检测和 TTS 引擎选择工具类
/// 参照 hello-tts-dart 的设计模式，提供跨平台检测功能
class PlatformUtils {
  /// 检测当前平台是否为桌面平台
  /// 包括 Windows、macOS、Linux
  static bool get isDesktop => 
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  
  /// 检测当前平台是否为移动平台
  /// 包括 Android、iOS
  static bool get isMobile => 
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  
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
  /// 通过尝试执行 edge-tts --list-voices 命令来检测
  static Future<bool> isEdgeTTSAvailable() async {
    if (kIsWeb) {
      // Web 平台不支持 Edge TTS
      return false;
    }
    
    try {
      final result = await Process.run('edge-tts', ['--list-voices']);
      return result.exitCode == 0;
    } catch (e) {
      // 命令不存在或执行失败
      return false;
    }
  }
  
  /// 检查 Edge TTS 是否可用（带超时）
  /// [timeout] 超时时间，默认 3 秒
  static Future<bool> isEdgeTTSAvailableWithTimeout({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (kIsWeb) {
      return false;
    }
    
    try {
      final result = await Process.run(
        'edge-tts', 
        ['--list-voices'],
      ).timeout(timeout);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
  
  /// 获取 Edge TTS 版本信息
  /// 返回版本字符串，如果不可用则返回 null
  static Future<String?> getEdgeTTSVersion() async {
    if (kIsWeb) {
      return null;
    }
    
    try {
      // edge-tts 没有 --version 参数，使用 --help 来检测
      final result = await Process.run('edge-tts', ['--help']);
      if (result.exitCode == 0) {
        return 'edge-tts (available)';
      }
    } catch (e) {
      // 忽略错误
    }
    return null;
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
}