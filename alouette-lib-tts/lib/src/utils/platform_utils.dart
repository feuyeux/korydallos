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
  /// 使用多种策略检测 edge-tts 命令的可用性
  static Future<bool> isEdgeTTSAvailable() async {
    if (kIsWeb) {
      // Web 平台不支持 Edge TTS
      return false;
    }
    
    // 策略1: 尝试常见的安装位置
    final commonPaths = _getCommonEdgeTTSPaths();
    for (final path in commonPaths) {
      try {
        final result = await Process.run(path, ['--list-voices']);
        if (result.exitCode == 0) {
          return true;
        }
      } catch (e) {
        // 继续尝试下一个路径
        continue;
      }
    }
    
    // 策略2: 使用 which/where 命令查找
    try {
      final whichCmd = Platform.isWindows ? 'where' : 'which';
      final whichResult = await Process.run(whichCmd, ['edge-tts']);
      if (whichResult.exitCode == 0) {
        final edgePath = whichResult.stdout.toString().trim().split('\n').first;
        if (edgePath.isNotEmpty) {
          final testResult = await Process.run(edgePath, ['--list-voices']);
          return testResult.exitCode == 0;
        }
      }
    } catch (e) {
      // which/where 命令失败，继续下一个策略
    }
    
    // 策略3: 直接尝试执行 edge-tts (依赖系统 PATH)
    try {
      final result = await Process.run('edge-tts', ['--list-voices']);
      return result.exitCode == 0;
    } catch (e) {
      // 所有策略都失败
      return false;
    }
  }
  
  /// 检查 Edge TTS 是否可用（带超时）
  /// [timeout] 超时时间，默认 5 秒
  static Future<bool> isEdgeTTSAvailableWithTimeout({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (kIsWeb) {
      return false;
    }
    
    try {
      return await isEdgeTTSAvailable().timeout(timeout);
    } catch (e) {
      return false;
    }
  }
  
  /// 获取 Edge TTS 的完整路径
  /// 返回路径字符串，如果不可用则返回 null
  static Future<String?> getEdgeTTSPath() async {
    if (kIsWeb) {
      return null;
    }
    
    // 策略1: 检查常见的安装位置
    final commonPaths = _getCommonEdgeTTSPaths();
    for (final path in commonPaths) {
      try {
        final result = await Process.run(path, ['--version']);
        if (result.exitCode == 0) {
          return path;
        }
      } catch (e) {
        continue;
      }
    }
    
    // 策略2: 使用 which/where 命令查找
    try {
      final whichCmd = Platform.isWindows ? 'where' : 'which';
      final result = await Process.run(whichCmd, ['edge-tts']);
      if (result.exitCode == 0) {
        final path = result.stdout.toString().trim().split('\n').first;
        return path.isNotEmpty ? path : null;
      }
    } catch (e) {
      // which/where 命令失败
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

  /// 获取常见的 Edge TTS 安装路径
  static List<String> _getCommonEdgeTTSPaths() {
    final paths = <String>[];
    
    if (Platform.isWindows) {
      // Windows 常见路径
      final userProfile = Platform.environment['USERPROFILE'] ?? '';
      final programFiles = Platform.environment['ProgramFiles'] ?? 'C:\\Program Files';
      final programFilesX86 = Platform.environment['ProgramFiles(x86)'] ?? 'C:\\Program Files (x86)';
      
      paths.addAll([
        'edge-tts.exe',
        'C:\\Python*\\Scripts\\edge-tts.exe',
        '$userProfile\\AppData\\Local\\Programs\\Python\\Python*\\Scripts\\edge-tts.exe',
        '$userProfile\\AppData\\Roaming\\Python\\Python*\\Scripts\\edge-tts.exe',
        '$programFiles\\Python*\\Scripts\\edge-tts.exe',
        '$programFilesX86\\Python*\\Scripts\\edge-tts.exe',
      ]);
    } else {
      // macOS 和 Linux 常见路径
      final home = Platform.environment['HOME'] ?? '';
      
      paths.addAll([
        'edge-tts',
        '/usr/local/bin/edge-tts',
        '/usr/bin/edge-tts',
        '/opt/homebrew/bin/edge-tts',
        '/opt/local/bin/edge-tts',
        '$home/.local/bin/edge-tts',
        '$home/miniconda3/bin/edge-tts',
        '$home/anaconda3/bin/edge-tts',
        '$home/.conda/bin/edge-tts',
        '$home/.pyenv/shims/edge-tts',
      ]);
      
      // 添加 conda 环境路径
      final condaPrefix = Platform.environment['CONDA_PREFIX'];
      if (condaPrefix != null) {
        paths.add('$condaPrefix/bin/edge-tts');
      }
      
      // 添加各种 Python 版本的可能路径
      for (final version in ['3.8', '3.9', '3.10', '3.11', '3.12']) {
        paths.addAll([
          '$home/.local/lib/python$version/bin/edge-tts',
          '/usr/local/lib/python$version/bin/edge-tts',
        ]);
      }
    }
    
    return paths;
  }
}