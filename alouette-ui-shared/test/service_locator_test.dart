import 'package:flutter_test/flutter_test.dart';
import '../lib/src/services/core/service_locator.dart';
import '../lib/src/services/core/service_manager.dart';
import '../lib/src/services/core/service_configuration.dart';
import 'mocks/mock_services.dart';

void main() {
  group('Service Locator Tests', () {
    setUp(() {
      // Clear services before each test
      ServiceLocator.clear();
    });

    tearDown(() {
      // Clean up after each test
      ServiceLocator.clear();
    });

    test('should register and retrieve services', () {
      // Arrange
      final testService = 'Test Service';

      // Act
      ServiceLocator.register<String>(testService);
      final retrieved = ServiceLocator.get<String>();

      // Assert
      expect(retrieved, equals(testService));
    });

    test('should register factory and create instances', () {
      // Arrange
      var callCount = 0;
      ServiceLocator.registerFactory<String>(() {
        callCount++;
        return 'Factory Service $callCount';
      });

      // Act
      final first = ServiceLocator.get<String>();
      final second = ServiceLocator.get<String>();

      // Assert
      expect(first, equals('Factory Service 1'));
      expect(second, equals('Factory Service 1')); // Same instance cached
      expect(callCount, equals(1)); // Factory called only once
    });

    test('should register singleton factory', () {
      // Arrange
      var callCount = 0;
      ServiceLocator.registerSingleton<String>(() {
        callCount++;
        return 'Singleton Service $callCount';
      });

      // Act
      final first = ServiceLocator.get<String>();
      final second = ServiceLocator.get<String>();

      // Assert
      expect(first, equals(second));
      expect(callCount, equals(1)); // Factory called only once
    });

    test('should check if service is registered', () {
      // Arrange
      ServiceLocator.register<String>('Test');

      // Act & Assert
      expect(ServiceLocator.isRegistered<String>(), isTrue);
      expect(ServiceLocator.isRegistered<int>(), isFalse);
    });

    test('should throw exception for unregistered service', () {
      // Act & Assert
      expect(
        () => ServiceLocator.get<String>(),
        throwsA(isA<ServiceNotRegisteredException>()),
      );
    });

    test('should unregister services', () {
      // Arrange
      ServiceLocator.register<String>('Test');
      expect(ServiceLocator.isRegistered<String>(), isTrue);

      // Act
      ServiceLocator.unregister<String>();

      // Assert
      expect(ServiceLocator.isRegistered<String>(), isFalse);
    });

    test('should clear all services', () {
      // Arrange
      ServiceLocator.register<String>('Test');
      ServiceLocator.register<int>(42);

      // Act
      ServiceLocator.clear();

      // Assert
      expect(ServiceLocator.isRegistered<String>(), isFalse);
      expect(ServiceLocator.isRegistered<int>(), isFalse);
    });

    test('should get registered types', () {
      // Arrange
      ServiceLocator.register<String>('Test');
      ServiceLocator.register<int>(42);

      // Act
      final types = ServiceLocator.getRegisteredTypes();

      // Assert
      expect(types, contains(String));
      expect(types, contains(int));
      expect(types.length, equals(2));
    });

    test('should handle complex service dependencies', () {
      // Arrange
      final mockTranslationService = MockTranslationService();
      final mockTTSService = MockTTSService();
      final mockConfigService = MockConfigurationService();

      // Act
      ServiceLocator.register<MockTranslationService>(mockTranslationService);
      ServiceLocator.register<MockTTSService>(mockTTSService);
      ServiceLocator.register<MockConfigurationService>(mockConfigService);

      // Assert
      expect(ServiceLocator.get<MockTranslationService>(), equals(mockTranslationService));
      expect(ServiceLocator.get<MockTTSService>(), equals(mockTTSService));
      expect(ServiceLocator.get<MockConfigurationService>(), equals(mockConfigService));
    });

    test('should handle service replacement', () {
      // Arrange
      final firstService = MockTranslationService();
      final secondService = MockTranslationService();

      ServiceLocator.register<MockTranslationService>(firstService);
      expect(ServiceLocator.get<MockTranslationService>(), equals(firstService));

      // Act - Replace service
      ServiceLocator.register<MockTranslationService>(secondService);

      // Assert
      expect(ServiceLocator.get<MockTranslationService>(), equals(secondService));
    });

    test('should handle factory service replacement', () {
      // Arrange
      var firstCallCount = 0;
      var secondCallCount = 0;

      ServiceLocator.registerFactory<String>(() {
        firstCallCount++;
        return 'First Factory $firstCallCount';
      });

      final firstResult = ServiceLocator.get<String>();
      expect(firstResult, equals('First Factory 1'));

      // Act - Replace factory
      ServiceLocator.registerFactory<String>(() {
        secondCallCount++;
        return 'Second Factory $secondCallCount';
      });

      // Assert
      final secondResult = ServiceLocator.get<String>();
      expect(secondResult, equals('Second Factory 1'));
      expect(firstCallCount, equals(1)); // First factory not called again
    });

    test('should handle lazy initialization correctly', () {
      // Arrange
      var initializationCount = 0;
      ServiceLocator.registerFactory<MockTranslationService>(() {
        initializationCount++;
        return MockTranslationService();
      });

      // Assert - Factory not called yet
      expect(initializationCount, equals(0));

      // Act - First access
      final service1 = ServiceLocator.get<MockTranslationService>();
      expect(initializationCount, equals(1));

      // Act - Second access (should use cached instance)
      final service2 = ServiceLocator.get<MockTranslationService>();
      expect(initializationCount, equals(1)); // Still 1, not called again
      expect(service1, equals(service2)); // Same instance
    });

    test('should handle service initialization order', () {
      // Arrange
      final initOrder = <String>[];

      ServiceLocator.registerFactory<MockConfigurationService>(() {
        initOrder.add('Config');
        return MockConfigurationService();
      });

      ServiceLocator.registerFactory<MockTranslationService>(() {
        initOrder.add('Translation');
        // Simulate dependency on config service
        ServiceLocator.get<MockConfigurationService>();
        return MockTranslationService();
      });

      ServiceLocator.registerFactory<MockTTSService>(() {
        initOrder.add('TTS');
        // Simulate dependency on config service
        ServiceLocator.get<MockConfigurationService>();
        return MockTTSService();
      });

      // Act
      ServiceLocator.get<MockTranslationService>();
      ServiceLocator.get<MockTTSService>();

      // Assert
      expect(initOrder, equals(['Translation', 'Config', 'TTS']));
    });

    test('should handle circular dependency detection', () {
      // Arrange - Create circular dependency scenario
      ServiceLocator.registerFactory<MockServiceA>(() {
        // This will try to get MockServiceB
        final serviceB = ServiceLocator.get<MockServiceB>();
        return MockServiceA(serviceB);
      });

      ServiceLocator.registerFactory<MockServiceB>(() {
        // This will try to get MockServiceA, creating a circular dependency
        final serviceA = ServiceLocator.get<MockServiceA>();
        return MockServiceB(serviceA);
      });

      // Act & Assert - Should handle gracefully or throw appropriate error
      expect(
        () => ServiceLocator.get<MockServiceA>(),
        throwsA(isA<StackOverflowError>()),
      );
    });

    test('should provide thread-safe access', () async {
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
      expect(initCount, equals(1)); // Factory called only once
      for (int i = 1; i < services.length; i++) {
        expect(services[i], equals(services[0]));
      }
    });

    test('should handle service disposal pattern', () {
      // Arrange
      final disposableService = MockDisposableService();
      ServiceLocator.register<MockDisposableService>(disposableService);

      // Act
      final retrieved = ServiceLocator.get<MockDisposableService>();
      expect(retrieved, equals(disposableService));

      // Simulate disposal
      ServiceLocator.unregister<MockDisposableService>();
      disposableService.dispose();

      // Assert
      expect(ServiceLocator.isRegistered<MockDisposableService>(), isFalse);
      expect(disposableService.isDisposed, isTrue);
    });

    test('should handle service locator initialization', () {
      // Act
      ServiceLocator.initialize();

      // Assert - Should have core services registered
      expect(ServiceLocator.isRegistered<LoggingService>(), isTrue);
    });

    test('should provide convenient logger access', () {
      // Act
      ServiceLocator.initialize();
      final logger = ServiceLocator.logger;

      // Assert
      expect(logger, isA<LoggingService>());
    });
  });

  group('Service Manager Tests', () {
    setUp(() async {
      await ServiceManager.reset();
    });

    tearDown(() async {
      await ServiceManager.dispose();
    });

    test('should initialize with configuration', () async {
      // Act
      final result = await ServiceManager.initialize(ServiceConfiguration.testing);

      // Assert
      expect(result.isSuccessful, isTrue);
      expect(ServiceManager.isInitialized, isTrue);
    });

    test('should get service status', () async {
      // Arrange
      await ServiceManager.initialize(ServiceConfiguration.testing);

      // Act
      final status = ServiceManager.getServiceStatus();

      // Assert
      expect(status, isA<Map<String, bool>>());
      expect(status.containsKey('TTS'), isTrue);
      expect(status.containsKey('Translation'), isTrue);
    });

    test('should provide initialization log', () async {
      // Act
      await ServiceManager.initialize(ServiceConfiguration.testing);
      final log = ServiceManager.getInitializationLog();

      // Assert
      expect(log, isA<List<String>>());
      expect(log.isNotEmpty, isTrue);
    });
  });

  group('Service Configuration Tests', () {
    test('should create predefined configurations', () {
      // Act & Assert
      expect(ServiceConfiguration.ttsOnly.initializeTTS, isTrue);
      expect(ServiceConfiguration.ttsOnly.initializeTranslation, isFalse);

      expect(ServiceConfiguration.translationOnly.initializeTTS, isFalse);
      expect(ServiceConfiguration.translationOnly.initializeTranslation, isTrue);

      expect(ServiceConfiguration.combined.initializeTTS, isTrue);
      expect(ServiceConfiguration.combined.initializeTranslation, isTrue);

      expect(ServiceConfiguration.testing.initializeTTS, isFalse);
      expect(ServiceConfiguration.testing.initializeTranslation, isFalse);
    });

    test('should create custom configuration', () {
      // Act
      const config = ServiceConfiguration(
        initializeTTS: true,
        initializeTranslation: false,
        ttsAutoFallback: false,
        verboseLogging: true,
        initializationTimeoutMs: 5000,
      );

      // Assert
      expect(config.initializeTTS, isTrue);
      expect(config.initializeTranslation, isFalse);
      expect(config.ttsAutoFallback, isFalse);
      expect(config.verboseLogging, isTrue);
      expect(config.initializationTimeoutMs, equals(5000));
    });
  });
}