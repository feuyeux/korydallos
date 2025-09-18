import 'package:flutter/material.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';

/// Example of how to integrate the Configuration Manager into an Alouette application
/// 
/// This example shows:
/// 1. How to initialize the configuration manager in main()
/// 2. How to register it with the service locator
/// 3. How to use configuration in widgets
/// 4. How to handle configuration changes

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize configuration manager
  await ConfigurationManager.instance.initialize();
  
  // Register with service locator for dependency injection
  ServiceLocator.register<ConfigurationManager>(ConfigurationManager.instance);
  
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
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
      title: 'Alouette Configuration Example',
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration Status',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ConfigurationStatusWidget(showDetails: true),
            SizedBox(height: 24),
            Text(
              'Configuration Panel',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ConfigurationPanel(showAdvanced: true),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showConfigurationDialog(context),
        tooltip: 'Open Configuration',
        child: const Icon(Icons.settings),
      ),
    );
  }

  void _showConfigurationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 500,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Application Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const Expanded(
                child: ConfigurationPanel(showAdvanced: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Example of a custom widget that uses configuration
class ConfigurationAwareWidget extends StatefulWidget {
  const ConfigurationAwareWidget({super.key});

  @override
  State<ConfigurationAwareWidget> createState() => _ConfigurationAwareWidgetState();
}

class _ConfigurationAwareWidgetState extends State<ConfigurationAwareWidget> {
  final ConfigurationManager _configManager = ConfigurationManager.instance;
  bool _animationsEnabled = true;
  double _fontScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
    
    // Listen to configuration changes
    _configManager.configurationStream.listen((config) {
      if (mounted) {
        setState(() {
          _animationsEnabled = config.uiPreferences.enableAnimations;
          _fontScale = config.uiPreferences.fontScale;
        });
      }
    });
  }

  Future<void> _loadConfiguration() async {
    final animationsEnabled = await _configManager.areAnimationsEnabled();
    final fontScale = await _configManager.getFontScale();
    
    if (mounted) {
      setState(() {
        _animationsEnabled = animationsEnabled;
        _fontScale = fontScale;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration-Aware Widget',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: Theme.of(context).textTheme.titleMedium!.fontSize! * _fontScale,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: _animationsEnabled 
                  ? const Duration(milliseconds: 300)
                  : Duration.zero,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Animations: ${_animationsEnabled ? 'Enabled' : 'Disabled'}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 14 * _fontScale,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Font Scale: ${(_fontScale * 100).round()}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: Theme.of(context).textTheme.bodyMedium!.fontSize! * _fontScale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example of how to use configuration in a service
class ExampleService {
  final ConfigurationManager _configManager = ConfigurationManager.instance;

  Future<void> performAction() async {
    // Check if auto-save is enabled
    final autoSave = await _configManager.getAppSetting<bool>('auto_save') ?? true;
    
    if (autoSave) {
      // Perform auto-save logic
      debugPrint('Auto-saving because it is enabled in configuration');
    }
    
    // Check if advanced options should be shown
    final showAdvanced = await _configManager.shouldShowAdvancedOptions();
    
    if (showAdvanced) {
      // Show advanced UI elements
      debugPrint('Showing advanced options');
    }
  }

  Future<void> updateUserPreference(String key, dynamic value) async {
    await _configManager.setAppSetting(key, value);
    debugPrint('Updated user preference: $key = $value');
  }
}