# TTS Library Unit Tests

This directory contains comprehensive unit tests for the alouette_lib_tts library.

## Test Files

### basic_unit_tests.dart
Basic unit tests covering core functionality:
- TTSService initialization and lifecycle
- Platform detection and strategy selection
- Engine availability and configuration
- Voice model management
- Error handling for uninitialized service

### mocks/mock_tts_processor.dart
Mock implementation of TTSProcessor for testing:
- Configurable voice lists
- Audio synthesis simulation
- Error injection capabilities
- Parameter tracking for verification

### mocks/mock_tts_engine_factory.dart
Mock implementation of TTSEngineFactory for testing:
- Engine creation simulation
- Platform-specific behavior testing
- Availability checking
- Error injection for initialization failures

## Test Coverage

The unit tests cover:

1. **Service Lifecycle**
   - Initialization states
   - Disposal handling
   - Multiple disposal safety

2. **Platform Detection**
   - Platform information retrieval
   - Strategy selection
   - Engine recommendation
   - Fallback engine lists

3. **Engine Management**
   - Engine availability checking
   - Configuration retrieval
   - Factory operations

4. **Voice Management**
   - Voice model creation
   - Serialization/deserialization
   - Property validation

5. **Strategy Testing**
   - Desktop strategy (Edge TTS preference)
   - Mobile strategy (Flutter TTS only)
   - Web strategy (Flutter TTS only)
   - Platform-appropriate engine selection

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

The mock TTS components support:
- Configurable voice responses
- Audio synthesis simulation
- Error injection for testing failure scenarios
- Engine availability simulation
- Platform behavior mocking

## Test Requirements Covered

✅ Unit tests for UnifiedTTSService with different engine types
✅ Platform-specific engine selection testing
✅ Error handling and recovery mechanisms testing
✅ Voice model and configuration testing