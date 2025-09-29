/// Mock services for testing ServiceLocator functionality

class MockTranslationService {
  bool _isInitialized = false;
  
  bool get isInitialized => _isInitialized;
  
  void initialize() {
    _isInitialized = true;
  }
  
  Future<String> translate(String text, String targetLanguage) async {
    if (!_isInitialized) {
      throw Exception('Service not initialized');
    }
    return 'Mock translation of "$text" to $targetLanguage';
  }
}

class MockTTSService {
  bool _isInitialized = false;
  
  bool get isInitialized => _isInitialized;
  
  void initialize() {
    _isInitialized = true;
  }
  
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      throw Exception('Service not initialized');
    }
    // Mock TTS operation
  }
}

class MockConfigurationService {
  final Map<String, dynamic> _config = {};
  
  void setConfig(String key, dynamic value) {
    _config[key] = value;
  }
  
  T? getConfig<T>(String key) {
    return _config[key] as T?;
  }
  
  Map<String, dynamic> getAllConfig() {
    return Map.from(_config);
  }
}

class MockDisposableService {
  bool _isDisposed = false;
  
  bool get isDisposed => _isDisposed;
  
  void dispose() {
    _isDisposed = true;
  }
  
  void doSomething() {
    if (_isDisposed) {
      throw Exception('Service has been disposed');
    }
    // Mock operation
  }
}

class MockServiceA {
  final MockServiceB? serviceB;
  
  MockServiceA(this.serviceB);
}

class MockServiceB {
  final MockServiceA? serviceA;
  
  MockServiceB(this.serviceA);
}

/// Mock logging service for testing
class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  static LoggingService get instance => _instance;
  
  LoggingService._internal();
  
  final List<String> _logs = [];
  
  List<String> get logs => List.unmodifiable(_logs);
  
  void info(String message, {String? tag}) {
    _logs.add('[INFO]${tag != null ? '[$tag]' : ''} $message');
  }
  
  void debug(String message, {String? tag}) {
    _logs.add('[DEBUG]${tag != null ? '[$tag]' : ''} $message');
  }
  
  void warning(String message, {String? tag}) {
    _logs.add('[WARNING]${tag != null ? '[$tag]' : ''} $message');
  }
  
  void error(String message, {String? tag}) {
    _logs.add('[ERROR]${tag != null ? '[$tag]' : ''} $message');
  }
  
  void clear() {
    _logs.clear();
  }
}