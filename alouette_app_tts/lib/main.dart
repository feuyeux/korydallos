import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import 'app/tts_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize only core services (non-blocking)
  ServiceLocator.initialize();

  // Run app immediately - services will be initialized asynchronously
  runApp(const TTSAppWrapper());
}

/// Wrapper that handles async service initialization
class TTSAppWrapper extends StatelessWidget {
  const TTSAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alouette TTS',
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: _initializeServices(),
        builder: (context, snapshot) {
          // Show splash screen while loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen(message: 'Initializing text-to-speech...');
          }

          // Show error screen if initialization failed
          if (snapshot.hasError || snapshot.data == false) {
            return InitializationErrorScreen(
              error: snapshot.error,
              onRetry: () {
                // Force rebuild to retry initialization
                (context as Element).markNeedsBuild();
              },
            );
          }

          // Services initialized successfully
          return const TTSApp();
        },
      ),
    );
  }

  Future<bool> _initializeServices() async {
    final logger = ServiceLocator.logger;

    try {
      logger.info('Starting TTS app initialization', tag: 'Main');

      // Initialize services in parallel
      await Future.wait([
        _initializeTTSService(),
        _initializeThemeService(),
      ]);

      logger.info('All services initialized successfully', tag: 'Main');
      return true;
    } catch (error, stackTrace) {
      logger.fatal(
        'Service initialization failed',
        tag: 'Main',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> _initializeTTSService() async {
    final logger = ServiceLocator.logger;
    try {
      logger.debug('Initializing TTS service', tag: 'ServiceInit');

      final result = await ServiceManager.initialize(
        const ServiceConfiguration(
          initializeTTS: true,
          initializeTranslation: false,
          initializationTimeoutMs: 15000, // 15 seconds
        ),
      );

      if (!result.isSuccessful) {
        throw ServiceError.initializationFailed('TTS', result.errors.join(', '));
      }

      logger.info('TTS service initialized successfully', tag: 'ServiceInit');
    } catch (e, stackTrace) {
      logger.error('TTS initialization failed', tag: 'ServiceInit', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _initializeThemeService() async {
    final logger = ServiceLocator.logger;
    try {
      logger.debug('Initializing Theme service', tag: 'ServiceInit');

      ServiceLocator.registerSingleton<ThemeService>(() => ThemeService());
      final themeService = ServiceLocator.get<ThemeService>();
      await themeService.initialize();

      logger.info('Theme service initialized', tag: 'ServiceInit');
    } catch (e, stackTrace) {
      logger.error('Theme initialization failed', tag: 'ServiceInit', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
