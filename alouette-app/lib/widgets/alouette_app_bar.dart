import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:alouette_lib_tts/alouette_tts.dart';
import '../services/tts_manager.dart';

class AlouetteAppBar extends StatefulWidget implements PreferredSizeWidget {
  const AlouetteAppBar({super.key});

  @override
  State<AlouetteAppBar> createState() => _AlouetteAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AlouetteAppBarState extends State<AlouetteAppBar> {
  TTSEngineType? _currentEngine;

  @override
  void initState() {
    super.initState();
    _loadTTSEngineInfo();
    // 定期检查TTS状态更新
    _startPeriodicCheck();
  }

  void _startPeriodicCheck() {
    // 每秒检查一次TTS状态，直到初始化完成
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      
      if (TTSManager.isInitialized && _currentEngine != TTSManager.currentEngine) {
        setState(() {
          _currentEngine = TTSManager.currentEngine;
        });
        return false; // 停止检查
      }
      
      return !TTSManager.isInitialized; // 继续检查直到初始化完成
    });
  }

  Future<void> _loadTTSEngineInfo() async {
    try {
      if (TTSManager.isInitialized) {
        setState(() {
          _currentEngine = TTSManager.currentEngine;
        });
      }
    } catch (e) {
      // 忽略错误，使用默认显示
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      title: Row(
        children: [
          // Alouette标题
          const Text(
            'Alouette',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Logo
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/icons/alouette_rounded.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.translate,
                      color: Colors.blue,
                      size: 20,
                    ),
                  );
                },
              ),
            ),
          ),
          
          const Spacer(),
          
          // 系统信息
          _buildSystemInfo(),
        ],
      ),
    );
  }

  Widget _buildSystemInfo() {
    final platform = _getPlatformName();
    final ttsEngine = _getTTSEngineName();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getPlatformIcon(),
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            platform,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 12,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Icon(
            _getTTSEngineIcon(),
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            ttsEngine,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _getTTSEngineName() {
    switch (_currentEngine) {
      case TTSEngineType.edge:
        return 'Edge TTS';
      case TTSEngineType.flutter:
        return 'Flutter TTS';
      case null:
        return 'Loading...'; // 避免使用TTS缩写，显示加载状态
    }
  }

  IconData _getTTSEngineIcon() {
    switch (_currentEngine) {
      case TTSEngineType.edge:
        return Icons.cloud; // Edge TTS 使用云图标
      case TTSEngineType.flutter:
        return Icons.phone_android; // Flutter TTS 使用设备图标
      case null:
        return Icons.record_voice_over; // 默认语音图标
    }
  }

  String _getPlatformName() {
    if (kIsWeb) return 'Web';
    try {
      if (Platform.isWindows) return 'Windows';
      if (Platform.isMacOS) return 'macOS';
      if (Platform.isLinux) return 'Linux';
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
    } catch (e) {
      // 如果Platform类不可用，默认返回Unknown
      return 'Unknown';
    }
    return 'Unknown';
  }

  IconData _getPlatformIcon() {
    if (kIsWeb) return Icons.web;
    try {
      if (Platform.isWindows) return Icons.desktop_windows;
      if (Platform.isMacOS) return Icons.desktop_mac;
      if (Platform.isLinux) return Icons.computer;
      if (Platform.isAndroid) return Icons.phone_android;
      if (Platform.isIOS) return Icons.phone_iphone;
    } catch (e) {
      // 如果Platform类不可用，默认返回通用图标
      return Icons.devices;
    }
    return Icons.devices;
  }
}
