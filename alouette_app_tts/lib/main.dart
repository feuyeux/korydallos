import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import 'app/tts_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize ServiceLocator with core services
    ServiceLocator.initialize();
    final logger = ServiceLocator.logger;

    logger.info(
      'Starting Alouette TTS application initialization',
      tag: 'Main',
    );

    // Initialize UI library services for TTS-only app
    await _setupServices();

    logger.info(
      'Alouette TTS application initialization completed successfully',
      tag: 'Main',
    );

    runApp(const TTSApp());
  } catch (error, stackTrace) {
    // Handle initialization errors gracefully
    debugPrint('Critical error during TTS app initialization: $error');
    debugPrint('Stack trace: $stackTrace');

    // Try to log the error if possible
    try {
      ServiceLocator.logger.fatal(
        'Critical initialization error in TTS app',
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
        title: 'Alouette TTS - Initialization Error',
        home: Scaffold(
          appBar: AppBar(title: const Text('TTS App - Error')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.record_voice_over,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize TTS application',
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

/// Setup and register services using UI library ServiceManager
Future<void> _setupServices() async {
  final logger = ServiceLocator.logger;

  try {
    logger.debug('Initializing UI library services for TTS app', tag: 'ServiceSetup');
    
    // Initialize UI library services with TTS-only configuration
    final result = await ServiceManager.initialize(ServiceConfiguration.ttsOnly);
    
    if (!result.isSuccessful) {
      throw Exception('Failed to initialize UI services: ${result.errors.join(', ')}');
    }

    logger.info(
      'UI library TTS services initialized successfully',
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

    // Test TTS service functionality
    logger.debug('Testing TTS service functionality', tag: 'ServiceSetup');
    try {
      final ttsService = ServiceManager.getTTSService();
      final voices = await ttsService.getAvailableVoices();
      logger.info(
        'TTS service test successful',
        tag: 'ServiceSetup',
        details: {
          'voiceCount': voices.length,
          'isInitialized': ttsService.isInitialized,
        },
      );
    } catch (e) {
      logger.warning('TTS service test failed', tag: 'ServiceSetup', error: e);
      // Continue anyway - the app will handle TTS errors gracefully
    }

    logger.info(
      'All TTS app services initialized successfully',
      tag: 'ServiceSetup',
    );
  } catch (error, stackTrace) {
    logger.error(
      'Failed to setup TTS app services',
      tag: 'ServiceSetup',
      error: error,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}
