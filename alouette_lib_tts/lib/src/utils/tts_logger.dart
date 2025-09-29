import 'package:flutter/foundation.dart';

/// 统一的日志工具类
/// 提供一致的日志格式和级别控制
class TTSLogger {
  static bool _debugEnabled = true;
  static const String _prefix = '[TTS]';
  
  /// 启用或禁用调试日志
  static void setDebugEnabled(bool enabled) {
    _debugEnabled = enabled;
  }
  
  /// 信息级别日志
  static void info(String message) {
    if (_debugEnabled) {
      // Use debugPrint for better Flutter integration
      debugPrint('$_prefix INFO: $message');
    }
  }
  
  /// 警告级别日志
  static void warning(String message) {
    if (_debugEnabled) {
      debugPrint('$_prefix WARNING: $message');
    }
  }
  
  /// 错误级别日志
  static void error(String message, [dynamic error]) {
    // Always log errors, even in release mode
    debugPrint('$_prefix ERROR: $message');
    if (error != null) {
      debugPrint('$_prefix ERROR Details: $error');
    }
  }
  
  /// 调试级别日志
  static void debug(String message) {
    if (_debugEnabled) {
      debugPrint('$_prefix DEBUG: $message');
    }
  }
  
  /// 初始化相关日志
  static void initialization(String component, String status, [String? details]) {
    final message = '$component initialization: $status';
    if (details != null) {
      info('$message - $details');
    } else {
      info(message);
    }
  }
  
  /// 引擎相关日志
  static void engine(String operation, String engine, [String? details]) {
    final message = 'Engine $operation: $engine';
    if (details != null) {
      info('$message - $details');
    } else {
      info(message);
    }
  }
  
  /// 语音相关日志
  static void voice(String operation, int count, [String? voiceName]) {
    final message = voiceName != null 
        ? 'Voice $operation: $count voices, selected: $voiceName'
        : 'Voice $operation: $count voices';
    info(message);
  }
}