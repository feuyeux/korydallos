import 'package:flutter/material.dart';

/// Utility functions for the TTS application
class AppUtils {
  /// Show error snackbar
  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show success snackbar
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show info snackbar
  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Format voice display name
  static String formatVoiceName(String voiceId, String displayName) {
    if (displayName.isNotEmpty && displayName != voiceId) {
      return displayName;
    }
    
    // Clean up voice ID for display
    return voiceId
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  /// Format language code for display
  static String formatLanguageCode(String languageCode) {
    final parts = languageCode.split('-');
    if (parts.isEmpty) return languageCode;
    
    final language = parts[0].toUpperCase();
    if (parts.length > 1) {
      final region = parts[1].toUpperCase();
      return '$language-$region';
    }
    
    return language;
  }

  /// Validate text input
  static String? validateTextInput(String? text) {
    if (text == null || text.trim().isEmpty) {
      return 'Please enter some text to speak';
    }
    
    if (text.trim().length > 5000) {
      return 'Text is too long (maximum 5000 characters)';
    }
    
    return null;
  }

  /// Format parameter value for display
  static String formatParameterValue(double value, String unit) {
    switch (unit) {
      case 'x':
        return '${value.toStringAsFixed(1)}x';
      case '%':
        return '${(value * 100).toInt()}%';
      default:
        return value.toStringAsFixed(2);
    }
  }

  /// Get parameter divisions for slider
  static int getParameterDivisions(double min, double max, double step) {
    return ((max - min) / step).round();
  }
}