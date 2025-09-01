import 'dart:io';
import 'dart:convert';
import '../models/tts_config.dart';

/// Configuration manager for TTS settings
/// 
/// Provides functionality to load and save TTS configuration from/to files,
/// with support for default configurations and custom file paths.
class ConfigManager {
  static const String _defaultConfigFile = 'tts_config.json';

  /// Load configuration from file
  /// 
  /// If the file doesn't exist, returns a default configuration.
  /// Throws [ConfigException] if the file exists but cannot be parsed.
  Future<TTSConfig> loadFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return const TTSConfig();
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return const TTSConfig();
      }

      final json = jsonDecode(content);
      if (json is! Map<String, dynamic>) {
        throw ConfigException('Configuration file must contain a JSON object');
      }

      final config = TTSConfig.fromJson(json);
      
      // Validate the loaded configuration
      final validationErrors = config.validate();
      if (validationErrors.isNotEmpty) {
        throw ConfigException(
          'Invalid configuration: ${validationErrors.join(', ')}'
        );
      }

      return config;
    } on ConfigException {
      rethrow;
    } catch (e) {
      throw ConfigException('Failed to load configuration from $filePath: $e');
    }
  }

  /// Save configuration to file
  /// 
  /// Creates the directory if it doesn't exist.
  /// Throws [ConfigException] if the configuration is invalid or cannot be saved.
  Future<void> saveToFile(TTSConfig config, String filePath) async {
    try {
      // Validate configuration before saving
      final validationErrors = config.validate();
      if (validationErrors.isNotEmpty) {
        throw ConfigException(
          'Cannot save invalid configuration: ${validationErrors.join(', ')}'
        );
      }

      final file = File(filePath);
      
      // Create directory if it doesn't exist
      final directory = file.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final json = jsonEncode(config.toJson());
      await file.writeAsString(json);
    } catch (e) {
      if (e is ConfigException) {
        rethrow;
      }
      throw ConfigException('Failed to save configuration to $filePath: $e');
    }
  }

  /// Load default configuration
  /// 
  /// Loads configuration from the default file location.
  /// If the file doesn't exist, returns a default configuration.
  Future<TTSConfig> loadDefault() async {
    return loadFromFile(_defaultConfigFile);
  }

  /// Save as default configuration
  /// 
  /// Saves configuration to the default file location.
  Future<void> saveDefault(TTSConfig config) async {
    return saveToFile(config, _defaultConfigFile);
  }

  /// Check if default configuration file exists
  Future<bool> hasDefaultConfig() async {
    final file = File(_defaultConfigFile);
    return file.exists();
  }

  /// Get the default configuration file path
  String get defaultConfigPath => _defaultConfigFile;

  /// Load configuration with fallback
  /// 
  /// Attempts to load from the specified path, falls back to default if not found,
  /// and finally falls back to built-in defaults if neither exists.
  Future<TTSConfig> loadWithFallback(String? customPath) async {
    if (customPath != null) {
      try {
        return await loadFromFile(customPath);
      } catch (e) {
        // Log the error but continue with fallback
      }
    }

    try {
      return await loadDefault();
    } catch (e) {
      // Log the error but continue with built-in defaults
      return const TTSConfig();
    }
  }

  /// Create a backup of the current configuration
  /// 
  /// Creates a timestamped backup file in the same directory as the original.
  Future<String> createBackup(String configPath) async {
    try {
      final originalFile = File(configPath);
      if (!await originalFile.exists()) {
        throw ConfigException('Configuration file $configPath does not exist');
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupPath = '${configPath}.backup.$timestamp';
      
      await originalFile.copy(backupPath);
      return backupPath;
    } catch (e) {
      throw ConfigException('Failed to create backup of $configPath: $e');
    }
  }

  /// Restore configuration from backup
  /// 
  /// Restores a configuration file from a backup.
  Future<void> restoreFromBackup(String backupPath, String targetPath) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw ConfigException('Backup file $backupPath does not exist');
      }

      // Validate the backup before restoring
      final config = await loadFromFile(backupPath);
      await saveToFile(config, targetPath);
    } catch (e) {
      throw ConfigException('Failed to restore from backup $backupPath: $e');
    }
  }

  /// Merge two configurations
  /// 
  /// Creates a new configuration by merging the base config with overrides.
  /// Non-null values in the override config take precedence.
  TTSConfig mergeConfigs(TTSConfig base, TTSConfig override) {
    return base.copyWith(
      defaultVoice: override.defaultVoice != base.defaultVoice ? override.defaultVoice : null,
      defaultFormat: override.defaultFormat != base.defaultFormat ? override.defaultFormat : null,
      defaultRate: override.defaultRate != base.defaultRate ? override.defaultRate : null,
      defaultPitch: override.defaultPitch != base.defaultPitch ? override.defaultPitch : null,
      defaultVolume: override.defaultVolume != base.defaultVolume ? override.defaultVolume : null,
      outputDirectory: override.outputDirectory != base.outputDirectory ? override.outputDirectory : null,
      enableCaching: override.enableCaching != base.enableCaching ? override.enableCaching : null,
      enablePlayback: override.enablePlayback != base.enablePlayback ? override.enablePlayback : null,
    );
  }
}

/// Exception thrown when configuration operations fail
class ConfigException implements Exception {
  final String message;
  
  const ConfigException(this.message);
  
  @override
  String toString() => 'ConfigException: $message';
}