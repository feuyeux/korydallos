# UI Shared Library Unit Tests

This directory contains comprehensive unit tests for the alouette_ui_shared library.

## Test Files

### basic_service_locator_tests.dart
Comprehensive unit tests for the ServiceLocator dependency injection system:
- Service registration and retrieval
- Factory pattern implementation
- Singleton pattern implementation
- Service lifecycle management
- Concurrent access handling
- Error scenarios and exception handling

### service_locator_test.dart
Extended ServiceLocator tests with complex scenarios:
- Service dependencies and initialization order
- Service replacement during runtime
- Circular dependency detection
- Thread-safe access patterns
- Service disposal patterns

### service_integration_test.dart
Integration tests for service interactions:
- Multi-service initialization
- Service dependency chains
- Configuration-driven service management
- ServiceManager integration
- Cross-service communication patterns

### configuration_service_test.dart
Tests for configuration management:
- Configuration validation
- Settings persistence
- Theme and UI preference management
- Import/export functionality
- First launch detection

### mocks/mock_services.dart
Mock implementations for testing:
- MockTranslationService
- MockTTSService
- MockConfigurationService
- MockDisposableService
- LoggingService

## Test Coverage

The unit tests cover:

1. **Dependency Injection**
   - Service registration (instance, factory, singleton)
   - Service retrieval and caching
   - Type safety and error handling
   - Service lifecycle management

2. **Service Management**
   - Initialization order and dependencies
   - Configuration-driven setup
   - Service status monitoring
   - Graceful failure handling

3. **Configuration Management**
   - Settings validation and persistence
   - UI preferences management
   - Theme switching
   - Import/export functionality

4. **Error Handling**
   - Unregistered service access
   - Factory failures
   - Circular dependencies
   - Concurrent access safety

5. **Integration Scenarios**
   - Multi-service workflows
   - Service replacement
   - Configuration changes
   - Cleanup and disposal

## Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/basic_service_locator_tests.dart

# Run with coverage
flutter test --coverage
```

## Mock Services

The mock services support:
- Configurable initialization behavior
- Dependency simulation
- Error injection for testing failure scenarios
- State tracking for verification
- Disposal pattern testing

## Test Requirements Covered

✅ Unit tests for ServiceLocator and dependency injection
✅ Service lifecycle and management testing
✅ Configuration service testing
✅ Error handling and recovery mechanisms testing
✅ Integration testing for service interactions