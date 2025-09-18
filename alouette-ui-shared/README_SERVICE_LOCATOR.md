# Service Locator and Dependency Injection

This document describes the Service Locator and Dependency Injection system implemented for the Alouette UI Shared library.

## Overview

The service locator provides a centralized way to manage dependencies across all Alouette applications. It enables loose coupling between components and makes testing easier by allowing services to be mocked.

## Key Components

### 1. ServiceLocator

The core service locator class that manages service registration and retrieval.

```dart
// Register a service instance
ServiceLocator.register<MyService>(MyServiceImpl());

// Register a factory for lazy creation
ServiceLocator.registerFactory<MyService>(() => MyServiceImpl());

// Register a singleton factory
ServiceLocator.registerSingleton<MyService>(() => MyServiceImpl());

// Get a service
final service = ServiceLocator.get<MyService>();

// Check if registered
if (ServiceLocator.isRegistered<MyService>()) {
  // Service is available
}
```

### 2. ServiceManager

High-level service management with lifecycle control and configuration.

```dart
// Initialize with configuration
final result = await ServiceManager.initialize(ServiceConfiguration.combined);

// Get services
final ttsService = ServiceManager.getTTSService();
final translationService = ServiceManager.getTranslationService();

// Check status
final status = ServiceManager.getServiceStatus();
print('TTS Available: ${status['TTS']}');
print('Translation Available: ${status['Translation']}');

// Dispose when done
await ServiceManager.dispose();
```

### 3. ServiceConfiguration

Predefined configurations for different application types.

```dart
// For TTS-only applications
ServiceConfiguration.ttsOnly

// For translation-only applications  
ServiceConfiguration.translationOnly

// For combined applications
ServiceConfiguration.combined

// For testing (no services)
ServiceConfiguration.testing

// Custom configuration
const config = ServiceConfiguration(
  initializeTTS: true,
  initializeTranslation: false,
  ttsAutoFallback: true,
  verboseLogging: true,
  initializationTimeoutMs: 10000,
);
```

### 4. ServiceHealthMonitor

Monitor service health and status.

```dart
// Start monitoring
ServiceHealthMonitor.startMonitoring(intervalSeconds: 30);

// Manual health check
final report = await ServiceHealthMonitor.performHealthCheck();
print('Overall healthy: ${report.isOverallHealthy}');

// Listen to health reports
ServiceHealthMonitor.healthReportStream.listen((report) {
  print('Health update: ${report.getSummary()}');
});

// Stop monitoring
ServiceHealthMonitor.stopMonitoring();
```

## Service Interfaces

### TTS Service Interface

```dart
abstract class ITTSService {
  Future<bool> initialize({bool autoFallback = true});
  Future<void> speak(String text, {String? voiceName});
  Future<void> stop();
  Future<List<TTSVoice>> getAvailableVoices();
  bool get isInitialized;
  void dispose();
}
```

### Translation Service Interface

```dart
abstract class ITranslationService {
  Future<bool> initialize();
  Future<String> translate({
    required String text,
    String? sourceLanguage,
    required String targetLanguage,
  });
  Future<Map<String, String>> translateToMultiple({
    required String text,
    String? sourceLanguage,
    required List<String> targetLanguages,
  });
  Future<List<LanguageInfo>> getSupportedLanguages();
  bool get isInitialized;
  void dispose();
}
```

## Usage Examples

### Basic Application Setup

```dart
void main() async {
  // Initialize services for a combined app
  final result = await ServiceManager.initialize(ServiceConfiguration.combined);
  
  if (result.isSuccessful) {
    runApp(MyApp());
  } else {
    print('Failed to initialize services: ${result.errors}');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}
```

### Using Services in Widgets

```dart
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late ITTSService _ttsService;
  late ITranslationService _translationService;

  @override
  void initState() {
    super.initState();
    _ttsService = ServiceManager.getTTSService();
    _translationService = ServiceManager.getTranslationService();
  }

  Future<void> _speakText(String text) async {
    await _ttsService.speak(text);
  }

  Future<void> _translateText(String text) async {
    final result = await _translationService.translate(
      text: text,
      targetLanguage: 'es',
    );
    print('Translation: $result');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Alouette App')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => _speakText('Hello World'),
            child: Text('Speak'),
          ),
          ElevatedButton(
            onPressed: () => _translateText('Hello World'),
            child: Text('Translate'),
          ),
        ],
      ),
    );
  }
}
```

### Testing with Mock Services

```dart
class MockTTSService implements ITTSService {
  @override
  Future<bool> initialize({bool autoFallback = true}) async => true;
  
  @override
  Future<void> speak(String text, {String? voiceName}) async {
    print('Mock speaking: $text');
  }
  
  @override
  Future<List<TTSVoice>> getAvailableVoices() async => [
    TTSVoice(name: 'mock-voice', language: 'en-US'),
  ];
  
  // ... other methods
}

void main() {
  group('Widget Tests', () {
    setUp(() {
      // Register mock services
      ServiceLocator.register<ITTSService>(MockTTSService());
    });

    tearDown(() {
      ServiceLocator.clear();
    });

    testWidgets('should speak text', (tester) async {
      // Test with mock service
    });
  });
}
```

### Helper Extensions

The ServiceManager provides helper extensions for quick access:

```dart
// Quick TTS access
await ServiceManagerHelpers.speak('Hello World');
await ServiceManagerHelpers.stopSpeaking();
final voices = await ServiceManagerHelpers.getVoices();

// Quick translation access
final translation = await ServiceManagerHelpers.translate(
  text: 'Hello',
  targetLanguage: 'es',
);

final multiTranslation = await ServiceManagerHelpers.translateToMultiple(
  text: 'Hello',
  targetLanguages: ['es', 'fr', 'de'],
);
```

## Error Handling

The service locator provides comprehensive error handling:

```dart
try {
  final service = ServiceLocator.get<MyService>();
} catch (e) {
  if (e is ServiceNotRegisteredException) {
    print('Service not registered: ${e.message}');
  }
}

// Check before using
if (ServiceManager.isServiceAvailable<ITTSService>()) {
  final ttsService = ServiceManager.getTTSService();
  // Use service safely
}
```

## Best Practices

1. **Initialize Early**: Call `ServiceManager.initialize()` in your app's main function
2. **Use Interfaces**: Always depend on interfaces, not concrete implementations
3. **Check Availability**: Use `isServiceAvailable()` before accessing services
4. **Proper Disposal**: Call `ServiceManager.dispose()` when shutting down
5. **Testing**: Use mock services for unit tests
6. **Configuration**: Choose appropriate configuration for your application type

## Architecture Benefits

- **Loose Coupling**: Applications depend on interfaces, not implementations
- **Testability**: Easy to mock services for testing
- **Flexibility**: Can swap implementations without changing application code
- **Centralized Management**: Single point of control for all services
- **Lifecycle Management**: Proper initialization and disposal of services
- **Health Monitoring**: Built-in service health checking
- **Configuration**: Flexible configuration for different application types