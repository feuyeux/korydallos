import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import 'app/translation_app.dart';

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

/// Setup and register all required services using simplified ServiceManager
Future<void> _setupServices() async {
  final logger = ServiceLocator.logger;

  try {
    logger.debug('Initializing translation services', tag: 'ServiceSetup');

    // Initialize services with translation-only configuration (extended timeout)
    const config = ServiceConfiguration(
      initializeTTS: false,
      initializeTranslation: true,
      initializationTimeoutMs:
          120000, // extend to 120s to avoid premature timeout
    );
    final result = await ServiceManager.initialize(config);

    if (!result.isSuccessful) {
      throw Exception(
        'Failed to initialize translation services: ${result.errors.join(', ')}',
      );
    }

    logger.info(
      'Translation services initialized successfully',
      tag: 'ServiceSetup',
    );

    // Register theme service
    ServiceLocator.registerSingleton<ThemeService>(() => ThemeService());
    final themeService = ServiceLocator.get<ThemeService>();
    await themeService.initialize();

    logger.info('Theme service initialized', tag: 'ServiceSetup');
  } catch (error, stackTrace) {
    logger.error(
      'Failed to setup translation services',
      tag: 'ServiceSetup',
      error: error,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}
