import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/services.dart';

import '../interfaces/i_platform_detector.dart';
import '../enums/tts_platform.dart';

/// Concrete implementation of platform detection and capability checking
class PlatformDetector implements IPlatformDetector {
  static const MethodChannel _channel = MethodChannel('alouette_tts');

  // Cache for platform capabilities to avoid repeated expensive operations
  Map<String, dynamic>? _cachedCapabilities;
  TTSPlatform? _cachedPlatform;

  @override
  TTSPlatform getCurrentPlatform() {
    if (_cachedPlatform != null) {
      return _cachedPlatform!;
    }

    debugPrint('PlatformDetector: Detecting current platform...');

    if (kIsWeb) {
      debugPrint('PlatformDetector: Detected Web platform');
      _cachedPlatform = TTSPlatform.web;
    } else if (Platform.isAndroid) {
      debugPrint('PlatformDetector: Detected Android platform');
      _cachedPlatform = TTSPlatform.android;
    } else if (Platform.isIOS) {
      debugPrint('PlatformDetector: Detected iOS platform');
      _cachedPlatform = TTSPlatform.ios;
    } else if (Platform.isLinux) {
      debugPrint('PlatformDetector: Detected Linux platform');
      _cachedPlatform = TTSPlatform.linux;
    } else if (Platform.isMacOS) {
      debugPrint('PlatformDetector: Detected macOS platform');
      _cachedPlatform = TTSPlatform.macos;
    } else if (Platform.isWindows) {
      debugPrint('PlatformDetector: Detected Windows platform');
      _cachedPlatform = TTSPlatform.windows;
    } else {
      debugPrint('PlatformDetector: Unknown platform, falling back to Web');
      _cachedPlatform = TTSPlatform.web;
    }

    return _cachedPlatform!;
  }

  @override
  bool isDesktopPlatform() {
    return getCurrentPlatform().isDesktop;
  }

  @override
  bool isMobilePlatform() {
    return getCurrentPlatform().isMobile;
  }

  @override
  bool isWebPlatform() {
    return getCurrentPlatform().isWeb;
  }

  @override
  Future<bool> isEdgeTTSAvailable() async {
    debugPrint('PlatformDetector: Checking Edge TTS availability...');

    // Edge TTS is only available on desktop platforms
    if (!isDesktopPlatform()) {
      debugPrint(
          'PlatformDetector: Not a desktop platform, Edge TTS not available');
      return false;
    }

    try {
      // Try to invoke platform-specific method to check edge-tts availability
      debugPrint('PlatformDetector: Attempting platform method check...');
      final result = await _channel.invokeMethod<bool>('isEdgeTTSAvailable');
      debugPrint(
          'PlatformDetector: Platform method result: ${result ?? false}');
      return result ?? false;
    } catch (e) {
      // If platform channel fails, try alternative detection methods
      debugPrint(
          'PlatformDetector: Platform method failed, falling back to detection: $e');
      return await _fallbackEdgeTTSDetection();
    }
  }

  /// Fallback method to detect Edge TTS availability without platform channels
  Future<bool> _fallbackEdgeTTSDetection() async {
    debugPrint('PlatformDetector: Running fallback Edge TTS detection...');

    try {
      // Check if edge-tts command is available on the system
      if (!isDesktopPlatform()) {
        debugPrint(
            'PlatformDetector: Not a desktop platform in fallback check');
        return false;
      }

      // On macOS, check in Python virtual environment
      if (Platform.isMacOS) {
        debugPrint(
            'PlatformDetector: Checking Edge TTS in macOS virtual environment...');
        try {
          // First try the virtual environment python
          final result =
              await Process.run('python3', ['-m', 'edge_tts', '--help']);
          final isAvailable = result.exitCode == 0;
          debugPrint(
              'PlatformDetector: Edge TTS ${isAvailable ? "is" : "is not"} available in virtual environment');
          if (!isAvailable) {
            debugPrint(
                'PlatformDetector: Command failed with error: ${result.stderr}');
          }
          return isAvailable;
        } catch (e) {
          debugPrint(
              'PlatformDetector: Failed to run Edge TTS in virtual environment: $e');
          return false;
        }
      }

      // On Windows, use 'where' instead of 'which'
      if (Platform.isWindows) {
        final result = await Process.run('where', ['edge-tts']);
        return result.exitCode == 0;
      } else {
        final result = await Process.run('which', ['edge-tts']);
        return result.exitCode == 0;
      }
    } catch (e) {
      // Try alternative check - run the command with --help
      try {
        final result = await Process.run('edge-tts', ['--help']);
        return result.exitCode == 0;
      } catch (e) {
        return false;
      }
    }
  }

  @override
  Future<List<String>> getAvailableTTSEngines() async {
    final platform = getCurrentPlatform();
    final engines = <String>[];

    // Flutter TTS is only advertised for non-desktop platforms (mobile/web).
    // All desktop platforms (Linux, macOS, Windows) should prefer edge-tts.
    if (!platform.isDesktop) {
      engines.add('flutter-tts');
    }

    // Add edge-tts when available (desktop platforms). On Linux this will be the
    // preferred (and required) implementation.
    if (platform.isDesktop && await isEdgeTTSAvailable()) {
      engines.add('edge-tts');
    }

    // Add platform-specific engines
    try {
      final platformEngines =
          await _channel.invokeMethod<List<dynamic>>('getAvailableTTSEngines');
      if (platformEngines != null) {
        engines.addAll(platformEngines.cast<String>());
      }
    } catch (e) {
      // Ignore platform channel errors and continue with basic engines
    }

    return engines;
  }

  @override
  Map<String, dynamic> getPlatformCapabilities() {
    if (_cachedCapabilities != null) {
      return Map<String, dynamic>.from(_cachedCapabilities!);
    }

    final platform = getCurrentPlatform();
    final capabilities = <String, dynamic>{};

    // Set capabilities based on platform
    switch (platform) {
      case TTSPlatform.android:
        capabilities.addAll(_getAndroidCapabilities());
        break;
      case TTSPlatform.ios:
        capabilities.addAll(_getIOSCapabilities());
        break;
      case TTSPlatform.linux:
      case TTSPlatform.macos:
      case TTSPlatform.windows:
        capabilities.addAll(_getDesktopCapabilities());
        break;
      case TTSPlatform.web:
        capabilities.addAll(_getWebCapabilities());
        break;
    }

    _cachedCapabilities = capabilities;
    return Map<String, dynamic>.from(capabilities);
  }

  Map<String, dynamic> _getAndroidCapabilities() {
    return {
      'supportsSSML': true,
      'supportsPause': true,
      'supportsVolumeControl': true,
      'supportsPitchControl': true,
      'supportsRateControl': true,
      'maxTextLength': 4000,
      'supportedFormats': ['wav', 'mp3'],
      'supportsFileOutput': true,
      'supportsBatchProcessing': true,
      'supportsVoiceSelection': true,
      'supportsLanguageDetection': false,
    };
  }

  Map<String, dynamic> _getIOSCapabilities() {
    return {
      'supportsSSML': true,
      'supportsPause': true,
      'supportsVolumeControl': true,
      'supportsPitchControl': true,
      'supportsRateControl': true,
      'maxTextLength': 4000,
      'supportedFormats': ['wav', 'mp3'],
      'supportsFileOutput': true,
      'supportsBatchProcessing': true,
      'supportsVoiceSelection': true,
      'supportsLanguageDetection': false,
    };
  }

  Map<String, dynamic> _getDesktopCapabilities() {
    return {
      'supportsSSML': true,
      'supportsPause': true,
      'supportsVolumeControl': true,
      'supportsPitchControl': true,
      'supportsRateControl': true,
      'maxTextLength': 10000, // Edge TTS supports longer texts
      'supportedFormats': ['wav', 'mp3', 'ogg'],
      'supportsFileOutput': true,
      'supportsBatchProcessing': true,
      'supportsVoiceSelection': true,
      'supportsLanguageDetection': true,
      'supportsConnectionPooling': true, // Edge TTS specific
      'supportsWebSocketConnection': true, // Edge TTS specific
    };
  }

  Map<String, dynamic> _getWebCapabilities() {
    return {
      'supportsSSML': false, // Web Speech API has limited SSML support
      'supportsPause': true,
      'supportsVolumeControl': true,
      'supportsPitchControl': true,
      'supportsRateControl': true,
      'maxTextLength': 2000, // Web Speech API limitations
      'supportedFormats': ['wav'], // Limited format support on web
      'supportsFileOutput': false, // File system access limitations
      'supportsBatchProcessing': false, // Limited by browser constraints
      'supportsVoiceSelection': true,
      'supportsLanguageDetection': false,
    };
  }

  @override
  Future<String> getPlatformVersion() async {
    try {
      final version = await _channel.invokeMethod<String>('getPlatformVersion');
      return version ?? 'Unknown';
    } catch (e) {
      // Fallback to basic platform information
      if (kIsWeb) {
        return 'Web';
      } else {
        return Platform.operatingSystemVersion;
      }
    }
  }

  @override
  bool isFeatureSupported(String feature) {
    final capabilities = getPlatformCapabilities();

    switch (feature.toLowerCase()) {
      case 'ssml':
        return capabilities['supportsSSML'] ?? false;
      case 'pause':
        return capabilities['supportsPause'] ?? false;
      case 'volume':
        return capabilities['supportsVolumeControl'] ?? false;
      case 'pitch':
        return capabilities['supportsPitchControl'] ?? false;
      case 'rate':
        return capabilities['supportsRateControl'] ?? false;
      case 'fileoutput':
        return capabilities['supportsFileOutput'] ?? false;
      case 'batch':
        return capabilities['supportsBatchProcessing'] ?? false;
      case 'voiceselection':
        return capabilities['supportsVoiceSelection'] ?? false;
      case 'languagedetection':
        return capabilities['supportsLanguageDetection'] ?? false;
      case 'connectionpooling':
        return capabilities['supportsConnectionPooling'] ?? false;
      case 'websocket':
        return capabilities['supportsWebSocketConnection'] ?? false;
      default:
        return false;
    }
  }

  @override
  String getRecommendedTTSImplementation() {
    final platform = getCurrentPlatform();

    if (platform.isDesktop) {
      return 'edge-tts';
    } else {
      return 'flutter-tts';
    }
  }

  /// Clears the cached platform information
  /// Useful for testing or when platform capabilities might change
  void clearCache() {
    _cachedCapabilities = null;
    _cachedPlatform = null;
  }
}
