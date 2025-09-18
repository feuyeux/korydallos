# Alouette Architecture Migration Guide

This guide provides comprehensive instructions for migrating from the legacy Alouette architecture to the new refactored architecture with centralized services, shared UI components, and Flutter naming conventions.

## Overview

The refactored architecture introduces several key improvements:

- **Centralized Services**: Translation and TTS functionality moved to dedicated libraries
- **Shared UI Components**: Atomic design system with reusable components
- **Service Locator Pattern**: Dependency injection for loose coupling
- **Flutter Naming Conventions**: Consistent snake_case files and PascalCase classes
- **Platform Optimization**: Automatic engine selection based on platform
- **Configuration Management**: Unified settings and preferences system

## Migration Timeline

### Phase 1: Library Updates ✅ COMPLETED
- Refactored alouette-lib-trans with unified API
- Refactored alouette-lib-tts with platform-specific engines
- Created alouette-ui-shared with atomic design components

### Phase 2: Application Updates ✅ COMPLETED
- Updated all applications to use refactored libraries
- Implemented service locator pattern
- Migrated to shared UI components

### Phase 3: Documentation Updates 🔄 IN PROGRESS
- Updated README files for new architecture
- Created migration guides and API documentation
- Added platform-specific configuration guides

## Breaking Changes

### 1. Import Statements

**Before (Legacy):**
```dart
// Old library imports
import 'package:alouette_lib_trans/translation_service.dart';
import 'package:alouette_lib_tts/edge_tts_service.dart';
import 'package:alouette_lib_tts/flutter_tts_service.dart';

// Old UI imports
import 'package:alouette_ui_shared/custom_button.dart';
import 'package:alouette_ui_shared/language_dropdown.dart';
```

**After (New Architecture):**
```dart
// New unified library imports
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'package:alouette_lib_tts/alouette_lib_tts.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';

// Or specific imports
import 'package:alouette_lib_trans/src/services/translation_service.dart';
import 'package:alouette_lib_tts/src/core/tts_service.dart';
import 'package:alouette_ui_shared/src/components/atoms/alouette_button.dart';
```

### 2. Service Initialization

**Before (Legacy):**
```dart
// Manual service creation
final translationService = TranslationService();
final edgeTTSService = EdgeTTSService();
final flutterTTSService = FlutterTTSService();

// Manual initialization
await translationService.initialize();
await edgeTTSService.initialize();
```

**After (New Architecture):**
```dart
// Service locator initialization
await ServiceManager.initialize(ServiceConfiguration.combined);

// Access services through service locator
final translationService = ServiceManager.getTranslationService();
final ttsService = ServiceManager.getTTSService();

// Or direct access
final translationService = ServiceLocator.get<TranslationService>();
final ttsService = ServiceLocator.get<UnifiedTTSService>();
```

### 3. TTS Engine Selection

**Before (Legacy):**
```dart
// Manual engine selection
TTSService ttsService;
if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
  ttsService = EdgeTTSService();
} else {
  ttsService = FlutterTTSService();
}
await ttsService.initialize();
```

**After (New Architecture):**
```dart
// Automatic platform-based selection
final ttsService = UnifiedTTSService();
await ttsService.initialize(); // Automatically selects best engine

// Or explicit engine selection
await ttsService.initialize(preferredEngine: TTSEngineType.edge);

// Runtime engine switching
await ttsService.switchEngine(TTSEngineType.flutter);
```

### 4. UI Components

**Before (Legacy):**
```dart
// Custom button implementations
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFF3B82F6),
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  onPressed: onPressed,
  child: Text('Button'),
)

// Custom language selector
DropdownButton<String>(
  value: selectedLanguage,
  items: languages.map((lang) => DropdownMenuItem(
    value: lang.code,
    child: Text(lang.name),
  )).toList(),
  onChanged: onLanguageChanged,
)
```

**After (New Architecture):**
```dart
// Atomic design components
AlouetteButton(
  text: 'Button',
  onPressed: onPressed,
  variant: AlouetteButtonVariant.primary,
  size: AlouetteButtonSize.medium,
)

// Shared language selector
LanguageSelector(
  selectedLanguage: selectedLanguage,
  onLanguageChanged: onLanguageChanged,
  availableLanguages: languages,
)
```

### 5. Configuration Management

**Before (Legacy):**
```dart
// Manual SharedPreferences usage
final prefs = await SharedPreferences.getInstance();
final themeMode = prefs.getString('theme_mode') ?? 'system';
await prefs.setString('theme_mode', 'dark');

// Scattered configuration
final llmConfig = LLMConfig.fromPrefs();
final ttsConfig = TTSConfig.fromPrefs();
```

**After (New Architecture):**
```dart
// Centralized configuration
final configManager = ConfigurationManager.instance;
await configManager.initialize();

// Type-safe configuration access
final themeMode = await configManager.getThemeMode();
await configManager.setThemeMode('dark');

// Unified configuration model
final config = await configManager.getConfiguration();
final success = await configManager.updateConfiguration(newConfig);
```

## Step-by-Step Migration

### Step 1: Update Dependencies

Update your `pubspec.yaml` files to use the refactored libraries:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Updated library dependencies
  alouette_lib_trans: ^1.0.0
  alouette_lib_tts: ^1.0.0
  alouette_ui_shared: ^1.0.0
  
  # Remove old dependencies (if any)
  # old_translation_lib: ^0.x.x
  # old_tts_lib: ^0.x.x
```

### Step 2: Update Import Statements

Replace old imports with new unified imports:

```bash
# Use find and replace in your IDE
# Replace: import 'package:alouette_lib_trans/translation_service.dart';
# With: import 'package:alouette_lib_trans/alouette_lib_trans.dart';

# Replace: import 'package:alouette_lib_tts/edge_tts_service.dart';
# With: import 'package:alouette_lib_tts/alouette_lib_tts.dart';

# Replace: import 'package:alouette_ui_shared/custom_button.dart';
# With: import 'package:alouette_ui_shared/alouette_ui_shared.dart';
```

### Step 3: Initialize Service Locator

Update your `main.dart` file:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services based on your app type
  ServiceConfiguration config;
  
  // For combined apps (translation + TTS)
  config = ServiceConfiguration.combined;
  
  // For translation-only apps
  // config = ServiceConfiguration.translationOnly;
  
  // For TTS-only apps
  // config = ServiceConfiguration.ttsOnly;
  
  final result = await ServiceManager.initialize(config);
  
  if (!result.isSuccessful) {
    print('Service initialization failed: ${result.errors}');
    // Handle initialization failure
  }
  
  runApp(MyApp());
}
```

### Step 4: Update Service Usage

Replace direct service instantiation with service locator access:

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  // Remove manual service creation
  // late TranslationService _translationService;
  // late EdgeTTSService _ttsService;
  
  // Access services through service locator
  late TranslationService _translationService;
  late UnifiedTTSService _ttsService;
  
  @override
  void initState() {
    super.initState();
    
    // Get services from service locator
    _translationService = ServiceManager.getTranslationService();
    _ttsService = ServiceManager.getTTSService();
    
    // Remove manual initialization
    // _initializeServices();
  }
  
  // Remove manual initialization method
  // Future<void> _initializeServices() async {
  //   await _translationService.initialize();
  //   await _ttsService.initialize();
  // }
}
```

### Step 5: Update UI Components

Replace custom UI implementations with atomic design components:

```dart
// Replace custom buttons
// OLD:
ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
  onPressed: onPressed,
  child: Text('Translate'),
)

// NEW:
AlouetteButton(
  text: 'Translate',
  onPressed: onPressed,
  variant: AlouetteButtonVariant.primary,
)

// Replace custom language selectors
// OLD:
DropdownButton<String>(
  value: selectedLanguage,
  items: languages.map((lang) => DropdownMenuItem(
    value: lang.code,
    child: Text(lang.name),
  )).toList(),
  onChanged: onLanguageChanged,
)

// NEW:
LanguageSelector(
  selectedLanguage: selectedLanguage,
  onLanguageChanged: onLanguageChanged,
  availableLanguages: languages,
)
```

### Step 6: Update Configuration Management

Replace manual SharedPreferences usage with centralized configuration:

```dart
class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ConfigurationManager _configManager = ConfigurationManager.instance;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    
    // Listen to configuration changes
    _configManager.configurationStream.listen((config) {
      setState(() {
        // Update UI based on configuration changes
      });
    });
  }
  
  Future<void> _loadSettings() async {
    // Load settings using configuration manager
    final themeMode = await _configManager.getThemeMode();
    final language = await _configManager.getPrimaryLanguage();
    
    setState(() {
      // Update UI state
    });
  }
  
  Future<void> _updateTheme(String themeMode) async {
    await _configManager.setThemeMode(themeMode);
    // Configuration change will be automatically broadcast
  }
}
```

### Step 7: Update Theme Management

Replace manual theme handling with the new theme service:

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeService _themeService = ThemeService();
  ThemeMode _themeMode = ThemeMode.system;
  
  @override
  void initState() {
    super.initState();
    _loadTheme();
    
    // Listen to theme changes
    _themeService.addListener(_onThemeChanged);
  }
  
  void _onThemeChanged() {
    setState(() {
      _themeMode = _getThemeMode(_themeService.themeMode);
    });
  }
  
  ThemeMode _getThemeMode(AlouetteThemeMode mode) {
    switch (mode) {
      case AlouetteThemeMode.light:
        return ThemeMode.light;
      case AlouetteThemeMode.dark:
        return ThemeMode.dark;
      case AlouetteThemeMode.system:
        return ThemeMode.system;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _themeService.getLightTheme(),
      darkTheme: _themeService.getDarkTheme(),
      themeMode: _themeMode,
      home: MyHomePage(),
    );
  }
}
```

## API Changes

### Translation Service API

**Before:**
```dart
// Old API
final result = await translationService.translateText(
  text: 'Hello',
  targetLanguages: ['es', 'fr'],
  config: llmConfig,
);
```

**After:**
```dart
// New unified API
final result = await translationService.translateToMultipleLanguages(
  'Hello',
  ['es', 'fr'],
  llmConfig,
);
```

### TTS Service API

**Before:**
```dart
// Old separate services
final edgeService = EdgeTTSService();
final flutterService = FlutterTTSService();

// Platform-specific usage
if (Platform.isDesktop) {
  await edgeService.synthesizeText('Hello', 'en-US-AriaNeural');
} else {
  await flutterService.speak('Hello');
}
```

**After:**
```dart
// New unified API
final ttsService = UnifiedTTSService();
await ttsService.initialize(); // Automatically selects best engine

// Unified usage across platforms
final audioData = await ttsService.synthesizeText('Hello', 'en-US-AriaNeural');
```

### UI Component API

**Before:**
```dart
// Old custom components
CustomButton(
  text: 'Action',
  color: Colors.blue,
  onTap: onPressed,
)

LanguageDropdown(
  languages: languages,
  selected: selectedLanguage,
  onChanged: onLanguageChanged,
)
```

**After:**
```dart
// New atomic components
AlouetteButton(
  text: 'Action',
  variant: AlouetteButtonVariant.primary,
  onPressed: onPressed,
)

LanguageSelector(
  availableLanguages: languages,
  selectedLanguage: selectedLanguage,
  onLanguageChanged: onLanguageChanged,
)
```

## Testing Migration

### Update Test Setup

**Before:**
```dart
void main() {
  group('Translation Tests', () {
    late TranslationService translationService;
    
    setUp(() {
      translationService = TranslationService();
    });
    
    test('should translate text', () async {
      await translationService.initialize();
      // Test implementation
    });
  });
}
```

**After:**
```dart
void main() {
  group('Translation Tests', () {
    setUp(() {
      // Register mock services
      ServiceLocator.register<TranslationService>(MockTranslationService());
    });
    
    tearDown(() {
      ServiceLocator.clear();
    });
    
    test('should translate text', () async {
      final translationService = ServiceLocator.get<TranslationService>();
      // Test implementation
    });
  });
}
```

### Mock Services

Create mock services for testing:

```dart
class MockTranslationService implements TranslationService {
  @override
  Future<TranslationResult> translateToMultipleLanguages(
    String text,
    List<String> targetLanguages,
    LLMConfig config,
  ) async {
    return TranslationResult(
      sourceText: text,
      translations: {'es': 'Hola', 'fr': 'Bonjour'},
      timestamp: DateTime.now(),
      isSuccessful: true,
    );
  }
  
  // Implement other required methods...
}
```

## Common Migration Issues

### 1. Service Not Found Errors

**Problem:** `ServiceNotRegisteredException: Service of type TranslationService not registered`

**Solution:** Ensure services are initialized before use:
```dart
// In main.dart
await ServiceManager.initialize(ServiceConfiguration.combined);

// Or register manually
ServiceLocator.register<TranslationService>(TranslationService());
```

### 2. Import Errors

**Problem:** `Target of URI doesn't exist: 'package:alouette_lib_trans/translation_service.dart'`

**Solution:** Update imports to use the new unified exports:
```dart
// Replace specific imports
import 'package:alouette_lib_trans/translation_service.dart';

// With unified imports
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
```

### 3. Theme Not Updating

**Problem:** Theme changes not reflected in UI

**Solution:** Use the new theme service and listen to changes:
```dart
final themeService = ThemeService();
themeService.addListener(() {
  setState(() {
    // Update theme mode
  });
});
```

### 4. Configuration Not Persisting

**Problem:** Settings not saved between app sessions

**Solution:** Use the centralized configuration manager:
```dart
final configManager = ConfigurationManager.instance;
await configManager.initialize(); // Call in main.dart
await configManager.setThemeMode('dark'); // Will persist automatically
```

## Performance Considerations

### Memory Usage
- Services are now singletons managed by the service locator
- Proper disposal is handled automatically
- Configuration is cached for better performance

### Initialization Time
- Services are initialized once during app startup
- Lazy loading for non-critical services
- Parallel initialization where possible

### Network Efficiency
- Connection pooling for LLM requests
- Cached voice lists for TTS
- Retry logic with exponential backoff

## Rollback Strategy

If you need to rollback to the legacy architecture:

1. **Revert pubspec.yaml** to use old library versions
2. **Restore old import statements** from version control
3. **Remove service locator initialization** from main.dart
4. **Restore manual service creation** in widgets
5. **Revert UI components** to custom implementations

However, we recommend completing the migration as the new architecture provides significant benefits in maintainability, performance, and consistency.

## Support and Resources

### Documentation
- [API Documentation](API_DOCUMENTATION.md) - Complete API reference
- [Platform Guide](PLATFORM_GUIDE.md) - Platform-specific features
- Library READMEs for detailed service documentation

### Getting Help
1. Check this migration guide for common issues
2. Review the example applications for implementation patterns
3. Consult the library documentation for API details
4. Create an issue on GitHub for specific problems

### Migration Checklist

- [ ] Updated pubspec.yaml dependencies
- [ ] Updated import statements
- [ ] Initialized service locator in main.dart
- [ ] Replaced direct service instantiation with service locator access
- [ ] Migrated to atomic design UI components
- [ ] Updated configuration management
- [ ] Updated theme management
- [ ] Updated test setup and mocks
- [ ] Verified functionality across all platforms
- [ ] Updated documentation and comments

## Conclusion

The migration to the new architecture provides significant benefits:

- **Reduced Code Duplication**: Single implementation of features
- **Improved Maintainability**: Clear separation of concerns
- **Better Testing**: Dependency injection enables easy mocking
- **Consistent UI**: Shared components ensure uniform experience
- **Platform Optimization**: Automatic selection of best engines
- **Future-Proof**: Extensible architecture for new features

While the migration requires some effort, the long-term benefits make it worthwhile for maintaining a high-quality, scalable codebase.