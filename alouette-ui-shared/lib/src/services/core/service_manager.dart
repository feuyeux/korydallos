import '../core/service_locator.dart';
import '../interfaces/tts_service_interface.dart';
import '../implementations/tts_service_impl.dart';

/// Service Manager for Alouette Applications
///
/// Provides centralized service management using dependency injection.
/// Replaces the old SharedTTSManager with a more testable and maintainable architecture.
class ServiceManager {
  static bool _isInitialized = false;

  /// Initialize all services with default implementations
  ///
  /// This should be called once at app startup.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Register TTS service as singleton
      ServiceLocator.registerSingleton<ITTSService>(() => TTSServiceImpl());

      // Initialize TTS service
      final ttsService = ServiceLocator.get<ITTSService>();
      final success = await ttsService.initialize();

      if (!success) {
        throw Exception('Failed to initialize TTS service');
      }

      _isInitialized = true;
      print('Service Manager: All services initialized successfully');
    } catch (e) {
      print('Service Manager initialization error: $e');
      rethrow;
    }
  }

  /// Get TTS service instance
  ///
  /// Returns the singleton TTS service instance.
  /// Throws ServiceNotRegisteredException if not initialized.
  static ITTSService getTTSService() {
    if (!_isInitialized) {
      throw StateError(
          'Service Manager not initialized. Call initialize() first.');
    }
    return ServiceLocator.get<ITTSService>();
  }

  /// Register a custom TTS service implementation
  ///
  /// Useful for testing or using alternative implementations.
  static void registerTTSService(ITTSService service) {
    ServiceLocator.register<ITTSService>(service);
  }

  /// Check if services are initialized
  static bool get isInitialized => _isInitialized;

  /// Dispose all services and cleanup
  ///
  /// Should be called when the app is shutting down.
  static Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      // Dispose TTS service if it exists
      if (ServiceLocator.isRegistered<ITTSService>()) {
        final ttsService = ServiceLocator.get<ITTSService>();
        ttsService.dispose();
      }

      // Clear all services
      ServiceLocator.clear();
      _isInitialized = false;

      print('Service Manager: All services disposed');
    } catch (e) {
      print('Service Manager disposal error: $e');
    }
  }

  /// Reset services (useful for testing)
  ///
  /// Disposes current services and allows re-initialization.
  static Future<void> reset() async {
    await dispose();
    _isInitialized = false;
  }
}

/// Helper extension for easier TTS access
extension TTSServiceHelper on ServiceManager {
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
}
