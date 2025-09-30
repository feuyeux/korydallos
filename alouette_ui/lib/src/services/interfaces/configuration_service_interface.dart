import '../../../alouette_ui.dart';

/// Interface for configuration management services
///
/// Defines the contract for managing application configuration,
/// user preferences, and persistent storage across all Alouette applications.
abstract class ConfigurationServiceInterface {
  /// Initialize the configuration service
  Future<void> initialize();

  /// Load configuration from persistent storage
  Future<AppConfiguration> loadConfiguration();

  /// Save configuration to persistent storage
  Future<void> saveConfiguration(AppConfiguration config);

  /// Get current configuration
  AppConfiguration get currentConfiguration;

  /// Update configuration with validation
  Future<bool> updateConfiguration(AppConfiguration config);

  /// Reset configuration to defaults
  Future<void> resetToDefaults();

  /// Check if configuration exists
  Future<bool> hasConfiguration();

  /// Get configuration version for migration
  Future<String?> getConfigurationVersion();

  /// Migrate configuration from older version
  Future<AppConfiguration> migrateConfiguration(
    Map<String, dynamic> oldConfig,
    String fromVersion,
    String toVersion,
  );

  /// Validate configuration
  Map<String, dynamic> validateConfiguration(AppConfiguration config);

  /// Export configuration to JSON
  Map<String, dynamic> exportConfiguration();

  /// Import configuration from JSON
  Future<bool> importConfiguration(Map<String, dynamic> configJson);

  /// Stream of configuration changes
  Stream<AppConfiguration> get configurationStream;

  /// Dispose resources
  void dispose();
}
