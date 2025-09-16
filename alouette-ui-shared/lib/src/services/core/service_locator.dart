/// Service Locator for Dependency Injection
///
/// Provides a simple service locator pattern for managing dependencies
/// across all Alouette applications. This enables loose coupling and
/// easier testing by allowing services to be mocked.
class ServiceLocator {
  static final Map<Type, dynamic> _services = {};
  static final Map<Type, dynamic Function()> _factories = {};

  /// Register a service instance
  ///
  /// [service] - The service instance to register
  /// Type T will be used as the key for retrieval
  static void register<T>(T service) {
    _services[T] = service;
  }

  /// Register a factory function for lazy service creation
  ///
  /// [factory] - Function that creates the service instance
  /// The service will be created when first accessed
  static void registerFactory<T>(T Function() factory) {
    _factories[T] = factory;
  }

  /// Register a singleton factory
  ///
  /// [factory] - Function that creates the service instance
  /// The same instance will be returned for all subsequent calls
  static void registerSingleton<T>(T Function() factory) {
    T? instance;
    _factories[T] = () {
      instance ??= factory();
      return instance!;
    };
  }

  /// Get a service instance
  ///
  /// Returns the registered service of type T.
  /// If the service is not registered, throws a ServiceNotRegisteredException.
  /// If a factory is registered, creates the instance on first access.
  static T get<T>() {
    // Check if instance is already created
    final service = _services[T];
    if (service != null) {
      return service as T;
    }

    // Check if factory is available
    final factory = _factories[T];
    if (factory != null) {
      final instance = factory() as T;
      _services[T] = instance;
      return instance;
    }

    throw ServiceNotRegisteredException(
      'Service of type $T is not registered. '
      'Please register it using ServiceLocator.register<$T>() or '
      'ServiceLocator.registerFactory<$T>()',
    );
  }

  /// Check if a service is registered
  ///
  /// Returns true if a service of type T is registered
  static bool isRegistered<T>() {
    return _services.containsKey(T) || _factories.containsKey(T);
  }

  /// Unregister a service
  ///
  /// Removes the service of type T from the locator
  static void unregister<T>() {
    _services.remove(T);
    _factories.remove(T);
  }

  /// Clear all registered services
  ///
  /// Useful for testing or when resetting the application state
  static void clear() {
    _services.clear();
    _factories.clear();
  }

  /// Get all registered service types
  ///
  /// Returns a list of all registered service types (for debugging)
  static List<Type> getRegisteredTypes() {
    final types = <Type>{};
    types.addAll(_services.keys);
    types.addAll(_factories.keys);
    return types.toList();
  }
}

/// Exception thrown when trying to access a service that is not registered
class ServiceNotRegisteredException implements Exception {
  final String message;

  const ServiceNotRegisteredException(this.message);

  @override
  String toString() => 'ServiceNotRegisteredException: $message';
}
