import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import 'app/translation_app.dart';
import 'config/translation_app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize ServiceLocator with core services
    ServiceLocator.initialize();
    final logger = ServiceLocator.logger;

    logger.info(
      'Starting Alouette Translation application initialization',
      tag: 'Main',
    );

    // Initialize UI library services for translation-only app
    await _setupServices();

    logger.info(
      'Alouette Translation application initialization completed successfully',
      tag: 'Main',
    );

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
    runApp(
      MaterialApp(
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
      ),
    );
  }
}

/// Setup and register all required services using UI library ServiceManager
Future<void> _setupServices() async {
  final logger = ServiceLocator.logger;

  try {
    logger.debug('Initializing UI library services for translation app', tag: 'ServiceSetup');
    
    // Initialize UI library services with translation-only configuration
    final result = await ServiceManager.initialize(ServiceConfiguration.translationOnly);
    
    if (!result.isSuccessful) {
      throw Exception('Failed to initialize UI services: ${result.errors.join(', ')}');
    }

    logger.info(
      'UI library translation services initialized successfully',
      tag: 'ServiceSetup',
      details: {'duration': '${result.durationMs}ms', 'services': result.serviceResults},
    );

    // Register additional app-specific services
    logger.debug('Registering app-specific services', tag: 'ServiceSetup');
    ServiceLocator.registerSingleton<ThemeService>(() => ThemeService());

    // Initialize theme service
    final themeService = ServiceLocator.get<ThemeService>();
    logger.debug('Initializing theme service', tag: 'ServiceSetup');
    await themeService.initialize();

    // Test translation service connection if auto-configuration is enabled
    if (TranslationAppConfig.enableAutoConfiguration) {
      logger.debug('Testing translation service connection', tag: 'ServiceSetup');
      try {
        final translationService = ServiceManager.getTranslationService();
        // Test basic functionality - the UI library service handles configuration internally
        final supportedLanguages = await translationService.getSupportedLanguages();
        logger.info(
          'Translation service connection test successful',
          tag: 'ServiceSetup',
          details: {'supportedLanguages': supportedLanguages.length},
        );
      } catch (e) {
        logger.warning(
          'Translation service connection test error',
          tag: 'ServiceSetup',
          error: e,
        );
        // Continue anyway - user can configure manually
      }
    }

    logger.info(
      'All translation app services initialized successfully',
      tag: 'ServiceSetup',
    );
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
