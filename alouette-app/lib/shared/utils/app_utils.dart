import 'dart:io';
import 'package:flutter/foundation.dart';

class AppUtils {
  /// Print environment information for debugging (only on non-web platforms)
  static void printEnvironmentInfo() {
    if (!kIsWeb) {
      try {
        final home = Platform.environment['HOME'];
        final path = Platform.environment['PATH'];
        debugPrint('Environment variables:');
        debugPrint('HOME: $home');
        debugPrint('PATH: $path');
      } catch (e) {
        debugPrint('Cannot access environment variables: $e');
      }
    }
  }

  /// Check if the current platform is desktop
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// Check if the current platform is mobile
  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Check if the current platform is web
  static bool get isWeb => kIsWeb;
}