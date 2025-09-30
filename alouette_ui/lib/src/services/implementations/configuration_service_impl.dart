import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import '../interfaces/configuration_service_interface.dart';
import '../../models/app_configuration.dart';

/// Implementation of configuration management service
///
/// Provides persistent storage for application configuration using
/// SharedPreferences for simple settings and file storage for complex configurations.
class ConfigurationServiceImpl implements ConfigurationServiceInterface {
  static const String _configKey = 'alouette_app_configuration';
  static const String _configVersionKey = 'alouette_config_version';
  static const String _configFileName = 'alouette_config.json';
  static const String _currentVersion = '1.0.0';

  SharedPreferences? _prefs;
  AppConfiguration? _currentConfig;
  final StreamController<AppConfiguration> _configController =
      StreamController<AppConfiguration>.broadcast();

  @override
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      // Load existing configuration or create default
      if (await hasConfiguration()) {
        _currentConfig = await loadConfiguration();
      } else {
        _currentConfig = _createDefaultConfiguration();
        await saveConfiguration(_currentConfig!);
      }

      // Check for migration needs
      final storedVersion = await getConfigurationVersion();
      if (storedVersion != null && storedVersion != _currentVersion) {
        await _performMigration(storedVersion);
      }

      debugPrint(
        'ConfigurationService initialized with version $_currentVersion',
      );
    } catch (e) {
      debugPrint('Failed to initialize ConfigurationService: $e');
      _currentConfig = _createDefaultConfiguration();
    }
  }

  @override
  Future<AppConfiguration> loadConfiguration() async {
    try {
      // Try to load from file first (for complex configurations)
      final config = await _loadFromFile();
      if (config != null) {
        return config;
      }

      // Fallback to SharedPreferences
      return await _loadFromPreferences();
    } catch (e) {
      debugPrint('Failed to load configuration: $e');
      return _createDefaultConfiguration();
    }
  }

  @override
  Future<void> saveConfiguration(AppConfiguration config) async {
    try {
      // Validate before saving
      final validation = validateConfiguration(config);
      if (!(validation['isValid'] as bool)) {
        throw Exception(
          'Configuration validation failed: ${validation['errors']}',
        );
      }

      // Save to both storage methods for redundancy
      await _saveToFile(config);
      await _saveToPreferences(config);

      // Update current configuration and notify listeners
      _currentConfig = config;
      _configController.add(config);

      debugPrint('Configuration saved successfully');
    } catch (e) {
      debugPrint('Failed to save configuration: $e');
      rethrow;
    }
  }

  @override
  AppConfiguration get currentConfiguration {
    return _currentConfig ?? _createDefaultConfiguration();
  }

  @override
  Future<bool> updateConfiguration(AppConfiguration config) async {
    try {
      await saveConfiguration(config);
      return true;
    } catch (e) {
      debugPrint('Failed to update configuration: $e');
      return false;
    }
  }

  @override
  Future<void> resetToDefaults() async {
    try {
      final defaultConfig = _createDefaultConfiguration();
      await saveConfiguration(defaultConfig);
      debugPrint('Configuration reset to defaults');
    } catch (e) {
      debugPrint('Failed to reset configuration: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasConfiguration() async {
    try {
      // Check if file exists
      final file = await _getConfigFile();
      if (await file.exists()) {
        return true;
      }

      // Check SharedPreferences
      return _prefs?.containsKey(_configKey) ?? false;
    } catch (e) {
      debugPrint('Error checking configuration existence: $e');
      return false;
    }
  }

  @override
  Future<String?> getConfigurationVersion() async {
    try {
      return _prefs?.getString(_configVersionKey);
    } catch (e) {
      debugPrint('Error getting configuration version: $e');
      return null;
    }
  }

  @override
  Future<AppConfiguration> migrateConfiguration(
    Map<String, dynamic> oldConfig,
    String fromVersion,
    String toVersion,
  ) async {
    debugPrint('Migrating configuration from $fromVersion to $toVersion');

    try {
      // Version-specific migration logic
      Map<String, dynamic> migratedConfig = Map.from(oldConfig);

      // Migration from any version to 1.0.0
      if (toVersion == '1.0.0') {
        migratedConfig = _migrateTo1_0_0(migratedConfig);
      }

      // Update version
      migratedConfig['version'] = toVersion;
      migratedConfig['last_updated'] = DateTime.now().toIso8601String();

      final newConfig = AppConfiguration.fromJson(migratedConfig);
      await saveConfiguration(newConfig);

      debugPrint('Configuration migration completed successfully');
      return newConfig;
    } catch (e) {
      debugPrint('Configuration migration failed: $e');
      // Return default configuration if migration fails
      return _createDefaultConfiguration();
    }
  }

  @override
  Map<String, dynamic> validateConfiguration(AppConfiguration config) {
    return config.validate();
  }

  @override
  Map<String, dynamic> exportConfiguration() {
    return currentConfiguration.toJson();
  }

  @override
  Future<bool> importConfiguration(Map<String, dynamic> configJson) async {
    try {
      final config = AppConfiguration.fromJson(configJson);
      await saveConfiguration(config);
      return true;
    } catch (e) {
      debugPrint('Failed to import configuration: $e');
      return false;
    }
  }

  @override
  Stream<AppConfiguration> get configurationStream => _configController.stream;

  @override
  void dispose() {
    _configController.close();
  }

  // Private helper methods

  AppConfiguration _createDefaultConfiguration() {
    return AppConfiguration(
      uiPreferences: const UIPreferences(
        themeMode: 'system',
        primaryLanguage: 'en',
        fontScale: 1.0,
        showAdvancedOptions: false,
        enableAnimations: true,
      ),
      appSettings: {
        'first_launch': true,
        'analytics_enabled': false,
        'auto_save': true,
        'backup_enabled': true,
      },
      version: _currentVersion,
    );
  }

  Future<File> _getConfigFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final configDir = Directory('${directory.path}/alouette');

    // Create directory if it doesn't exist
    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }

    return File('${configDir.path}/$_configFileName');
  }

  Future<AppConfiguration?> _loadFromFile() async {
    try {
      final file = await _getConfigFile();
      if (!await file.exists()) {
        return null;
      }

      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return AppConfiguration.fromJson(jsonData);
    } catch (e) {
      debugPrint('Failed to load configuration from file: $e');
      return null;
    }
  }

  Future<AppConfiguration> _loadFromPreferences() async {
    try {
      final configString = _prefs?.getString(_configKey);
      if (configString == null) {
        return _createDefaultConfiguration();
      }

      final jsonData = json.decode(configString) as Map<String, dynamic>;
      return AppConfiguration.fromJson(jsonData);
    } catch (e) {
      debugPrint('Failed to load configuration from preferences: $e');
      return _createDefaultConfiguration();
    }
  }

  Future<void> _saveToFile(AppConfiguration config) async {
    try {
      final file = await _getConfigFile();
      final jsonString = json.encode(config.toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint('Failed to save configuration to file: $e');
      // Don't rethrow - file storage is secondary
    }
  }

  Future<void> _saveToPreferences(AppConfiguration config) async {
    try {
      final jsonString = json.encode(config.toJson());
      await _prefs?.setString(_configKey, jsonString);
      await _prefs?.setString(_configVersionKey, config.version);
    } catch (e) {
      debugPrint('Failed to save configuration to preferences: $e');
      rethrow; // This is critical storage
    }
  }

  Future<void> _performMigration(String fromVersion) async {
    try {
      debugPrint(
        'Performing configuration migration from $fromVersion to $_currentVersion',
      );

      // Load old configuration
      final oldConfigString = _prefs?.getString(_configKey);
      if (oldConfigString == null) {
        return;
      }

      final oldConfigJson =
          json.decode(oldConfigString) as Map<String, dynamic>;

      // Perform migration
      final migratedConfig = await migrateConfiguration(
        oldConfigJson,
        fromVersion,
        _currentVersion,
      );

      _currentConfig = migratedConfig;
    } catch (e) {
      debugPrint('Migration failed, using default configuration: $e');
      _currentConfig = _createDefaultConfiguration();
      await saveConfiguration(_currentConfig!);
    }
  }

  Map<String, dynamic> _migrateTo1_0_0(Map<String, dynamic> oldConfig) {
    final migratedConfig = Map<String, dynamic>.from(oldConfig);

    // Ensure all required fields exist with defaults
    migratedConfig['version'] = '1.0.0';

    // Migrate UI preferences if they exist in old format
    if (migratedConfig['ui_preferences'] == null) {
      migratedConfig['ui_preferences'] = {
        'theme_mode': 'system',
        'primary_language': 'en',
        'font_scale': 1.0,
        'show_advanced_options': false,
        'enable_animations': true,
      };
    }

    // Ensure app_settings exists
    if (migratedConfig['app_settings'] == null) {
      migratedConfig['app_settings'] = {
        'first_launch': false, // Not first launch if migrating
        'analytics_enabled': false,
        'auto_save': true,
        'backup_enabled': true,
      };
    }

    return migratedConfig;
  }
}
