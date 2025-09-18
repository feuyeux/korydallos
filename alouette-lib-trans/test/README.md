# Translation Library Unit Tests

This directory contains comprehensive unit tests for the alouette_lib_trans library.

## Test Files

### basic_unit_tests.dart
Basic unit tests covering core functionality:
- TranslationService initialization and configuration
- Provider management and validation
- LLMConfigService functionality
- TextProcessor utilities
- State management and statistics

### mocks/mock_translation_provider.dart
Mock implementation of TranslationProvider for testing:
- Configurable mock responses
- Error simulation
- Retry behavior testing
- Language-specific failure simulation

## Test Coverage

The unit tests cover:

1. **Service Initialization**
   - Default provider registration
   - Provider availability checking
   - Configuration validation

2. **Translation Operations**
   - Request creation and validation
   - State management
   - Statistics calculation

3. **Configuration Management**
   - LLM configuration validation
   - Recommended settings retrieval
   - Platform-specific configurations

4. **Text Processing**
   - Translation result cleaning
   - Prefix/suffix removal
   - Whitespace handling

5. **Error Handling**
   - Mock error simulation
   - Exception type validation
   - Recovery mechanisms

## Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/basic_unit_tests.dart

# Run with coverage
flutter test --coverage
```

## Mock Services

The mock translation provider supports:
- Configurable translation responses
- Error injection for testing failure scenarios
- Retry behavior simulation
- Connection status mocking
- Model list mocking

## Test Requirements Covered

✅ Unit tests for TranslationService with mocked providers
✅ Error handling and recovery mechanisms testing
✅ Service configuration and validation testing
✅ Text processing and utility function testing