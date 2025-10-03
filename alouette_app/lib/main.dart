import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import 'app/alouette_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize only core services (non-blocking)
  ServiceLocator.initialize();

  // Run app immediately - services will be initialized asynchronously
  runApp(const AlouetteAppWrapper());
}

/// Wrapper that handles async service initialization
class AlouetteAppWrapper extends StatelessWidget {
  const AlouetteAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alouette',
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: _initializeServices(),
        builder: (context, snapshot) {
          // Show splash screen while loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen(message: 'Initializing services...');
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
          return const AlouetteApp();
        },
      ),
    );
  }

  Future<bool> _initializeServices() async {
    final logger = ServiceLocator.logger;

    try {
      logger.info('Starting service initialization', tag: 'Main');

      // Initialize services in parallel for faster startup
      await Future.wait([
        _initializeTTSService(),
        _initializeTranslationService(),
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
          initializationTimeoutMs: 15000, // 15 seconds timeout
        ),
      );

      if (!result.isSuccessful) {
        throw ServiceError.initializationFailed('TTS', result.errors.join(', '));
      }

      logger.info('TTS service initialized', tag: 'ServiceInit');
    } catch (e, stackTrace) {
      logger.error('TTS initialization failed', tag: 'ServiceInit', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _initializeTranslationService() async {
    final logger = ServiceLocator.logger;
    try {
      logger.debug('Initializing Translation service', tag: 'ServiceInit');

      // Use short timeout for translation - it can be configured manually later
      final result = await ServiceManager.initialize(
        const ServiceConfiguration(
          initializeTTS: false,
          initializeTranslation: true,
          initializationTimeoutMs: 5000, // 5 seconds - allow manual config later
        ),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // Timeout is OK - user can configure manually
          logger.info('Translation auto-config timed out - manual configuration available', tag: 'ServiceInit');
          return ServiceInitializationResult(
            isSuccessful: true, // Continue anyway
            serviceResults: {'Translation': false},
            errors: ['Auto-configuration timed out'],
            durationMs: 5000,
          );
        },
      );

      logger.info('Translation service initialized: ${result.isSuccessful}', tag: 'ServiceInit');
    } catch (e) {
      // Allow translation service to fail - can be configured manually
      logger.warning('Translation auto-config failed - manual configuration available', tag: 'ServiceInit', error: e);
      // Don't rethrow - app can still start
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
