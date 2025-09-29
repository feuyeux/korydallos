# Alouette Main App - Integration Tests

This directory contains comprehensive integration tests for the Alouette main application, which combines both translation and TTS functionality.

## Test Structure

### Test Files

- **`app_test.dart`** - Basic app initialization and navigation tests
- **`translation_workflow_test.dart`** - Translation functionality with real LLM providers
- **`tts_workflow_test.dart`** - TTS functionality with platform-specific engines
- **`combined_workflow_test.dart`** - End-to-end tests combining translation and TTS
- **`cross_platform_test.dart`** - Cross-platform compatibility and engine switching tests
- **`test_runner.dart`** - Runs all integration tests in sequence

### Test Coverage

#### Translation Workflow Tests
- Complete translation workflow with real LLM providers (Ollama, LM Studio)
- Multiple language translation
- Translation error handling and recovery
- Translation service provider switching
- LLM configuration and connection testing

#### TTS Workflow Tests
- Complete TTS workflow with platform-specific engines
- TTS engine switching and fallback (Edge TTS ↔ Flutter TTS)
- Voice selection and configuration
- TTS playback controls (play, pause, stop)
- TTS error handling and recovery
- Cross-platform TTS engine compatibility

#### Combined Workflow Tests
- End-to-end translation + TTS workflow
- Multi-language translation with TTS for each language
- Service coordination and state management
- Performance and memory management during combined operations
- Error recovery in combined workflows

#### Cross-Platform Tests
- Platform detection and automatic engine selection
- TTS engine switching across platforms (Desktop: Edge TTS, Mobile/Web: Flutter TTS)
- Voice availability across platforms
- Translation service cross-platform compatibility
- UI responsiveness across different screen sizes
- Performance testing across platforms

## Prerequisites

### For Translation Tests
1. **LLM Provider Setup** (choose one):
   - **Ollama**: Install and run Ollama with a model (e.g., `ollama run llama2`)
   - **LM Studio**: Install and run LM Studio with a loaded model

2. **Network Configuration**:
   - Ollama default: `http://localhost:11434`
   - LM Studio default: `http://localhost:1234`
   - For mobile testing: Use `http://10.0.2.2:11434` (Android emulator)

### For TTS Tests
1. **Desktop Platforms** (Windows/macOS/Linux):
   - Edge TTS will be automatically detected and used as primary engine
   - Flutter TTS available as fallback

2. **Mobile Platforms** (Android/iOS):
   - System TTS engines will be used through Flutter TTS
   - Ensure device has TTS voices installed

3. **Web Platform**:
   - Web Speech API will be used through Flutter TTS
   - Browser must support Web Speech API

## Running the Tests

### Run All Integration Tests
```bash
# Navigate to the app directory
cd alouette-app

# Run all integration tests
flutter test integration_test/test_runner.dart
```

### Run Individual Test Suites
```bash
# Basic app tests
flutter test integration_test/app_test.dart

# Translation workflow tests
flutter test integration_test/translation_workflow_test.dart

# TTS workflow tests
flutter test integration_test/tts_workflow_test.dart

# Combined workflow tests
flutter test integration_test/combined_workflow_test.dart

# Cross-platform tests
flutter test integration_test/cross_platform_test.dart
```

### Platform-Specific Testing

#### Desktop Testing
```bash
# Windows
flutter test integration_test/ -d windows

# macOS
flutter test integration_test/ -d macos

# Linux
flutter test integration_test/ -d linux
```

#### Mobile Testing
```bash
# Android (device or emulator)
flutter test integration_test/ -d android

# iOS (device or simulator)
flutter test integration_test/ -d ios
```

#### Web Testing
```bash
# Chrome
flutter test integration_test/ -d chrome

# Firefox
flutter test integration_test/ -d firefox
```

## Test Configuration

### Environment Variables
You can set environment variables to configure test behavior:

```bash
# Set LLM provider URL
export ALOUETTE_LLM_URL="http://localhost:11434"

# Set preferred TTS engine
export ALOUETTE_TTS_ENGINE="edge"  # or "flutter"

# Enable debug logging
export ALOUETTE_DEBUG="true"
```

### Test Timeouts
The tests include appropriate timeouts for different operations:
- Translation requests: 10-20 seconds
- TTS synthesis: 3-5 seconds
- Engine switching: 2-3 seconds
- Voice loading: 3-5 seconds

## Troubleshooting

### Common Issues

1. **Translation Tests Fail**:
   - Ensure LLM provider is running and accessible
   - Check network connectivity
   - Verify server URL configuration
   - Check firewall settings

2. **TTS Tests Fail**:
   - Ensure system has TTS voices installed
   - Check audio system is working
   - Verify platform-specific TTS engines are available

3. **Cross-Platform Tests Fail**:
   - Ensure platform detection is working correctly
   - Check engine availability on target platform
   - Verify UI adapts to screen size correctly

4. **Performance Issues**:
   - Run tests on release builds for better performance
   - Ensure sufficient system resources
   - Check for memory leaks in long-running tests

### Debug Mode
To run tests with additional debugging:

```bash
flutter test integration_test/ --verbose
```

### Test Reports
Integration test results are automatically generated. For detailed reports:

```bash
flutter test integration_test/ --reporter=json > test_results.json
```

## Requirements Coverage

These integration tests cover the following requirements from the specification:

- **Requirement 9.1**: Existing functionality preservation during refactoring
- **Requirement 9.3**: Integration tests for key user flows
- **Cross-platform compatibility**: Engine switching and platform-specific behavior
- **Service integration**: Translation and TTS services working together
- **Error handling**: Graceful error recovery and fallback mechanisms
- **Performance**: Memory management and responsiveness testing

## Continuous Integration

For CI/CD pipelines, use headless testing:

```bash
# Headless web testing
flutter test integration_test/ -d web-server --web-port=7357

# Android emulator testing
flutter test integration_test/ -d android --headless
```