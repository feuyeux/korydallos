# Centralized Configuration Management

This document describes the centralized configuration management system implemented in the Alouette UI Shared library. This system provides unified configuration storage, validation, and migration capabilities for all Alouette applications.

## Overview

The configuration management system consists of several key components:

- **ConfigurationManager**: High-level API for configuration management
- **ConfigurationServiceInterface**: Abstract interface for configuration services
- **ConfigurationServiceImpl**: Implementation using SharedPreferences and file storage
- **AppConfiguration**: Unified data model for all configuration data
- **ConfigurationMigration**: Handles version upgrades and data migration
- **Configuration Widgets**: UI components for managing settings

## Features

- ✅ **Persistent Storage**: Uses both SharedPreferences and file storage for redundancy
- ✅ **Validation**: Comprehensive validation with error and warning reporting
- ✅ **Migration**: Automatic migration between configuration versions
- ✅ **Type Safety**: Strongly typed configuration models with validation
- ✅ **Reactive Updates**: Stream-based configuration change notifications
- ✅ **Export/Import**: Configuration backup and restore capabilities
- ✅ **UI Components**: Ready-to-use widgets for configuration management
- ✅ **Service Integration**: Seamless integration with the service locator pattern

## Quick Start

### 1. Initialize Configuration Manager

In your application's `main()` function:

```dart
import 'package:alouette_ui_shared/alouette_ui_shared.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize configuration manager
  await ConfigurationManager.instance.initialize();
  
  // Register with service locator (optional)
  ServiceLocator.register<ConfigurationManager>(ConfigurationManager.instance);
  
  runApp(MyApp());
}
```

### 2. Use Configuration in Your App

```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ConfigurationManager _configManager = ConfigurationManager.instance;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    
    // Listen to configuration changes
    _configManager.configurationStream.listen((config) {
      _updateThemeMode(config.uiPreferences.themeMode);
    });
  }

  Future<void> _loadThemeMode() async {
    final themeMode = await _configManager.getThemeMode();
    _updateThemeMode(themeMode);
  }

  void _updateThemeMode(String themeModeString) {
    setState(() {
      switch (themeModeString) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: _themeMode,
      // ... rest of your app
    );
  }
}
```

### 3. Add Configuration UI

```dart
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Column(
        children: [
          // Configuration status
          ConfigurationStatusWidget(showDetails: true),
          
          SizedBox(height: 16),
          
          // Configuration panel
          Expanded(
            child: ConfigurationPanel(showAdvanced: true),
          ),
        ],
      ),
    );
  }
}
```

## Configuration API

### Basic Configuration Operations

```dart
final configManager = ConfigurationManager.instance;

// Get current configuration
final config = await configManager.getConfiguration();

// Update entire configuration
final success = await configManager.updateConfiguration(newConfig);

// Reset to defaults
await configManager.resetToDefaults();
```

### UI Preferences

```dart
// Theme mode
await configManager.setThemeMode('dark');
final themeMode = await configManager.getThemeMode();

// Language
await configManager.setPrimaryLanguage('es');
final language = await configManager.getPrimaryLanguage();

// Font scale
await configManager.setFontScale(1.2);
final fontScale = await configManager.getFontScale();

// Advanced options
await configManager.setShowAdvancedOptions(true);
final showAdvanced = await configManager.shouldShowAdvancedOptions();

// Animations
await configManager.setAnimationsEnabled(false);
final animationsEnabled = await configManager.areAnimationsEnabled();
```

### App Settings

```dart
// Set custom app setting
await configManager.setAppSetting('auto_save', true);

// Get custom app setting
final autoSave = await configManager.getAppSetting<bool>('auto_save');

// Update multiple settings
await configManager.updateAppSettings({
  'auto_save': true,
  'backup_enabled': false,
  'custom_setting': 'value',
});
```

### Configuration Validation

```dart
// Check if configuration is valid
final isValid = await configManager.isConfigurationValid();

// Get validation errors
final errors = await configManager.getConfigurationErrors();

// Get validation warnings
final warnings = await configManager.getConfigurationWarnings();

// Full validation result
final validation = await configManager.validateConfiguration();
```

### Export/Import

```dart
// Export configuration
final configJson = await configManager.exportConfiguration();

// Import configuration
final success = await configManager.importConfiguration(configJson);
```

### Reactive Updates

```dart
// Listen to configuration changes
configManager.configurationStream.listen((config) {
  print('Configuration updated: ${config.version}');
  // Update your UI accordingly
});
```

## Configuration Model

The `AppConfiguration` class is the central data model:

```dart
class AppConfiguration {
  final LLMConfig? translationConfig;      // Translation settings
  final TTSConfig? ttsConfig;              // TTS settings
  final UIPreferences uiPreferences;       // UI preferences
  final Map<String, dynamic> appSettings; // Custom app settings
  final DateTime lastUpdated;             // Last update timestamp
  final String version;                   // Configuration version
}
```

### UI Preferences

```dart
class UIPreferences {
  final String themeMode;                 // 'light', 'dark', 'system'
  final String primaryLanguage;           // Language code (e.g., 'en', 'es')
  final double fontScale;                 // Font size multiplier (0.5 - 3.0)
  final bool showAdvancedOptions;         // Show advanced UI options
  final bool enableAnimations;            // Enable UI animations
  final WindowPreferences? windowPreferences; // Window size/position
  final Map<String, dynamic> customSettings;  // Custom UI settings
}
```

## Migration System

The configuration system automatically handles version migrations:

```dart
// Migration is automatic when initializing
await ConfigurationManager.instance.initialize();

// Manual migration (advanced usage)
final migratedConfig = await ConfigurationMigration.migrate(
  oldConfigJson,
  fromVersion: '0.1.0',
);
```

### Supported Migration Paths

- `0.1.0` → `1.0.0`: Migrates old theme/language settings to new UI preferences
- `0.2.0` → `1.0.0`: Ensures all required fields exist in UI preferences
- Generic migration: Applies safe defaults for any unsupported version

## Storage Strategy

The configuration system uses a dual-storage approach:

1. **Primary Storage**: SharedPreferences for reliable, platform-native storage
2. **Secondary Storage**: JSON files in the application documents directory for backup

### Storage Locations

- **SharedPreferences**: `alouette_app_configuration` key
- **File Storage**: `{DocumentsDirectory}/alouette/alouette_config.json`

## Error Handling

The system provides comprehensive error handling:

```dart
try {
  await configManager.updateConfiguration(config);
} catch (e) {
  // Handle configuration errors
  print('Configuration error: $e');
}

// Or check validation before updating
final validation = await configManager.validateConfiguration();
if (!(validation['isValid'] as bool)) {
  final errors = validation['errors'] as List<String>;
  // Handle validation errors
}
```

## Testing

The configuration system is fully testable:

```dart
void main() {
  group('Configuration Tests', () {
    late ConfigurationManager configManager;

    setUp(() {
      configManager = ConfigurationManager.instance;
    });

    tearDown(() {
      configManager.dispose();
    });

    test('should update theme mode', () async {
      await configManager.initialize();
      
      await configManager.setThemeMode('dark');
      final themeMode = await configManager.getThemeMode();
      
      expect(themeMode, equals('dark'));
    });
  });
}
```

## Best Practices

### 1. Initialize Early
Always initialize the configuration manager in your app's `main()` function before running the app.

### 2. Use Reactive Updates
Listen to configuration changes using the stream API to keep your UI in sync.

### 3. Validate Before Saving
Always validate configuration before saving to prevent invalid states.

### 4. Handle Errors Gracefully
Implement proper error handling for configuration operations.

### 5. Use Type-Safe Getters
Use the typed getter methods for common settings instead of accessing the raw configuration.

### 6. Test Configuration Logic
Write tests for any custom configuration logic in your application.

## Integration with Service Locator

The configuration manager integrates seamlessly with the service locator pattern:

```dart
// Register during app initialization
ServiceLocator.register<ConfigurationManager>(ConfigurationManager.instance);

// Use in services
class MyService {
  final ConfigurationManager _configManager = ServiceLocator.get<ConfigurationManager>();
  
  Future<void> performAction() async {
    final autoSave = await _configManager.getAppSetting<bool>('auto_save') ?? true;
    if (autoSave) {
      // Perform auto-save
    }
  }
}
```

## Troubleshooting

### Configuration Not Persisting
- Ensure `WidgetsFlutterBinding.ensureInitialized()` is called before initialization
- Check that the app has write permissions to the documents directory

### Migration Failures
- Check the logs for specific migration errors
- The system will fall back to default configuration if migration fails

### Validation Errors
- Use `getConfigurationErrors()` to see specific validation issues
- Check that all required fields are properly set

### Performance Issues
- Configuration is cached in memory after loading
- File operations are performed asynchronously
- Consider using the stream API to avoid polling for changes

## Future Enhancements

Planned improvements for the configuration system:

- [ ] Cloud synchronization support
- [ ] Configuration profiles/presets
- [ ] Advanced validation rules
- [ ] Configuration diff/changelog
- [ ] Encrypted storage for sensitive settings
- [ ] Configuration templates for different app types

## Support

For issues or questions about the configuration system:

1. Check the test files for usage examples
2. Review the example integration code
3. Examine the validation error messages
4. Consult the API documentation in the source code