import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:alouette_lib_tts/alouette_tts.dart';
import 'alouette_logo.dart';

class AlouetteAppBar extends StatefulWidget implements PreferredSizeWidget {
  final TTSEngineType? currentEngine;
  final bool ttsInitialized;

  const AlouetteAppBar({
    super.key,
    this.currentEngine,
    this.ttsInitialized = false,
  });

  @override
  State<AlouetteAppBar> createState() => _AlouetteAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AlouetteAppBarState extends State<AlouetteAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      title: Row(
        children: [
          // Alouette title
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
          AlouetteLogo.circleAvatar(
            radius: 16,
            backgroundColor: Colors.white,
          ),

          const Spacer(),

          // System info
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
    if (!widget.ttsInitialized) return 'Loading...';

    switch (widget.currentEngine) {
      case TTSEngineType.edge:
        return 'Edge TTS';
      case TTSEngineType.flutter:
        return 'Flutter TTS';
      case null:
        return 'TTS N/A';
    }
  }

  IconData _getTTSEngineIcon() {
    switch (widget.currentEngine) {
      case TTSEngineType.edge:
        return Icons.cloud;
      case TTSEngineType.flutter:
        return Icons.phone_android;
      case null:
        return Icons.record_voice_over;
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
      return Icons.devices;
    }
    return Icons.devices;
  }
}
