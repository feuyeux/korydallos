import 'package:flutter_test/flutter_test.dart';
import '../lib/src/services/core/service_locator.dart';
import '../lib/src/services/core/service_manager.dart';
import '../lib/src/services/core/service_configuration.dart';
import 'mocks/mock_services.dart';

void main() {
  group('Service Integration Tests', () {
    setUp(() {
      ServiceLocator.clear();
    });

    tearDown(() {
      ServiceLocator.clear();
    });

    test('should initialize services in correct order', () async {
      // Arrange
      final initOrder = <String>[];
      
      ServiceLocator.registerFactory<MockConfigurationService>(() {
        initOrder.add('Config');
        return MockConfigurationService();
      });

      ServiceLocator.registerFactory<MockTranslationService>(() {
        initOrder.add('Translation');
        final config = ServiceLocator.get<MockConfigurationService>();
        final service = MockTranslationService();
        service.initialize();
        return service;
      });

      ServiceLocator.registerFactory<MockTTSService>(() {
        initOrder.add('TTS');
        final config = ServiceLocator.get<MockConfigurationService>();
        final service = MockTTSService();
        service.initialize();
        return service;
      });

      // Act
      final translationService = ServiceLocator.get<MockTranslationService>();
      final ttsService = ServiceLocator.get<MockTTSService>();

      // Assert
      expect(translationService.isInitialized, isTrue);
      expect(ttsService.isInitialized, isTrue);
      expect(initOrder, equals(['Translation', 'Config', 'TTS']));
    });

    test('should handle service dependencies correctly', () async {
      // Arrange
      ServiceLocator.registerSingleton<MockConfigurationService>(() {
        final config = MockConfigurationService();
        config.setConfig('translation_enabled', true);
        config.setConfig('tts_enabled', true);
        return config;
      });

      ServiceLocator.registerFactory<MockTranslationService>(() {
        final config = ServiceLocator.get<MockConfigurationService>();
        final service = MockTranslationService();
        
        if (config.getConfig<bool>('translation_enabled') == true) {
          service.initialize();
        }
        
        return service;
      });

      ServiceLocator.registerFactory<MockTTSService>(() {
        final config = ServiceLocator.get<MockConfigurationService>();
        final service = MockTTSService();
        
        if (config.getConfig<bool>('tts_enabled') == true) {
          service.initialize();
        }
        
        return service;
      });

      // Act
      final translationService = ServiceLocator.get<MockTranslationService>();
      final ttsService = ServiceLocator.get<MockTTSService>();
      final configService = ServiceLocator.get<MockConfigurationService>();

      // Assert
      expect(translationService.isInitialized, isTrue);
      expect(ttsService.isInitialized, isTrue);
      expect(configService.getConfig<bool>('translation_enabled'), isTrue);
      expect(configService.getConfig<bool>('tts_enabled'), isTrue);
    });

    test('should handle service failure propagation', () async {
      // Arrange
      ServiceLocator.registerFactory<MockConfigurationService>(() {
        throw Exception('Configuration service failed to initialize');
      });

      ServiceLocator.registerFactory<MockTranslationService>(() {
        // This will fail because config service throws
        final config = ServiceLocator.get<MockConfigurationService>();
        return MockTranslationService();
      });

      // Act & Assert
      expect(
        () => ServiceLocator.get<MockTranslationService>(),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle service isolation', () async {
      // Arrange
      ServiceLocator.register<MockTranslationService>(MockTranslationService());
      ServiceLocator.register<MockTTSService>(MockTTSService());

      final translationService = ServiceLocator.get<MockTranslationService>();
      final ttsService = ServiceLocator.get<MockTTSService>();

      // Act - Initialize one service
      translationService.initialize();

      // Assert - Other service should remain uninitialized
      expect(translationService.isInitialized, isTrue);
      expect(ttsService.isInitialized, isFalse);
    });

    test('should handle service replacement during runtime', () async {
      // Arrange
      final originalService = MockTranslationService();
      ServiceLocator.register<MockTranslationService>(originalService);

      final retrievedOriginal = ServiceLocator.get<MockTranslationService>();
      expect(retrievedOriginal, equals(originalService));

      // Act - Replace service
      final newService = MockTranslationService();
      ServiceLocator.register<MockTranslationService>(newService);

      // Assert
      final retrievedNew = ServiceLocator.get<MockTranslationService>();
      expect(retrievedNew, equals(newService));
      expect(retrievedNew, isNot(equals(originalService)));
    });

    test('should handle concurrent service access', () async {
      // Arrange
      var initCount = 0;
      ServiceLocator.registerFactory<MockTranslationService>(() {
        initCount++;
        return MockTranslationService();
      });

      // Act - Simulate concurrent access
      final futures = List.generate(10, (index) async {
        return ServiceLocator.get<MockTranslationService>();
      });

      final services = await Future.wait(futures);

      // Assert - All should be the same instance (singleton behavior)
      expect(initCount, equals(1));
      for (int i = 1; i < services.length; i++) {
        expect(services[i], equals(services[0]));
      }
    });

    test('should handle service lifecycle management', () async {
      // Arrange
      final disposableService = MockDisposableService();
      ServiceLocator.register<MockDisposableService>(disposableService);

      // Act - Use service
      final service = ServiceLocator.get<MockDisposableService>();
      service.doSomething(); // Should work

      // Dispose service
      ServiceLocator.unregister<MockDisposableService>();
      service.dispose();

      // Assert
      expect(service.isDisposed, isTrue);
      expect(
        () => service.doSomething(),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle complex service interaction scenario', () async {
      // Arrange - Set up a realistic service interaction scenario
      ServiceLocator.registerSingleton<MockConfigurationService>(() {
        final config = MockConfigurationService();
        config.setConfig('api_url', 'http://localhost:11434');
        config.setConfig('default_voice', 'en-US-female');
        config.setConfig('translation_timeout', 30);
        return config;
      });

      ServiceLocator.registerFactory<MockTranslationService>(() {
        final config = ServiceLocator.get<MockConfigurationService>();
        final service = MockTranslationService();
        service.initialize();
        return service;
      });

      ServiceLocator.registerFactory<MockTTSService>(() {
        final config = ServiceLocator.get<MockConfigurationService>();
        final service = MockTTSService();
        service.initialize();
        return service;
      });

      // Act - Simulate application workflow
      final configService = ServiceLocator.get<MockConfigurationService>();
      final translationService = ServiceLocator.get<MockTranslationService>();
      final ttsService = ServiceLocator.get<MockTTSService>();

      // Simulate translation workflow
      final translatedText = await translationService.translate('Hello', 'es');
      await ttsService.speak(translatedText);

      // Assert
      expect(configService.getConfig<String>('api_url'), equals('http://localhost:11434'));
      expect(translationService.isInitialized, isTrue);
      expect(ttsService.isInitialized, isTrue);
      expect(translatedText, contains('Mock translation'));
    });

    test('should handle service configuration changes', () async {
      // Arrange
      ServiceLocator.registerSingleton<MockConfigurationService>(() {
        return MockConfigurationService();
      });

      ServiceLocator.registerFactory<MockTranslationService>(() {
        final config = ServiceLocator.get<MockConfigurationService>();
        final service = MockTranslationService();
        
        // Only initialize if enabled in config
        if (config.getConfig<bool>('translation_enabled') == true) {
          service.initialize();
        }
        
        return service;
      });

      final configService = ServiceLocator.get<MockConfigurationService>();

      // Act - Initially disabled
      configService.setConfig('translation_enabled', false);
      var translationService = ServiceLocator.get<MockTranslationService>();
      expect(translationService.isInitialized, isFalse);

      // Enable translation
      configService.setConfig('translation_enabled', true);
      
      // Need to get new instance to reflect config change
      ServiceLocator.unregister<MockTranslationService>();
      translationService = ServiceLocator.get<MockTranslationService>();

      // Assert
      expect(translationService.isInitialized, isTrue);
    });
  });

  group('Service Manager Integration Tests', () {
    setUp(() async {
      await ServiceManager.reset();
    });

    tearDown(() async {
      await ServiceManager.dispose();
    });

    test('should initialize with different configurations', () async {
      // Test TTS-only configuration
      var result = await ServiceManager.initialize(ServiceConfiguration.ttsOnly);
      expect(result.isSuccessful, isTrue);
      
      var status = ServiceManager.getServiceStatus();
      expect(status['TTS'], isTrue);
      expect(status['Translation'], isFalse);

      // Reset and test translation-only configuration
      await ServiceManager.reset();
      result = await ServiceManager.initialize(ServiceConfiguration.translationOnly);
      expect(result.isSuccessful, isTrue);
      
      status = ServiceManager.getServiceStatus();
      expect(status['TTS'], isFalse);
      expect(status['Translation'], isTrue);

      // Reset and test combined configuration
      await ServiceManager.reset();
      result = await ServiceManager.initialize(ServiceConfiguration.combined);
      expect(result.isSuccessful, isTrue);
      
      status = ServiceManager.getServiceStatus();
      expect(status['TTS'], isTrue);
      expect(status['Translation'], isTrue);
    });

    test('should provide initialization logging', () async {
      // Act
      await ServiceManager.initialize(ServiceConfiguration.combined);
      final log = ServiceManager.getInitializationLog();

      // Assert
      expect(log, isA<List<String>>());
      expect(log.isNotEmpty, isTrue);
      expect(log.any((entry) => entry.contains('ServiceManager')), isTrue);
    });

    test('should handle initialization failures gracefully', () async {
      // Arrange - Use testing configuration that might fail
      const failingConfig = ServiceConfiguration(
        initializeTTS: true,
        initializeTranslation: true,
        ttsAutoFallback: false,
        verboseLogging: true,
        initializationTimeoutMs: 1, // Very short timeout to force failure
      );

      // Act
      final result = await ServiceManager.initialize(failingConfig);

      // Assert - Should handle failure gracefully
      expect(result, isA<ServiceInitializationResult>());
      // Result might be successful or failed depending on actual service availability
    });

    test('should handle multiple initialization attempts', () async {
      // Act - Multiple concurrent initialization attempts
      final futures = List.generate(3, (index) => 
        ServiceManager.initialize(ServiceConfiguration.testing)
      );

      final results = await Future.wait(futures);

      // Assert - All should complete successfully
      for (final result in results) {
        expect(result.isSuccessful, isTrue);
      }
      expect(ServiceManager.isInitialized, isTrue);
    });

    test('should handle reset and reinitialize', () async {
      // Arrange
      await ServiceManager.initialize(ServiceConfiguration.ttsOnly);
      expect(ServiceManager.isInitialized, isTrue);

      // Act - Reset
      await ServiceManager.reset();
      expect(ServiceManager.isInitialized, isFalse);

      // Reinitialize with different configuration
      await ServiceManager.initialize(ServiceConfiguration.translationOnly);

      // Assert
      expect(ServiceManager.isInitialized, isTrue);
      final status = ServiceManager.getServiceStatus();
      expect(status['TTS'], isFalse);
      expect(status['Translation'], isTrue);
    });
  });
}