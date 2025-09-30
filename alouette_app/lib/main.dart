import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import 'app/alouette_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize ServiceLocator with core services
    ServiceLocator.initialize();
    final logger = ServiceLocator.logger;

    logger.info(
      'Starting Alouette main application initialization',
      tag: 'Main',
    );

    // Initialize UI library services with combined configuration
    await _setupServices();

    logger.info(
      'Alouette main application initialization completed successfully',
      tag: 'Main',
    );

    runApp(const AlouetteApp());
  } catch (error, stackTrace) {
    // Handle initialization errors gracefully
    debugPrint('Critical error during app initialization: $error');
    debugPrint('Stack trace: $stackTrace');

    // Try to log the error if possible
    try {
      ServiceLocator.logger.fatal(
        'Critical initialization error',
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
        title: 'Alouette - Initialization Error',
        home: Scaffold(
          appBar: AppBar(title: const Text('Initialization Error')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize application',
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
    logger.debug('Initializing UI library services', tag: 'ServiceSetup');
    
    // Initialize UI library services with combined configuration (TTS + Translation)
    final result = await ServiceManager.initialize(ServiceConfiguration.combined);
    
    if (!result.isSuccessful) {
      throw Exception('Failed to initialize UI services: ${result.errors.join(', ')}');
    }

    logger.info(
      'UI library services initialized successfully',
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

    logger.info('All services initialized successfully', tag: 'ServiceSetup');
  } catch (error, stackTrace) {
    logger.error(
      'Failed to setup services',
      tag: 'ServiceSetup',
      error: error,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}
