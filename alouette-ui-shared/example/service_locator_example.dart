/// Example demonstrating how to use the Service Locator and Dependency Injection system
/// 
/// This example shows the basic usage patterns for the Alouette service architecture.

import '../lib/src/services/core/service_locator.dart';
import '../lib/src/services/core/service_manager.dart';
import '../lib/src/services/core/service_configuration.dart';

// Example service interface
abstract class IExampleService {
  String getMessage();
  void dispose();
}

// Example service implementation
class ExampleServiceImpl implements IExampleService {
  final String _message;
  
  ExampleServiceImpl(this._message);
  
  @override
  String getMessage() => _message;
  
  @override
  void dispose() {
    print('ExampleService disposed');
  }
}

void main() async {
  print('=== Service Locator Example ===\n');
  
  // Example 1: Basic service registration and retrieval
  print('1. Basic Service Registration:');
  ServiceLocator.register<IExampleService>(ExampleServiceImpl('Hello from basic service!'));
  final basicService = ServiceLocator.get<IExampleService>();
  print('   Message: ${basicService.getMessage()}');
  print('   Is registered: ${ServiceLocator.isRegistered<IExampleService>()}');
  
  // Clear for next example
  ServiceLocator.clear();
  print('');
  
  // Example 2: Factory registration
  print('2. Factory Registration:');
  var factoryCallCount = 0;
  ServiceLocator.registerFactory<IExampleService>(() {
    factoryCallCount++;
    return ExampleServiceImpl('Factory service call #$factoryCallCount');
  });
  
  final factoryService1 = ServiceLocator.get<IExampleService>();
  final factoryService2 = ServiceLocator.get<IExampleService>();
  print('   First call: ${factoryService1.getMessage()}');
  print('   Second call: ${factoryService2.getMessage()}');
  print('   Same instance: ${identical(factoryService1, factoryService2)}');
  
  ServiceLocator.clear();
  print('');
  
  // Example 3: Singleton factory registration
  print('3. Singleton Factory Registration:');
  var singletonCallCount = 0;
  ServiceLocator.registerSingleton<IExampleService>(() {
    singletonCallCount++;
    return ExampleServiceImpl('Singleton service call #$singletonCallCount');
  });
  
  final singletonService1 = ServiceLocator.get<IExampleService>();
  final singletonService2 = ServiceLocator.get<IExampleService>();
  print('   First call: ${singletonService1.getMessage()}');
  print('   Second call: ${singletonService2.getMessage()}');
  print('   Same instance: ${identical(singletonService1, singletonService2)}');
  print('   Factory called: $singletonCallCount times');
  
  ServiceLocator.clear();
  print('');
  
  // Example 4: Service Manager usage
  print('4. Service Manager Usage:');
  
  // Initialize with testing configuration (no actual services)
  final initResult = await ServiceManager.initialize(ServiceConfiguration.testing);
  print('   Initialization successful: ${initResult.isSuccessful}');
  print('   Duration: ${initResult.durationMs}ms');
  print('   Service status: ${ServiceManager.getServiceStatus()}');
  
  // Get initialization log
  final log = ServiceManager.getInitializationLog();
  print('   Initialization log: ${log.join(' -> ')}');
  
  await ServiceManager.dispose();
  print('');
  
  // Example 5: Different service configurations
  print('5. Service Configurations:');
  
  final configs = [
    ('TTS Only', ServiceConfiguration.ttsOnly),
    ('Translation Only', ServiceConfiguration.translationOnly),
    ('Combined', ServiceConfiguration.combined),
    ('Testing', ServiceConfiguration.testing),
    ('Debug', ServiceConfiguration.debug),
  ];
  
  for (final (name, config) in configs) {
    print('   $name: TTS=${config.initializeTTS}, Translation=${config.initializeTranslation}, Verbose=${config.verboseLogging}');
  }
  
  print('');
  
  // Example 6: Error handling
  print('6. Error Handling:');
  
  try {
    ServiceLocator.get<String>(); // This should throw
  } catch (e) {
    print('   Expected error: $e');
  }
  
  // Example 7: Service inspection
  print('');
  print('7. Service Inspection:');
  
  ServiceLocator.register<String>('Test String');
  ServiceLocator.register<int>(42);
  ServiceLocator.registerFactory<double>(() => 3.14);
  
  final registeredTypes = ServiceLocator.getRegisteredTypes();
  print('   Registered types: ${registeredTypes.map((t) => t.toString()).join(', ')}');
  
  print('   String registered: ${ServiceLocator.isRegistered<String>()}');
  print('   bool registered: ${ServiceLocator.isRegistered<bool>()}');
  
  // Cleanup
  ServiceLocator.clear();
  
  print('\n=== Example Complete ===');
}