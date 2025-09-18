import 'package:flutter/material.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'app/translation_app.dart';
import 'config/translation_app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize ServiceLocator with core services
    ServiceLocator.initialize();
    final logger = ServiceLocator.logger;
    
    logger.info('Starting Alouette Translation application initialization', tag: 'Main');

    // Initialize services and dependency injection
    await _setupServices();

    logger.info('Alouette Translation application initialization completed successfully', tag: 'Main');

    runApp(const TranslationApp());
  } catch (error, stackTrace) {
    // Handle initialization errors gracefully
    debugPrint('Critical error during translation app initialization: $error');
    debugPrint('Stack trace: $stackTrace');
    
    // Try to log the error if possible
    try {
      ServiceLocator.logger.fatal(
        'Critical initialization error in translation app',
        tag: 'Main',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (e) {
      // If logging fails, just print to console
      debugPrint('Failed to log initialization error: $e');
    }
    
    // Run app with error state
    runApp(MaterialApp(
      title: 'Alouette Translator - Initialization Error',
      home: Scaffold(
        appBar: AppBar(title: const Text('Translation App - Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.translate, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to initialize translation application',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Restart the app
                  main();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

/// Setup and register all required services with the ServiceLocator
Future<void> _setupServices() async {
  final logger = ServiceLocator.logger;
  
  try {
    // Register Translation services
    logger.debug('Registering translation services', tag: 'ServiceSetup');
    ServiceLocator.registerSingleton<LLMConfigService>(() => LLMConfigService());
    ServiceLocator.registerSingleton<TranslationService>(() => TranslationService());

    // Register UI services
    logger.debug('Registering UI services', tag: 'ServiceSetup');
    ServiceLocator.registerSingleton<ThemeService>(() => ThemeService());

    // Initialize translation service with app-specific configuration
    final translationService = ServiceLocator.get<TranslationService>();
    logger.debug('Initializing translation service', tag: 'ServiceSetup');
    await translationService.initialize();

    // Create default LLM configuration for the translation app
    logger.debug('Creating default LLM configuration', tag: 'ServiceSetup');
    
    final defaultConfig = LLMConfig(
      provider: TranslationAppConfig.defaultProvider,
      serverUrl: TranslationAppConfig.defaultServerUrl,
      selectedModel: '',
    );
    
    // Validate the default configuration
    final configValidation = LLMConfigService.validateConfig(defaultConfig);
    if (configValidation['isValid'] as bool) {
      logger.debug('Default LLM configuration is valid', tag: 'ServiceSetup');
    } else {
      logger.warning('Default LLM configuration has issues', tag: 'ServiceSetup', 
        details: configValidation);
    }

    // Initialize theme service
    final themeService = ServiceLocator.get<ThemeService>();
    logger.debug('Initializing theme service', tag: 'ServiceSetup');
    await themeService.initialize();

    // Test translation service connection if auto-configuration is enabled
    if (TranslationAppConfig.enableAutoConfiguration) {
      logger.debug('Testing translation service connection', tag: 'ServiceSetup');
      try {
        final connectionStatus = await translationService.testConnection(defaultConfig);
        if (connectionStatus.success) {
          logger.info('Translation service connection test successful', tag: 'ServiceSetup');
        } else {
          logger.warning('Translation service connection test failed', tag: 'ServiceSetup', 
            details: {'status': connectionStatus.toString()});
        }
      } catch (e) {
        logger.warning('Translation service connection test error', tag: 'ServiceSetup', error: e);
        // Continue anyway - user can configure manually
      }
    }

    logger.info('All translation app services initialized successfully', tag: 'ServiceSetup');
  } catch (error, stackTrace) {
    logger.error(
      'Failed to setup translation app services',
      tag: 'ServiceSetup',
      error: error,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}
