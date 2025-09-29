import 'dart:async';
import '../core/service_locator.dart';
import '../core/service_configuration.dart';
import '../interfaces/tts_service_interface.dart';
import '../interfaces/translation_service_interface.dart';
import '../implementations/tts_service_impl.dart';
import '../implementations/translation_service_impl.dart';

/// Service Manager for Alouette Applications
///
/// Provides centralized service management using dependency injection.
/// Manages the lifecycle of all services including initialization, registration, and disposal.
class ServiceManager {
  static bool _isInitialized = false;
  static final List<String> _initializationLog = [];
  static final Map<Type, bool> _serviceStatus = {};

  /// Initialize all services with default implementations
  ///
  /// This should be called once at app startup.
  /// [config] - Service configuration (defaults to combined configuration)
  static Future<ServiceInitializationResult> initialize([
    ServiceConfiguration config = ServiceConfiguration.combined,
  ]) async {
    if (_isInitialized) {
      return ServiceInitializationResult(
        isSuccessful: true,
        serviceResults: Map.from(_serviceStatus.map((k, v) => MapEntry(k.toString(), v))),
        errors: [],
        durationMs: 0,
      );
    }

    final stopwatch = Stopwatch()..start();
    _initializationLog.clear();
    _serviceStatus.clear();
    final errors = <String>[];

    try {
      if (config.verboseLogging) {
        _log('Starting service initialization with config: $config');
      } else {
        _log('Starting service initialization...');
      }

      // Register services as singletons
      if (config.initializeTTS) {
        ServiceLocator.registerSingleton<ITTSService>(() => TTSServiceImpl());
        _log('TTS service registered');
      }

      if (config.initializeTranslation) {
        ServiceLocator.registerSingleton<ITranslationService>(() => TranslationServiceImpl());
        _log('Translation service registered');
      }

      // Initialize services with timeout
      final initFuture = _initializeServicesWithConfig(config);
      await initFuture.timeout(
        Duration(milliseconds: config.initializationTimeoutMs),
        onTimeout: () {
          throw TimeoutException('Service initialization timed out after ${config.initializationTimeoutMs}ms');
        },
      );

      _isInitialized = true;
      stopwatch.stop();
      
      final result = ServiceInitializationResult(
        isSuccessful: true,
        serviceResults: Map.from(_serviceStatus.map((k, v) => MapEntry(k.toString(), v))),
        errors: errors,
        durationMs: stopwatch.elapsedMilliseconds,
      );

      _log('All services initialized successfully in ${result.durationMs}ms');
      if (config.verboseLogging) {
        print('Service Manager: ${result.getSummary()}');
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      errors.add(e.toString());
      _log('Service initialization failed: $e');
      
      final result = ServiceInitializationResult(
        isSuccessful: false,
        serviceResults: Map.from(_serviceStatus.map((k, v) => MapEntry(k.toString(), v))),
        errors: errors,
        durationMs: stopwatch.elapsedMilliseconds,
      );

      if (config.verboseLogging) {
        print('Service Manager initialization error: ${result.getSummary()}');
      }
      
      await dispose(); // Cleanup on failure
      return result;
    }
  }

  /// Initialize services based on configuration
  static Future<void> _initializeServicesWithConfig(ServiceConfiguration config) async {
    // Initialize services in parallel for better performance
    final futures = <Future<void>>[];

    if (config.initializeTTS) {
      futures.add(_initializeService<ITTSService>('TTS', config));
    }

    if (config.initializeTranslation) {
      futures.add(_initializeService<ITranslationService>('Translation', config));
    }

    // Wait for all services to initialize
    await Future.wait(futures);
  }

  /// Initialize a specific service
  static Future<void> _initializeService<T>(String serviceName, ServiceConfiguration config) async {
    try {
      final service = ServiceLocator.get<T>();
      
      bool success = false;
      if (service is ITTSService) {
        success = await service.initialize(autoFallback: config.ttsAutoFallback);
      } else if (service is ITranslationService) {
        success = await service.initialize();
      }

      if (!success) {
        throw Exception('Failed to initialize $serviceName service');
      }

      _serviceStatus[T] = true;
      _log('$serviceName service initialized');
    } catch (e) {
      _serviceStatus[T] = false;
      _log('$serviceName service failed: $e');
      rethrow;
    }
  }

  /// Get TTS service instance
  ///
  /// Returns the singleton TTS service instance.
  /// Throws ServiceNotRegisteredException if not initialized.
  static ITTSService getTTSService() {
    _ensureInitialized();
    _ensureServiceAvailable<ITTSService>('TTS');
    return ServiceLocator.get<ITTSService>();
  }

  /// Get Translation service instance
  ///
  /// Returns the singleton Translation service instance.
  /// Throws ServiceNotRegisteredException if not initialized.
  static ITranslationService getTranslationService() {
    _ensureInitialized();
    _ensureServiceAvailable<ITranslationService>('Translation');
    return ServiceLocator.get<ITranslationService>();
  }

  /// Register a custom TTS service implementation
  ///
  /// Useful for testing or using alternative implementations.
  static void registerTTSService(ITTSService service) {
    ServiceLocator.register<ITTSService>(service);
    _serviceStatus[ITTSService] = true;
  }

  /// Register a custom Translation service implementation
  ///
  /// Useful for testing or using alternative implementations.
  static void registerTranslationService(ITranslationService service) {
    ServiceLocator.register<ITranslationService>(service);
    _serviceStatus[ITranslationService] = true;
  }

  /// Check if services are initialized
  static bool get isInitialized => _isInitialized;

  /// Check if a specific service is available and initialized
  static bool isServiceAvailable<T>() {
    return _isInitialized && 
           ServiceLocator.isRegistered<T>() && 
           (_serviceStatus[T] ?? false);
  }

  /// Get service initialization status
  static Map<String, bool> getServiceStatus() {
    return {
      'TTS': isServiceAvailable<ITTSService>(),
      'Translation': isServiceAvailable<ITranslationService>(),
    };
  }

  /// Get initialization log for debugging
  static List<String> getInitializationLog() {
    return List.unmodifiable(_initializationLog);
  }

  /// Dispose all services and cleanup
  ///
  /// Should be called when the app is shutting down.
  static Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      _log('Starting service disposal...');

      // Dispose TTS service if it exists
      if (ServiceLocator.isRegistered<ITTSService>()) {
        final ttsService = ServiceLocator.get<ITTSService>();
        ttsService.dispose();
        _log('TTS service disposed');
      }

      // Dispose Translation service if it exists
      if (ServiceLocator.isRegistered<ITranslationService>()) {
        final translationService = ServiceLocator.get<ITranslationService>();
        translationService.dispose();
        _log('Translation service disposed');
      }

      // Clear all services
      ServiceLocator.clear();
      _serviceStatus.clear();
      _isInitialized = false;

      _log('All services disposed successfully');
      print('Service Manager: ${_initializationLog.join(', ')}');
    } catch (e) {
      _log('Service disposal error: $e');
      print('Service Manager disposal error: $e');
    }
  }

  /// Reset services (useful for testing)
  ///
  /// Disposes current services and allows re-initialization.
  static Future<void> reset() async {
    await dispose();
    _initializationLog.clear();
    _serviceStatus.clear();
    _isInitialized = false;
  }

  /// Reinitialize a specific service
  ///
  /// Useful for recovering from service failures.
  static Future<void> reinitializeService<T>(String serviceName) async {
    if (!_isInitialized) {
      throw StateError('Service Manager not initialized. Call initialize() first.');
    }

    try {
      _log('Reinitializing $serviceName service...');
      await _initializeService<T>(serviceName, ServiceConfiguration.combined);
      _log('$serviceName service reinitialized successfully');
    } catch (e) {
      _log('Failed to reinitialize $serviceName service: $e');
      rethrow;
    }
  }

  /// Private helper methods
  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('Service Manager not initialized. Call initialize() first.');
    }
  }

  static void _ensureServiceAvailable<T>(String serviceName) {
    if (!isServiceAvailable<T>()) {
      throw StateError('$serviceName service is not available or failed to initialize.');
    }
  }

  static void _log(String message) {
    _initializationLog.add(message);
  }
}

/// Helper extension for easier service access
extension ServiceManagerHelpers on ServiceManager {
  /// Quick access to TTS speak functionality
  static Future<void> speak(String text, {String? voiceName}) async {
    final ttsService = ServiceManager.getTTSService();
    await ttsService.speak(text, voiceName: voiceName);
  }

  /// Quick access to TTS stop functionality
  static Future<void> stopSpeaking() async {
    final ttsService = ServiceManager.getTTSService();
    await ttsService.stop();
  }

  /// Quick access to get available voices
  static Future<List<TTSVoice>> getVoices() async {
    final ttsService = ServiceManager.getTTSService();
    return await ttsService.getAvailableVoices();
  }

  /// Quick access to translation functionality
  static Future<String> translate({
    required String text,
    String? sourceLanguage,
    required String targetLanguage,
  }) async {
    final translationService = ServiceManager.getTranslationService();
    return await translationService.translate(
      text: text,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
  }

  /// Quick access to multi-language translation
  static Future<Map<String, String>> translateToMultiple({
    required String text,
    String? sourceLanguage,
    required List<String> targetLanguages,
  }) async {
    final translationService = ServiceManager.getTranslationService();
    return await translationService.translateToMultiple(
      text: text,
      sourceLanguage: sourceLanguage,
      targetLanguages: targetLanguages,
    );
  }

  /// Quick access to get supported languages
  static Future<List<LanguageInfo>> getSupportedLanguages() async {
    final translationService = ServiceManager.getTranslationService();
    return await translationService.getSupportedLanguages();
  }
}
