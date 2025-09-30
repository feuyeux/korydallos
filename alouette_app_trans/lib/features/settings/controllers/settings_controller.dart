import 'package:flutter/material.dart';

class SettingsController extends ChangeNotifier {
  bool _darkMode = false;
  bool _autoSave = true;
  bool _showNotifications = true;
  double _fontSize = 14.0;
  String _language = 'en';

  // Getters
  bool get darkMode => _darkMode;
  bool get autoSave => _autoSave;
  bool get showNotifications => _showNotifications;
  double get fontSize => _fontSize;
  String get language => _language;

  /// Initialize settings from storage
  Future<void> initialize() async {
    // Load settings from persistent storage would be implemented here
    notifyListeners();
  }

  /// Update dark mode setting
  void setDarkMode(bool value) {
    _darkMode = value;
    _saveSettings();
    notifyListeners();
  }

  /// Update auto-save setting
  void setAutoSave(bool value) {
    _autoSave = value;
    _saveSettings();
    notifyListeners();
  }

  /// Update notifications setting
  void setShowNotifications(bool value) {
    _showNotifications = value;
    _saveSettings();
    notifyListeners();
  }

  /// Update font size setting
  void setFontSize(double value) {
    _fontSize = value;
    _saveSettings();
    notifyListeners();
  }

  /// Update language setting
  void setLanguage(String value) {
    _language = value;
    _saveSettings();
    notifyListeners();
  }

  /// Save settings to persistent storage
  Future<void> _saveSettings() async {
    // Persistent storage implementation would go here
    // Could use SharedPreferences, Hive, or another storage solution
  }

  /// Export settings to a file
  Future<Map<String, dynamic>> exportSettings() async {
    return {
      'darkMode': _darkMode,
      'autoSave': _autoSave,
      'showNotifications': _showNotifications,
      'fontSize': _fontSize,
      'language': _language,
    };
  }

  /// Import settings from a map
  Future<void> importSettings(Map<String, dynamic> settings) async {
    _darkMode = settings['darkMode'] ?? _darkMode;
    _autoSave = settings['autoSave'] ?? _autoSave;
    _showNotifications = settings['showNotifications'] ?? _showNotifications;
    _fontSize = settings['fontSize'] ?? _fontSize;
    _language = settings['language'] ?? _language;

    await _saveSettings();
    notifyListeners();
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    _darkMode = false;
    _autoSave = true;
    _showNotifications = true;
    _fontSize = 14.0;
    _language = 'en';

    await _saveSettings();
    notifyListeners();
  }
}
