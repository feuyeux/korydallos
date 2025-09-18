import 'dart:io';
import 'package:flutter/foundation.dart';
import '../enums/tts_engine_type.dart';

/// Platform detector utility for automatic platform detection
/// Provides platform-specific information and recommendations
class PlatformDetector {
  /// Get the current platform name
  String get platformName {
    if (kIsWeb) return 'web';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  /// Check if current platform is desktop
  bool get isDesktop {
    return !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  }

  /// Check if current platform is mobile
  bool get isMobile {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }

  /// Check if current platform is web
  bool get isWeb => kIsWeb;

  /// Check if platform supports process execution
  bool get supportsProcessExecution {
    return !kIsWeb && isDesktop;
  }

  /// Check if platform supports file system operations
  bool get supportsFileSystem {
    return !kIsWeb;
  }

  /// Check if Flutter TTS is supported on this platform
  bool get isFlutterTTSSupported {
    // Flutter TTS is supported on all platforms
    return true;
  }

  /// Get recommended TTS engine for current platform
  TTSEngineType getRecommendedEngine() {
    if (isDesktop && supportsProcessExecution) {
      // Desktop platforms prefer Edge TTS for better quality
      return TTSEngineType.edge;
    }
    // Mobile and web platforms use Flutter TTS
    return TTSEngineType.flutter;
  }

  /// Get platform-specific information
  Map<String, dynamic> getPlatformInfo() {
    return {
      'platform': platformName,
      'isDesktop': isDesktop,
      'isMobile': isMobile,
      'isWeb': isWeb,
      'supportsProcessExecution': supportsProcessExecution,
      'supportsFileSystem': supportsFileSystem,
      'isFlutterTTSSupported': isFlutterTTSSupported,
    };
  }

  /// Get platform-specific TTS strategy
  TTSStrategy getTTSStrategy() {
    if (isDesktop) {
      return DesktopTTSStrategy();
    } else if (isMobile) {
      return MobileTTSStrategy();
    } else if (isWeb) {
      return WebTTSStrategy();
    }
    return MobileTTSStrategy(); // Default fallback
  }

  /// Get fallback engines in order of preference for current platform
  List<TTSEngineType> getFallbackEngines() {
    final strategy = getTTSStrategy();
    return strategy.getFallbackEngines();
  }
}

/// Abstract TTS strategy for platform-specific implementations
abstract class TTSStrategy {
  /// Get the preferred engine for this platform
  TTSEngineType get preferredEngine;
  
  /// Get fallback engines in order of preference
  List<TTSEngineType> getFallbackEngines();
  
  /// Check if engine is supported on this platform
  bool isEngineSupported(TTSEngineType engine);
  
  /// Get platform-specific engine configuration
  Map<String, dynamic> getEngineConfig(TTSEngineType engine);
}

/// Desktop TTS strategy - prefers Edge TTS with Flutter TTS fallback
class DesktopTTSStrategy implements TTSStrategy {
  @override
  TTSEngineType get preferredEngine => TTSEngineType.edge;
  
  @override
  List<TTSEngineType> getFallbackEngines() {
    return [TTSEngineType.edge, TTSEngineType.flutter];
  }
  
  @override
  bool isEngineSupported(TTSEngineType engine) {
    switch (engine) {
      case TTSEngineType.edge:
        return true; // Edge TTS can be installed on desktop
      case TTSEngineType.flutter:
        return true; // Flutter TTS works on desktop
    }
  }
  
  @override
  Map<String, dynamic> getEngineConfig(TTSEngineType engine) {
    switch (engine) {
      case TTSEngineType.edge:
        return {
          'quality': 'high',
          'format': 'mp3',
          'timeout': 30000,
        };
      case TTSEngineType.flutter:
        return {
          'quality': 'standard',
          'useSystemVoices': true,
        };
    }
  }
}

/// Mobile TTS strategy - uses Flutter TTS exclusively
class MobileTTSStrategy implements TTSStrategy {
  @override
  TTSEngineType get preferredEngine => TTSEngineType.flutter;
  
  @override
  List<TTSEngineType> getFallbackEngines() {
    return [TTSEngineType.flutter]; // Only Flutter TTS on mobile
  }
  
  @override
  bool isEngineSupported(TTSEngineType engine) {
    switch (engine) {
      case TTSEngineType.edge:
        return false; // Edge TTS not available on mobile
      case TTSEngineType.flutter:
        return true; // Flutter TTS is native on mobile
    }
  }
  
  @override
  Map<String, dynamic> getEngineConfig(TTSEngineType engine) {
    switch (engine) {
      case TTSEngineType.edge:
        return {}; // Not supported
      case TTSEngineType.flutter:
        return {
          'quality': 'standard',
          'useSystemVoices': true,
          'optimizeForMobile': true,
        };
    }
  }
}

/// Web TTS strategy - uses Flutter TTS with web optimizations
class WebTTSStrategy implements TTSStrategy {
  @override
  TTSEngineType get preferredEngine => TTSEngineType.flutter;
  
  @override
  List<TTSEngineType> getFallbackEngines() {
    return [TTSEngineType.flutter]; // Only Flutter TTS on web
  }
  
  @override
  bool isEngineSupported(TTSEngineType engine) {
    switch (engine) {
      case TTSEngineType.edge:
        return false; // Edge TTS not available on web
      case TTSEngineType.flutter:
        return true; // Flutter TTS uses Web Speech API
    }
  }
  
  @override
  Map<String, dynamic> getEngineConfig(TTSEngineType engine) {
    switch (engine) {
      case TTSEngineType.edge:
        return {}; // Not supported
      case TTSEngineType.flutter:
        return {
          'quality': 'standard',
          'useWebSpeechAPI': true,
          'optimizeForWeb': true,
        };
    }
  }
}