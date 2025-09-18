import 'package:flutter/foundation.dart';
import '../models/tts_config.dart';
import '../models/tts_error.dart';
import '../utils/config_validator.dart';
import '../exceptions/tts_exceptions.dart';
import 'config_manager.dart';

/// Service for managing TTS configuration
/// 
/// Provides configuration management with reactive updates,
/// validation, and persistence capabilities.
class TTSConfigService extends ChangeNotifier {
  final ConfigManager _configManager;
  TTSConfig _currentConfig = const TTSConfig();
  bool _isLoading = false;
  bool _isDirty = false;
  TTSConfigValidator? _validator;
  ValidationResult? _lastValidationResult;

  /// Notifier for configuration loading state
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  /// Notifier for configuration dirty state
  final ValueNotifier<bool> isDirtyNotifier = ValueNotifier<bool>(false);

  TTSConfigService({ConfigManager? configManager})
      : _configManager = configManager ?? ConfigManager();

  /// Get current configuration
  TTSConfig get currentConfig => _currentConfig;

  /// Check if configuration is being loaded
  bool get isLoading => _isLoading;

  /// Check if configuration has unsaved changes
  bool get isDirty => _isDirty;

  /// Load configuration from file
  Future<void> loadConfig([String? filePath]) async {
    _setLoading(true);

    try {
      if (filePath != null) {
        _currentConfig = await _configManager.loadFromFile(filePath);
      } else {
        _currentConfig = await _configManager.loadDefault();
      }
      
      _setDirty(false);
      notifyListeners();
    } catch (e) {
      throw TTSError(
        'Failed to load TTS configuration: $e',
        code: TTSErrorCodes.configurationError,
        originalError: e,
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Save configuration to file
  Future<void> saveConfig([String? filePath]) async {
    _setLoading(true);

    try {
      if (filePath != null) {
        await _configManager.saveToFile(_currentConfig, filePath);
      } else {
        await _configManager.saveDefault(_currentConfig);
      }
      
      _setDirty(false);
      notifyListeners();
    } catch (e) {
      throw TTSError(
        'Failed to save TTS configuration: $e',
        code: TTSErrorCodes.configurationError,
        originalError: e,
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Load configuration with fallback
  Future<void> loadWithFallback([String? customPath]) async {
    _setLoading(true);

    try {
      _currentConfig = await _configManager.loadWithFallback(customPath);
      _setDirty(false);
      notifyListeners();
    } catch (e) {
      throw TTSError(
        'Failed to load TTS configuration with fallback: $e',
        code: TTSErrorCodes.configurationError,
        originalError: e,
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Update configuration
  void updateConfig(TTSConfig newConfig) {
    if (_currentConfig != newConfig) {
      _currentConfig = newConfig;
      _setDirty(true);
      _validateCurrentConfig();
      notifyListeners();
    }
  }

  /// Update specific configuration field
  void updateField<T>(String fieldName, T value) {
    late TTSConfig updatedConfig;

    switch (fieldName) {
      case 'defaultVoice':
        updatedConfig = _currentConfig.copyWith(defaultVoice: value as String?);
        break;
      case 'defaultFormat':
        updatedConfig = _currentConfig.copyWith(defaultFormat: value as String?);
        break;
      case 'defaultRate':
        updatedConfig = _currentConfig.copyWith(defaultRate: value as double?);
        break;
      case 'defaultPitch':
        updatedConfig = _currentConfig.copyWith(defaultPitch: value as double?);
        break;
      case 'defaultVolume':
        updatedConfig = _currentConfig.copyWith(defaultVolume: value as double?);
        break;
      case 'outputDirectory':
        updatedConfig = _currentConfig.copyWith(outputDirectory: value as String?);
        break;
      case 'enableCaching':
        updatedConfig = _currentConfig.copyWith(enableCaching: value as bool?);
        break;
      case 'enablePlayback':
        updatedConfig = _currentConfig.copyWith(enablePlayback: value as bool?);
        break;
      default:
        throw TTSError(
          'Unknown configuration field: $fieldName',
          code: TTSErrorCodes.configurationError,
        );
    }

    updateConfig(updatedConfig);
  }

  /// Reset to default configuration
  void resetToDefaults() {
    updateConfig(const TTSConfig());
  }

  /// Validate current configuration using enhanced validator
  ValidationResult validateCurrentConfig() {
    return _validateCurrentConfig();
  }
  
  /// Internal validation method
  ValidationResult _validateCurrentConfig() {
    if (_validator != null) {
      _lastValidationResult = _validator!.validateConfig(_currentConfig);
    } else {
      // Fallback to basic validation if no validator is set
      final errors = _currentConfig.validate();
      _lastValidationResult = errors.isEmpty 
          ? ValidationResult.valid()
          : ValidationResult.invalid(errors);
    }
    return _lastValidationResult!;
  }

  /// Check if current configuration is valid
  bool get isValid {
    final result = _lastValidationResult ?? _validateCurrentConfig();
    return result.isValid;
  }
  
  /// Get validation errors
  List<String> get validationErrors {
    final result = _lastValidationResult ?? _validateCurrentConfig();
    return result.errors;
  }
  
  /// Get validation warnings
  List<String> get validationWarnings {
    final result = _lastValidationResult ?? _validateCurrentConfig();
    return result.warnings;
  }
  
  /// Get validation suggestions
  List<String> get validationSuggestions {
    final result = _lastValidationResult ?? _validateCurrentConfig();
    return result.suggestions;
  }

  /// Get configuration summary with enhanced validation info
  Map<String, dynamic> getConfigSummary() {
    final validationResult = _validateCurrentConfig();
    
    return {
      'hasDefaultVoice': _currentConfig.defaultVoice.isNotEmpty,
      'defaultVoice': _currentConfig.defaultVoice,
      'defaultFormat': _currentConfig.defaultFormat,
      'defaultRate': _currentConfig.defaultRate,
      'defaultPitch': _currentConfig.defaultPitch,
      'defaultVolume': _currentConfig.defaultVolume,
      'outputDirectory': _currentConfig.outputDirectory,
      'enableCaching': _currentConfig.enableCaching,
      'enablePlayback': _currentConfig.enablePlayback,
      'isValid': validationResult.isValid,
      'isDirty': _isDirty,
      'validationErrors': validationResult.errors,
      'validationWarnings': validationResult.warnings,
      'validationSuggestions': validationResult.suggestions,
      'hasValidator': _validator != null,
    };
  }

  /// Create backup of current configuration
  Future<String> createBackup([String? configPath]) async {
    try {
      final path = configPath ?? _configManager.defaultConfigPath;
      return await _configManager.createBackup(path);
    } catch (e) {
      throw TTSError(
        'Failed to create configuration backup: $e',
        code: TTSErrorCodes.configurationError,
        originalError: e,
      );
    }
  }

  /// Restore configuration from backup
  Future<void> restoreFromBackup(String backupPath, [String? targetPath]) async {
    _setLoading(true);

    try {
      final target = targetPath ?? _configManager.defaultConfigPath;
      await _configManager.restoreFromBackup(backupPath, target);
      await loadConfig(target);
    } catch (e) {
      throw TTSError(
        'Failed to restore configuration from backup: $e',
        code: TTSErrorCodes.configurationError,
        originalError: e,
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Merge with another configuration
  void mergeWith(TTSConfig otherConfig) {
    final merged = _configManager.mergeConfigs(_currentConfig, otherConfig);
    updateConfig(merged);
  }

  /// Export configuration as JSON string
  String exportAsJson() {
    return _currentConfig.toJsonString();
  }

  /// Import configuration from JSON string
  void importFromJson(String jsonString) {
    try {
      final config = TTSConfig.fromJsonString(jsonString);
      updateConfig(config);
    } catch (e) {
      throw TTSError(
        'Failed to import configuration from JSON: $e',
        code: TTSErrorCodes.configurationError,
        originalError: e,
      );
    }
  }

  /// Check if default configuration file exists
  Future<bool> hasDefaultConfig() async {
    return await _configManager.hasDefaultConfig();
  }

  /// Get default configuration file path
  String get defaultConfigPath => _configManager.defaultConfigPath;
  
  /// Generate configuration recommendations
  List<String> getRecommendations() {
    if (_validator != null) {
      return _validator!.generateRecommendations(_currentConfig);
    }
    return [];
  }
  
  /// Perform quick validation (basic checks only)
  bool quickValidate() {
    if (_validator != null) {
      final result = _validator!.quickValidate(_currentConfig);
      return result.isValid;
    }
    return _currentConfig.validate().isEmpty;
  }

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      isLoadingNotifier.value = loading;
    }
  }

  /// Set dirty state
  void _setDirty(bool dirty) {
    if (_isDirty != dirty) {
      _isDirty = dirty;
      isDirtyNotifier.value = dirty;
    }
  }

  /// Discard unsaved changes
  void discardChanges() {
    if (_isDirty) {
      // Reload from last saved state
      loadConfig().catchError((e) {
        // If loading fails, reset to defaults
        resetToDefaults();
      });
    }
  }

  /// Auto-save configuration if dirty
  Future<void> autoSave() async {
    if (_isDirty && isValid) {
      await saveConfig();
    }
  }

  @override
  void dispose() {
    isLoadingNotifier.dispose();
    isDirtyNotifier.dispose();
    super.dispose();
  }
}