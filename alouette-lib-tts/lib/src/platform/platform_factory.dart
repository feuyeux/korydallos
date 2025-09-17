import 'dart:io';
import 'package:flutter/foundation.dart';
import '../utils/platform_utils.dart';
import '../utils/tts_logger.dart';
import '../models/tts_error.dart';
import '../enums/tts_engine_type.dart';
import '../engines/edge_tts_processor.dart';
import '../engines/flutter_tts_processor.dart';
import '../engines/base_processor.dart';

/// 平台适配器抽象基类
/// 提供统一的平台检测和适配接口
abstract class PlatformAdapter {
  /// 适配器名称
  String get name;

  /// 对应的引擎类型
  TTSEngineType get engineType;

  /// 检查当前平台是否支持此适配器
  bool get isSupported;

  /// 检查具体可用性（可能包含异步检测）
  Future<bool> checkAvailability();

  /// 创建处理器实例
  BaseTTSProcessor createProcessor();

  /// 获取平台诊断信息
  Map<String, dynamic> getDiagnostics();

  /// 获取推荐优先级（数字越小优先级越高）
  int get priority;
}

/// Edge TTS 平台适配器
class EdgeTTSAdapter extends PlatformAdapter {
  @override
  String get name => 'Edge TTS';

  @override
  TTSEngineType get engineType => TTSEngineType.edge;

  @override
  bool get isSupported {
    // Edge TTS 仅在支持进程执行的桌面平台上可用
    return PlatformUtils.isDesktop && PlatformUtils.supportsProcessExecution;
  }

  @override
  int get priority => 1; // 桌面平台的首选

  @override
  Future<bool> checkAvailability() async {
    if (!isSupported) {
      TTSLogger.debug('Edge TTS not supported on this platform');
      return false;
    }

    try {
      TTSLogger.debug('Checking Edge TTS availability...');
      final available = await PlatformUtils.isEdgeTTSAvailableWithTimeout(
        timeout: const Duration(seconds: 12),
      );
      TTSLogger.debug('Edge TTS availability check result: $available');

      if (!available) {
        // Get more detailed diagnostic information
        final edgePath = await PlatformUtils.getEdgeTTSPath();
        TTSLogger.debug('Edge TTS path check result: $edgePath');

        // Try a simple edge-tts command to see what happens
        try {
          final result = await Process.run('edge-tts', ['--version'])
              .timeout(Duration(seconds: 5));
          TTSLogger.debug('edge-tts --version exit code: ${result.exitCode}');
          TTSLogger.debug('edge-tts --version stdout: ${result.stdout}');
          TTSLogger.debug('edge-tts --version stderr: ${result.stderr}');
        } catch (e) {
          TTSLogger.debug('edge-tts --version command failed: $e');
        }

        // Try which/where command
        try {
          final whichCmd = Platform.isWindows ? 'where' : 'which';
          final whichResult = await Process.run(whichCmd, ['edge-tts'])
              .timeout(Duration(seconds: 3));
          TTSLogger.debug(
              '$whichCmd edge-tts exit code: ${whichResult.exitCode}');
          TTSLogger.debug('$whichCmd edge-tts stdout: ${whichResult.stdout}');
          TTSLogger.debug('$whichCmd edge-tts stderr: ${whichResult.stderr}');
        } catch (e) {
          final whichCmd = Platform.isWindows ? 'where' : 'which';
          TTSLogger.debug('$whichCmd edge-tts command failed: $e');
        }
      }

      return available;
    } catch (e) {
      TTSLogger.warning('Edge TTS availability check failed: $e');
      return false;
    }
  }

  @override
  BaseTTSProcessor createProcessor() {
    return EdgeTTSProcessor();
  }

  @override
  Map<String, dynamic> getDiagnostics() {
    final diagnostics = <String, dynamic>{
      'name': name,
      'engineType': engineType.name,
      'supported': isSupported,
      'priority': priority,
      'platform': PlatformUtils.platformName,
      'supportsProcessExecution': PlatformUtils.supportsProcessExecution,
    };

    if (!isSupported) {
      diagnostics['reason'] = kIsWeb
          ? 'Web platform does not support process execution'
          : 'Not a desktop platform';
    }

    return diagnostics;
  }
}

/// Flutter TTS 平台适配器
class FlutterTTSAdapter extends PlatformAdapter {
  @override
  String get name => 'Flutter TTS';

  @override
  TTSEngineType get engineType => TTSEngineType.flutter;

  @override
  bool get isSupported {
    // Flutter TTS 在所有支持的平台上都可用
    return PlatformUtils.isFlutterTTSSupported;
  }

  @override
  int get priority {
    // 在移动和Web平台优先级较高，桌面平台较低
    if (PlatformUtils.isMobile || PlatformUtils.isWeb) {
      return 1;
    }
    return 2; // 桌面平台作为回退选项
  }

  @override
  Future<bool> checkAvailability() async {
    if (!isSupported) {
      TTSLogger.debug('Flutter TTS not supported on this platform');
      return false;
    }

    // Flutter TTS 在支持的平台上总是可用的
    TTSLogger.debug('Flutter TTS is available');
    return true;
  }

  @override
  BaseTTSProcessor createProcessor() {
    return FlutterTTSProcessor();
  }

  @override
  Map<String, dynamic> getDiagnostics() {
    return {
      'name': name,
      'engineType': engineType.name,
      'supported': isSupported,
      'priority': priority,
      'platform': PlatformUtils.platformName,
      'isDesktop': PlatformUtils.isDesktop,
      'isMobile': PlatformUtils.isMobile,
      'isWeb': PlatformUtils.isWeb,
    };
  }
}

/// 平台 TTS 工厂类
/// 整合原有的 PlatformAdapterManager 和 PlatformTTSFactory 功能
/// 提供平台检测、适配器管理和处理器创建功能
class PlatformTTSFactory {
  static PlatformTTSFactory? _instance;
  static PlatformTTSFactory get instance =>
      _instance ??= PlatformTTSFactory._();

  PlatformTTSFactory._() {
    _adapters = [
      EdgeTTSAdapter(),
      FlutterTTSAdapter(),
    ];
  }

  late final List<PlatformAdapter> _adapters;

  /// 获取所有适配器
  List<PlatformAdapter> get allAdapters => List.unmodifiable(_adapters);

  /// 获取支持的适配器
  List<PlatformAdapter> get supportedAdapters {
    return _adapters.where((adapter) => adapter.isSupported).toList();
  }

  /// 获取推荐的适配器（按优先级排序）
  List<PlatformAdapter> getRecommendedAdapters() {
    final supported = supportedAdapters;
    supported.sort((a, b) => a.priority.compareTo(b.priority));
    return supported;
  }

  /// 根据名称查找适配器
  PlatformAdapter? findAdapterByName(String name) {
    try {
      return _adapters.firstWhere(
        (adapter) => adapter.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// 根据引擎类型查找适配器
  PlatformAdapter? findAdapterByType(TTSEngineType engineType) {
    try {
      return _adapters.firstWhere(
        (adapter) => adapter.engineType == engineType,
      );
    } catch (e) {
      return null;
    }
  }

  /// 自动选择最佳适配器
  Future<PlatformAdapter?> selectBestAdapter() async {
    TTSLogger.debug('Selecting best platform adapter');

    final recommended = getRecommendedAdapters();
    if (recommended.isEmpty) {
      TTSLogger.warning('No supported platform adapters found');
      return null;
    }

    // 按优先级逐一检查可用性
    for (final adapter in recommended) {
      try {
        final available = await adapter.checkAvailability();
        if (available) {
          TTSLogger.info('Selected platform adapter: ${adapter.name}');
          return adapter;
        }
      } catch (e) {
        TTSLogger.warning(
            'Failed to check availability for ${adapter.name}: $e');
        continue;
      }
    }

    // 如果没有找到可用的适配器，返回第一个支持的作为回退
    final fallback = recommended.first;
    TTSLogger.warning(
        'No available adapters found, using fallback: ${fallback.name}');
    return fallback;
  }

  /// 根据平台自动创建最适合的 TTS 处理器
  Future<BaseTTSProcessor> createForPlatform() async {
    TTSLogger.debug('Creating TTS processor for platform');

    try {
      final adapter = await selectBestAdapter();
      if (adapter == null) {
        throw TTSError(
          'No TTS adapters available for this platform',
          code: TTSErrorCodes.initializationFailed,
        );
      }

      return adapter.createProcessor();
    } catch (e) {
      TTSLogger.error('Failed to create processor for platform', e);
      rethrow;
    }
  }

  /// 为指定引擎类型创建 TTS 处理器
  Future<BaseTTSProcessor> createForEngine(TTSEngineType engineType) async {
    TTSLogger.debug('Creating TTS processor for engine: ${engineType.name}');

    final adapter = findAdapterByType(engineType);
    if (adapter == null) {
      throw TTSError(
        'No adapter found for engine type: ${engineType.name}',
        code: TTSErrorCodes.initializationFailed,
      );
    }

    // 检查可用性
    final available = await adapter.checkAvailability();
    if (!available) {
      final diagnostics = adapter.getDiagnostics();

      String errorMessage =
          '${engineType.name} TTS is not available on this system.';
      if (diagnostics['reason'] != null) {
        errorMessage += '\nReason: ${diagnostics['reason']}';
      }

      // 提供安装建议
      if (engineType == TTSEngineType.edge) {
        errorMessage +=
            '\nTo install: pip install edge-tts\nEnsure Python and pip are in your PATH.';
      }

      throw TTSError(
        errorMessage,
        code: TTSErrorCodes.initializationFailed,
      );
    }

    return adapter.createProcessor();
  }

  /// 获取当前平台推荐的引擎类型
  TTSEngineType get recommendedEngineType {
    return PlatformUtils.recommendedEngine;
  }

  /// 检查指定引擎是否在当前平台可用
  Future<bool> isEngineAvailable(TTSEngineType engineType) async {
    final adapter = findAdapterByType(engineType);
    if (adapter == null || !adapter.isSupported) {
      return false;
    }

    try {
      return await adapter.checkAvailability();
    } catch (e) {
      return false;
    }
  }

  /// 获取当前平台所有可用的引擎类型
  Future<List<TTSEngineType>> getAvailableEngines() async {
    final availableEngines = <TTSEngineType>[];

    for (final adapter in supportedAdapters) {
      try {
        final available = await adapter.checkAvailability();
        if (available) {
          availableEngines.add(adapter.engineType);
        }
      } catch (e) {
        TTSLogger.warning(
            'Failed to check availability for ${adapter.name}: $e');
      }
    }

    return availableEngines;
  }

  /// 获取平台和引擎可用性信息
  Future<Map<String, dynamic>> getPlatformInfo() async {
    final availableEngines = await getAvailableEngines();

    final adapterDiagnostics = <String, dynamic>{};
    for (final adapter in allAdapters) {
      final diagnostics = adapter.getDiagnostics();

      // 添加可用性检查结果
      try {
        final available = await adapter.checkAvailability();
        diagnostics['available'] = available;
      } catch (e) {
        diagnostics['available'] = false;
        diagnostics['availabilityError'] = e.toString();
      }

      adapterDiagnostics[adapter.name] = diagnostics;
    }

    return {
      'platform': PlatformUtils.platformName,
      'isDesktop': PlatformUtils.isDesktop,
      'isMobile': PlatformUtils.isMobile,
      'isWeb': PlatformUtils.isWeb,
      'supportsProcessExecution': PlatformUtils.supportsProcessExecution,
      'supportsFileSystem': PlatformUtils.supportsFileSystem,
      'recommendedEngine': recommendedEngineType.name,
      'availableEngines': availableEngines.map((e) => e.name).toList(),
      'adapters': adapterDiagnostics,
    };
  }
}

/// 平台 TTS 异常
/// 保持向后兼容性
class PlatformTTSException implements Exception {
  final String message;

  PlatformTTSException(this.message);

  @override
  String toString() => 'PlatformTTSException: $message';
}
