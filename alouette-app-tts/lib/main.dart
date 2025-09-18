import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';
import 'app/tts_app.dart';
import 'config/tts_app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize ServiceLocator with core services
    ServiceLocator.initialize();
    final logger = ServiceLocator.logger;
    
    logger.info('Starting Alouette TTS application initialization', tag: 'Main');

    // Initialize services and dependency injection
    await _setupServices();

    logger.info('Alouette TTS application initialization completed successfully', tag: 'Main');

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
    runApp(MaterialApp(
      title: 'Alouette TTS - Initialization Error',
      home: Scaffold(
        appBar: AppBar(title: const Text('TTS App - Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.record_voice_over, size: 64, color: Colors.red),
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
    ));
  }
}

/// Setup and register services with ServiceLocator
Future<void> _setupServices() async {
  final logger = ServiceLocator.logger;
  
  try {
    // Register TTS services
    logger.debug('Registering TTS services', tag: 'ServiceSetup');
    ServiceLocator.registerSingleton<UnifiedTTSService>(() => UnifiedTTSService.instance);

    // Register UI services
    logger.debug('Registering UI services', tag: 'ServiceSetup');
    ServiceLocator.registerSingleton<ThemeService>(() => ThemeService());

    // Initialize platform detection and configure TTS engine preferences
    final platformDetector = PlatformDetector();
    final platformInfo = platformDetector.getPlatformInfo();
    logger.info('Platform detected for TTS app', tag: 'ServiceSetup', details: platformInfo);

    // Determine preferred engine based on platform and app config
    TTSEngineType? preferredEngine = TTSAppConfig.preferredEngine;
    if (preferredEngine == null) {
      preferredEngine = platformDetector.getRecommendedEngine();
      logger.debug('Using platform-recommended TTS engine: $preferredEngine', tag: 'ServiceSetup');
    } else {
      logger.debug('Using app-configured TTS engine: $preferredEngine', tag: 'ServiceSetup');
    }

    // Initialize the TTS service with platform-specific settings
    final ttsService = ServiceLocator.get<UnifiedTTSService>();
    logger.debug('Initializing TTS service', tag: 'ServiceSetup');
    await ttsService.initialize(
      preferredEngine: preferredEngine,
      autoFallback: TTSAppConfig.enableAutoFallback,
      config: TTSAppConfig.defaultTTSConfig,
    );

    // Test TTS service functionality
    logger.debug('Testing TTS service functionality', tag: 'ServiceSetup');
    try {
      final voices = await ttsService.getVoices();
      logger.info('TTS service test successful', tag: 'ServiceSetup', 
        details: {'voiceCount': voices.length, 'engine': ttsService.currentEngine});
    } catch (e) {
      logger.warning('TTS service test failed', tag: 'ServiceSetup', error: e);
      // Continue anyway - the app will handle TTS errors gracefully
    }

    // Initialize theme service
    final themeService = ServiceLocator.get<ThemeService>();
    logger.debug('Initializing theme service', tag: 'ServiceSetup');
    await themeService.initialize();

    logger.info('All TTS app services initialized successfully', tag: 'ServiceSetup');
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
