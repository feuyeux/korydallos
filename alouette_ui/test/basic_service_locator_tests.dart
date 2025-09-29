import 'package:flutter_test/flutter_test.dart';
import '../lib/src/services/core/service_locator.dart';

// Simple mock services for testing
class MockService {
  final String name;
  bool _initialized = false;
  
  MockService(this.name);
  
  void initialize() {
    _initialized = true;
  }
  
  bool get isInitialized => _initialized;
}

class MockDisposableService {
  bool _disposed = false;
  
  bool get isDisposed => _disposed;
  
  void dispose() {
    _disposed = true;
  }
}

void main() {
  group('Basic Service Locator Unit Tests', () {
    setUp(() {
      ServiceLocator.clear();
    });

    tearDown(() {
      ServiceLocator.clear();
    });

    test('should register and retrieve services', () {
      final testService = MockService('test');

      ServiceLocator.register<MockService>(testService);
      final retrieved = ServiceLocator.get<MockService>();

      expect(retrieved, equals(testService));
      expect(retrieved.name, equals('test'));
    });

    test('should register factory and create instances', () {
      var callCount = 0;
      ServiceLocator.registerFactory<MockService>(() {
        callCount++;
        return MockService('factory-$callCount');
      });

      final first = ServiceLocator.get<MockService>();
      final second = ServiceLocator.get<MockService>();

      expect(first.name, equals('factory-1'));
      expect(second, equals(first)); // Same instance cached
      expect(callCount, equals(1)); // Factory called only once
    });

    test('should register singleton factory', () {
      var callCount = 0;
      ServiceLocator.registerSingleton<MockService>(() {
        callCount++;
        return MockService('singleton-$callCount');
      });

      final first = ServiceLocator.get<MockService>();
      final second = ServiceLocator.get<MockService>();

      expect(first, equals(second));
      expect(callCount, equals(1)); // Factory called only once
    });

    test('should check if service is registered', () {
      ServiceLocator.register<MockService>(MockService('test'));

      expect(ServiceLocator.isRegistered<MockService>(), isTrue);
      expect(ServiceLocator.isRegistered<String>(), isFalse);
    });

    test('should throw exception for unregistered service', () {
      expect(
        () => ServiceLocator.get<MockService>(),
        throwsA(isA<ServiceNotRegisteredException>()),
      );
    });

    test('should unregister services', () {
      ServiceLocator.register<MockService>(MockService('test'));
      expect(ServiceLocator.isRegistered<MockService>(), isTrue);

      ServiceLocator.unregister<MockService>();

      expect(ServiceLocator.isRegistered<MockService>(), isFalse);
    });

    test('should clear all services', () {
      ServiceLocator.register<MockService>(MockService('test'));
      ServiceLocator.register<String>('test-string');

      ServiceLocator.clear();

      expect(ServiceLocator.isRegistered<MockService>(), isFalse);
      expect(ServiceLocator.isRegistered<String>(), isFalse);
    });

    test('should get registered types', () {
      ServiceLocator.register<MockService>(MockService('test'));
      ServiceLocator.register<String>('test-string');

      final types = ServiceLocator.getRegisteredTypes();

      expect(types, contains(MockService));
      expect(types, contains(String));
      expect(types.length, equals(2));
    });

    test('should handle service replacement', () {
      final firstService = MockService('first');
      final secondService = MockService('second');

      ServiceLocator.register<MockService>(firstService);
      expect(ServiceLocator.get<MockService>(), equals(firstService));

      ServiceLocator.register<MockService>(secondService);
      expect(ServiceLocator.get<MockService>(), equals(secondService));
    });

    test('should handle factory service replacement', () {
      var firstCallCount = 0;
      var secondCallCount = 0;

      ServiceLocator.registerFactory<MockService>(() {
        firstCallCount++;
        return MockService('first-$firstCallCount');
      });

      final firstResult = ServiceLocator.get<MockService>();
      expect(firstResult.name, equals('first-1'));

      // Clear the cached instance before replacing factory
      ServiceLocator.unregister<MockService>();
      
      ServiceLocator.registerFactory<MockService>(() {
        secondCallCount++;
        return MockService('second-$secondCallCount');
      });

      final secondResult = ServiceLocator.get<MockService>();
      expect(secondResult.name, equals('second-1'));
      expect(firstCallCount, equals(1)); // First factory not called again
    });

    test('should handle lazy initialization correctly', () {
      var initializationCount = 0;
      ServiceLocator.registerFactory<MockService>(() {
        initializationCount++;
        return MockService('lazy-$initializationCount');
      });

      expect(initializationCount, equals(0));

      final service1 = ServiceLocator.get<MockService>();
      expect(initializationCount, equals(1));

      final service2 = ServiceLocator.get<MockService>();
      expect(initializationCount, equals(1)); // Still 1, not called again
      expect(service1, equals(service2)); // Same instance
    });

    test('should handle service disposal pattern', () {
      final disposableService = MockDisposableService();
      ServiceLocator.register<MockDisposableService>(disposableService);

      final retrieved = ServiceLocator.get<MockDisposableService>();
      expect(retrieved, equals(disposableService));

      ServiceLocator.unregister<MockDisposableService>();
      disposableService.dispose();

      expect(ServiceLocator.isRegistered<MockDisposableService>(), isFalse);
      expect(disposableService.isDisposed, isTrue);
    });

    test('should handle concurrent service access', () async {
      var initCount = 0;
      ServiceLocator.registerFactory<MockService>(() {
        initCount++;
        return MockService('concurrent-$initCount');
      });

      final futures = List.generate(10, (index) async {
        return ServiceLocator.get<MockService>();
      });

      final services = await Future.wait(futures);

      expect(initCount, equals(1));
      for (int i = 1; i < services.length; i++) {
        expect(services[i], equals(services[0]));
      }
    });

    test('should handle multiple service types', () {
      final mockService = MockService('test');
      final stringService = 'test-string';
      final intService = 42;

      ServiceLocator.register<MockService>(mockService);
      ServiceLocator.register<String>(stringService);
      ServiceLocator.register<int>(intService);

      expect(ServiceLocator.get<MockService>(), equals(mockService));
      expect(ServiceLocator.get<String>(), equals(stringService));
      expect(ServiceLocator.get<int>(), equals(intService));
    });

    test('should handle service dependencies', () {
      ServiceLocator.registerSingleton<String>(() => 'config-value');

      ServiceLocator.registerFactory<MockService>(() {
        final config = ServiceLocator.get<String>();
        return MockService(config);
      });

      final service = ServiceLocator.get<MockService>();
      expect(service.name, equals('config-value'));
    });
  });

  group('Service Locator Exception Tests', () {
    setUp(() {
      ServiceLocator.clear();
    });

    test('should provide meaningful error messages', () {
      try {
        ServiceLocator.get<MockService>();
        fail('Expected exception to be thrown');
      } catch (e) {
        expect(e, isA<ServiceNotRegisteredException>());
        expect(e.toString(), contains('MockService'));
        expect(e.toString(), contains('not registered'));
      }
    });

    test('should handle exception in factory', () {
      ServiceLocator.registerFactory<MockService>(() {
        throw Exception('Factory failed');
      });

      expect(
        () => ServiceLocator.get<MockService>(),
        throwsA(isA<Exception>()),
      );
    });
  });
}