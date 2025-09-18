import 'package:flutter/material.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import 'app/alouette_app.dart';
import 'config/app_config.dart';
import 'shared/utils/app_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize ServiceLocator with core services
    ServiceLocator.initialize();
    final logger = ServiceLocator.logger;
    
    logger.info('Starting Alouette main application initialization', tag: 'Main');

    // Print environment info for debugging
    AppUtils.printEnvironmentInfo();

    // Initialize services and dependency injection
    await _setupServices();

    logger.info('Alouette main application initialization completed successfully', tag: 'Main');

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
    runApp(MaterialApp(
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

    // Register TTS services with platform-specific configuration
    logger.debug('Registering TTS services', tag: 'ServiceSetup');
    ServiceLocator.registerSingleton<UnifiedTTSService>(() => UnifiedTTSService.instance);

    // Register UI services
    logger.debug('Registering UI services', tag: 'ServiceSetup');
    ServiceLocator.registerSingleton<ThemeService>(() => ThemeService());

    // Initialize platform detection and configure TTS engine preferences
    final platformDetector = PlatformDetector();
    final platformInfo = platformDetector.getPlatformInfo();
    logger.info('Platform detected', tag: 'ServiceSetup', details: platformInfo);

    // Initialize TTS service with platform-specific settings
    final ttsService = ServiceLocator.get<UnifiedTTSService>();
    final recommendedEngine = platformDetector.getRecommendedEngine();
    
    logger.debug('Initializing TTS service with recommended engine: $recommendedEngine', tag: 'ServiceSetup');
    await ttsService.initialize(
      preferredEngine: recommendedEngine,
      autoFallback: true,
      config: AppConfig.defaultTTSConfig,
    );

    // Initialize translation service
    final translationService = ServiceLocator.get<TranslationService>();
    logger.debug('Initializing translation service', tag: 'ServiceSetup');
    await translationService.initialize();

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
