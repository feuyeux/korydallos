import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';

void main() {
  group('ConfigurationManager Tests', () {
    late ConfigurationManager configManager;

    setUp(() {
      configManager = ConfigurationManager.instance;
    });

    tearDown(() {
      configManager.dispose();
    });

    test('should initialize with default configuration', () async {
      await configManager.initialize();
      
      final config = await configManager.getConfiguration();
      
      expect(config, isNotNull);
      expect(config.version, equals('1.0.0'));
      expect(config.uiPreferences.themeMode, equals('system'));
      expect(config.uiPreferences.primaryLanguage, equals('en'));
      expect(config.uiPreferences.fontScale, equals(1.0));
      expect(config.uiPreferences.enableAnimations, isTrue);
    });

    test('should update UI preferences', () async {
      await configManager.initialize();
      
      final newPreferences = const UIPreferences(
        themeMode: 'dark',
        primaryLanguage: 'es',
        fontScale: 1.2,
        showAdvancedOptions: true,
        enableAnimations: false,
      );
      
      final success = await configManager.updateUIPreferences(newPreferences);
      expect(success, isTrue);
      
      final config = await configManager.getConfiguration();
      expect(config.uiPreferences.themeMode, equals('dark'));
      expect(config.uiPreferences.primaryLanguage, equals('es'));
      expect(config.uiPreferences.fontScale, equals(1.2));
      expect(config.uiPreferences.showAdvancedOptions, isTrue);
      expect(config.uiPreferences.enableAnimations, isFalse);
    });

    test('should update app settings', () async {
      await configManager.initialize();
      
      final newSettings = {
        'auto_save': false,
        'backup_enabled': false,
        'custom_setting': 'test_value',
      };
      
      final success = await configManager.updateAppSettings(newSettings);
      expect(success, isTrue);
      
      final config = await configManager.getConfiguration();
      expect(config.appSettings['auto_save'], isFalse);
      expect(config.appSettings['backup_enabled'], isFalse);
      expect(config.appSettings['custom_setting'], equals('test_value'));
    });

    test('should get and set individual app settings', () async {
      await configManager.initialize();
      
      // Set a setting
      await configManager.setAppSetting('test_key', 'test_value');
      
      // Get the setting
      final value = await configManager.getAppSetting<String>('test_key');
      expect(value, equals('test_value'));
      
      // Set a different type
      await configManager.setAppSetting('test_number', 42);
      final numberValue = await configManager.getAppSetting<int>('test_number');
      expect(numberValue, equals(42));
    });

    test('should handle theme mode changes', () async {
      await configManager.initialize();
      
      // Test setting light theme
      await configManager.setThemeMode('light');
      final lightTheme = await configManager.getThemeMode();
      expect(lightTheme, equals('light'));
      
      // Test setting dark theme
      await configManager.setThemeMode('dark');
      final darkTheme = await configManager.getThemeMode();
      expect(darkTheme, equals('dark'));
      
      // Test setting system theme
      await configManager.setThemeMode('system');
      final systemTheme = await configManager.getThemeMode();
      expect(systemTheme, equals('system'));
    });

    test('should handle language changes', () async {
      await configManager.initialize();
      
      await configManager.setPrimaryLanguage('fr');
      final language = await configManager.getPrimaryLanguage();
      expect(language, equals('fr'));
    });

    test('should handle font scale changes', () async {
      await configManager.initialize();
      
      await configManager.setFontScale(1.5);
      final fontScale = await configManager.getFontScale();
      expect(fontScale, equals(1.5));
    });

    test('should handle advanced options toggle', () async {
      await configManager.initialize();
      
      await configManager.setShowAdvancedOptions(true);
      final showAdvanced = await configManager.shouldShowAdvancedOptions();
      expect(showAdvanced, isTrue);
      
      await configManager.setShowAdvancedOptions(false);
      final hideAdvanced = await configManager.shouldShowAdvancedOptions();
      expect(hideAdvanced, isFalse);
    });

    test('should handle animations toggle', () async {
      await configManager.initialize();
      
      await configManager.setAnimationsEnabled(false);
      final animationsDisabled = await configManager.areAnimationsEnabled();
      expect(animationsDisabled, isFalse);
      
      await configManager.setAnimationsEnabled(true);
      final animationsEnabled = await configManager.areAnimationsEnabled();
      expect(animationsEnabled, isTrue);
    });

    test('should validate configuration', () async {
      await configManager.initialize();
      
      final isValid = await configManager.isConfigurationValid();
      expect(isValid, isTrue);
      
      final errors = await configManager.getConfigurationErrors();
      expect(errors, isEmpty);
    });

    test('should export and import configuration', () async {
      await configManager.initialize();
      
      // Modify configuration
      await configManager.setThemeMode('dark');
      await configManager.setPrimaryLanguage('es');
      await configManager.setAppSetting('test_setting', 'test_value');
      
      // Export configuration
      final exportedConfig = await configManager.exportConfiguration();
      expect(exportedConfig, isNotNull);
      expect(exportedConfig['ui_preferences']['theme_mode'], equals('dark'));
      expect(exportedConfig['ui_preferences']['primary_language'], equals('es'));
      expect(exportedConfig['app_settings']['test_setting'], equals('test_value'));
      
      // Reset to defaults
      await configManager.resetToDefaults();
      
      // Verify reset
      final resetTheme = await configManager.getThemeMode();
      expect(resetTheme, equals('system'));
      
      // Import configuration
      final importSuccess = await configManager.importConfiguration(exportedConfig);
      expect(importSuccess, isTrue);
      
      // Verify import
      final importedTheme = await configManager.getThemeMode();
      final importedLanguage = await configManager.getPrimaryLanguage();
      final importedSetting = await configManager.getAppSetting<String>('test_setting');
      
      expect(importedTheme, equals('dark'));
      expect(importedLanguage, equals('es'));
      expect(importedSetting, equals('test_value'));
    });

    test('should handle first launch detection', () async {
      await configManager.initialize();
      
      // Should be first launch initially (or false if already initialized)
      final isFirstLaunch = await configManager.isFirstLaunch();
      
      // Complete first launch
      await configManager.completeFirstLaunch();
      
      // Should no longer be first launch
      final isNotFirstLaunch = await configManager.isFirstLaunch();
      expect(isNotFirstLaunch, isFalse);
    });

    test('should reset to defaults', () async {
      await configManager.initialize();
      
      // Modify configuration
      await configManager.setThemeMode('dark');
      await configManager.setPrimaryLanguage('fr');
      await configManager.setFontScale(1.5);
      await configManager.setAppSetting('custom_setting', 'custom_value');
      
      // Reset to defaults
      await configManager.resetToDefaults();
      
      // Verify reset
      final config = await configManager.getConfiguration();
      expect(config.uiPreferences.themeMode, equals('system'));
      expect(config.uiPreferences.primaryLanguage, equals('en'));
      expect(config.uiPreferences.fontScale, equals(1.0));
      expect(config.appSettings['custom_setting'], isNull);
    });
  });

  group('AppConfiguration Tests', () {
    test('should create valid default configuration', () {
      final config = AppConfiguration();
      
      expect(config.version, equals('1.0.0'));
      expect(config.uiPreferences.themeMode, equals('system'));
      expect(config.uiPreferences.primaryLanguage, equals('en'));
      expect(config.uiPreferences.fontScale, equals(1.0));
      expect(config.uiPreferences.enableAnimations, isTrue);
      expect(config.appSettings, isEmpty);
    });

    test('should serialize to and from JSON', () {
      final originalConfig = AppConfiguration(
        uiPreferences: const UIPreferences(
          themeMode: 'dark',
          primaryLanguage: 'es',
          fontScale: 1.2,
          showAdvancedOptions: true,
          enableAnimations: false,
        ),
        appSettings: {
          'auto_save': false,
          'custom_setting': 'test_value',
        },
        version: '1.0.0',
      );
      
      final json = originalConfig.toJson();
      final deserializedConfig = AppConfiguration.fromJson(json);
      
      expect(deserializedConfig.uiPreferences.themeMode, equals('dark'));
      expect(deserializedConfig.uiPreferences.primaryLanguage, equals('es'));
      expect(deserializedConfig.uiPreferences.fontScale, equals(1.2));
      expect(deserializedConfig.uiPreferences.showAdvancedOptions, isTrue);
      expect(deserializedConfig.uiPreferences.enableAnimations, isFalse);
      expect(deserializedConfig.appSettings['auto_save'], isFalse);
      expect(deserializedConfig.appSettings['custom_setting'], equals('test_value'));
      expect(deserializedConfig.version, equals('1.0.0'));
    });

    test('should validate configuration correctly', () {
      // Valid configuration
      final validConfig = AppConfiguration(
        uiPreferences: const UIPreferences(
          themeMode: 'dark',
          primaryLanguage: 'en',
          fontScale: 1.0,
        ),
      );
      
      final validResult = validConfig.validate();
      expect(validResult['isValid'], isTrue);
      expect(validResult['errors'], isEmpty);
      
      // Invalid configuration
      final invalidConfig = AppConfiguration(
        uiPreferences: const UIPreferences(
          themeMode: 'invalid_theme',
          primaryLanguage: 'en',
          fontScale: 5.0, // Too high
        ),
      );
      
      final invalidResult = invalidConfig.validate();
      expect(invalidResult['isValid'], isFalse);
      expect(invalidResult['errors'], isNotEmpty);
    });

    test('should create copies with modifications', () {
      final originalConfig = AppConfiguration(
        uiPreferences: const UIPreferences(themeMode: 'light'),
        appSettings: {'setting1': 'value1'},
      );
      
      final modifiedConfig = originalConfig.copyWith(
        uiPreferences: const UIPreferences(themeMode: 'dark'),
        appSettings: {'setting2': 'value2'},
      );
      
      expect(originalConfig.uiPreferences.themeMode, equals('light'));
      expect(originalConfig.appSettings['setting1'], equals('value1'));
      
      expect(modifiedConfig.uiPreferences.themeMode, equals('dark'));
      expect(modifiedConfig.appSettings['setting2'], equals('value2'));
    });
  });
}