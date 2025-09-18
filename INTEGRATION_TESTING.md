# Alouette Integration Testing Guide

This document provides comprehensive guidance for running integration tests across all Alouette applications.

## Overview

The Alouette project includes comprehensive integration tests that verify:
- **Translation workflows** with real LLM providers (Ollama, LM Studio)
- **TTS functionality** with platform-specific engines (Edge TTS, Flutter TTS)
- **Cross-platform compatibility** and engine switching
- **Combined workflows** integrating translation and TTS
- **Error handling and recovery** mechanisms
- **Performance and memory management**

## Test Structure

### Applications Tested
1. **Alouette Main App** (`alouette-app`) - Combined translation and TTS functionality
2. **Alouette Translation App** (`alouette-app-trans`) - Specialized translation features
3. **Alouette TTS App** (`alouette-app-tts`) - Specialized text-to-speech features

### Test Categories
- **Unit Integration Tests** - Service initialization and basic functionality
- **Workflow Tests** - Complete user workflows and feature interactions
- **Cross-Platform Tests** - Platform-specific behavior and compatibility
- **Performance Tests** - Memory management and responsiveness
- **Error Recovery Tests** - Graceful error handling and fallback mechanisms

## Prerequisites

### Development Environment
```bash
# Flutter SDK (latest stable)
flutter --version

# Ensure all applications can build
flutter doctor
```

### For Translation Tests

#### Option 1: Ollama Setup
```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Pull and run a model
ollama pull llama2
ollama run llama2

# Verify Ollama is running
curl http://localhost:11434/api/tags
```

#### Option 2: LM Studio Setup
1. Download and install [LM Studio](https://lmstudio.ai/)
2. Load a compatible model (e.g., Llama 2, Mistral)
3. Start the local server (default: http://localhost:1234)
4. Verify server is running:
   ```bash
   curl http://localhost:1234/v1/models
   ```

### For TTS Tests

#### Desktop Platforms
- **Windows**: Edge TTS automatically available (Windows 10/11)
- **macOS**: System TTS via Flutter TTS
- **Linux**: Install espeak or festival
  ```bash
  sudo apt-get install espeak espeak-data
  # or
  sudo apt-get install festival festvox-kallpc16k
  ```

#### Mobile Platforms
- **Android**: Ensure Google TTS or Samsung TTS is installed
- **iOS**: Built-in system TTS (no additional setup)

#### Web Platform
- **Browsers**: Chrome, Firefox, Safari, Edge (Web Speech API support)

## Running Tests

### Quick Start

#### Run All Tests (Recommended)
```bash
# Windows (PowerShell)
.\run_integration_tests.ps1

# macOS/Linux (Bash)
./run_integration_tests.sh
```

#### Run Specific Application Tests
```bash
# Main app only
.\run_integration_tests.ps1 -App main

# Translation app only
.\run_integration_tests.ps1 -App trans

# TTS app only
.\run_integration_tests.ps1 -App tts
```

#### Run on Specific Platform
```bash
# Android
.\run_integration_tests.ps1 -Platform android

# Web (Chrome)
.\run_integration_tests.ps1 -Platform chrome

# Windows desktop
.\run_integration_tests.ps1 -Platform windows
```

### Manual Test Execution

#### Individual Application Tests
```bash
# Main application
cd alouette-app
flutter test integration_test/test_runner.dart

# Translation application
cd alouette-app-trans
flutter test integration_test/test_runner.dart

# TTS application
cd alouette-app-tts
flutter test integration_test/test_runner.dart
```

#### Specific Test Files
```bash
# Translation workflow tests
cd alouette-app
flutter test integration_test/translation_workflow_test.dart

# TTS workflow tests
cd alouette-app
flutter test integration_test/tts_workflow_test.dart

# Cross-platform tests
cd alouette-app
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
# Android (device or emulator must be connected)
flutter test integration_test/ -d android

# iOS (device or simulator must be connected)
flutter test integration_test/ -d ios
```

#### Web Testing
```bash
# Chrome
flutter test integration_test/ -d chrome

# Firefox
flutter test integration_test/ -d firefox

# Headless web testing
flutter test integration_test/ -d web-server --web-port=7357
```

## Test Configuration

### Environment Variables

#### Translation Configuration
```bash
# LLM Provider URL
export ALOUETTE_LLM_URL="http://localhost:11434"

# Preferred provider
export ALOUETTE_PROVIDER="ollama"  # or "lmstudio"

# Enable debug logging
export ALOUETTE_DEBUG="true"
```

#### TTS Configuration
```bash
# Preferred TTS engine
export ALOUETTE_TTS_ENGINE="edge"     # or "flutter"

# Voice preferences
export ALOUETTE_TTS_VOICE="en-US-AriaNeural"

# TTS parameters
export ALOUETTE_TTS_RATE="1.0"       # Speech rate
export ALOUETTE_TTS_PITCH="1.0"      # Voice pitch
export ALOUETTE_TTS_VOLUME="1.0"     # Audio volume
```

### Test Timeouts
Default timeouts are configured for different operations:
- **Translation requests**: 10-20 seconds
- **TTS synthesis**: 3-5 seconds
- **Engine switching**: 2-3 seconds
- **Voice loading**: 3-5 seconds
- **App initialization**: 5 seconds

## Test Scenarios

### Translation Workflow Tests
1. **LLM Configuration**
   - Ollama provider setup and connection testing
   - LM Studio provider setup and connection testing
   - Configuration persistence and validation

2. **Translation Operations**
   - Single language translation
   - Multiple language translation (batch processing)
   - Large text translation (performance testing)
   - Translation history management

3. **Error Handling**
   - Invalid LLM configuration recovery
   - Network connectivity issues
   - Service timeout handling
   - Provider switching and fallback

### TTS Workflow Tests
1. **Engine Management**
   - Automatic platform detection
   - Engine initialization (Edge TTS, Flutter TTS)
   - Engine switching and fallback mechanisms
   - Voice loading and enumeration

2. **Synthesis Operations**
   - Basic text-to-speech conversion
   - Voice selection and parameter adjustment
   - Playback controls (play, pause, stop)
   - Queue management for multiple requests

3. **Platform Compatibility**
   - Desktop: Edge TTS primary, Flutter TTS fallback
   - Mobile: Flutter TTS with system integration
   - Web: Web Speech API through Flutter TTS

### Combined Workflow Tests
1. **End-to-End Workflows**
   - Translate text → Speak translated result
   - Multi-language translation → TTS for each language
   - Service coordination without conflicts

2. **Performance Testing**
   - Memory management during combined operations
   - Concurrent translation and TTS requests
   - App responsiveness during long operations

3. **Error Recovery**
   - Graceful handling when one service fails
   - Service restart and recovery mechanisms
   - User experience during error conditions

## Troubleshooting

### Common Issues

#### Translation Tests
1. **Connection Failures**
   ```bash
   # Check Ollama
   curl http://localhost:11434/api/tags
   
   # Check LM Studio
   curl http://localhost:1234/v1/models
   
   # Check firewall settings
   # Ensure ports 11434 (Ollama) or 1234 (LM Studio) are open
   ```

2. **Timeout Issues**
   - Increase timeout values for slower models
   - Ensure sufficient system resources (RAM, CPU)
   - Check model performance and size

3. **Network Configuration**
   - Verify localhost access is allowed
   - Check proxy settings
   - For mobile testing, use `10.0.2.2` instead of `localhost`

#### TTS Tests
1. **No Voices Available**
   ```bash
   # Windows: Check installed voices
   Get-WmiObject -Class Win32_SystemDriver | Where-Object {$_.Name -like "*speech*"}
   
   # macOS: List available voices
   say -v ?
   
   # Linux: Install TTS engines
   sudo apt-get install espeak espeak-data
   ```

2. **Audio Issues**
   - Verify system audio is working
   - Check audio device configuration
   - Test with system TTS utilities
   - Ensure no other applications are using audio exclusively

3. **Engine Failures**
   - Edge TTS: Ensure Windows 10/11 or Edge browser
   - Flutter TTS: Check system TTS configuration
   - Web: Verify browser supports Web Speech API

#### Performance Issues
1. **Slow Tests**
   - Run on release builds: `flutter test --release`
   - Ensure sufficient system resources
   - Close unnecessary applications
   - Use SSD storage for better I/O performance

2. **Memory Issues**
   - Monitor memory usage during tests
   - Check for memory leaks in long-running tests
   - Restart devices/emulators between test runs

### Debug Mode
```bash
# Enable verbose output
flutter test integration_test/ --verbose

# Enable debug logging
flutter test integration_test/ --dart-define=DEBUG=true

# Run with coverage
flutter test integration_test/ --coverage
```

### Mock Testing
For CI/CD or environments without real services:

```bash
# Mock LLM providers
ALOUETTE_MOCK_LLM=true flutter test integration_test/

# Mock TTS engines
ALOUETTE_MOCK_TTS=true flutter test integration_test/

# Mock audio output
ALOUETTE_MOCK_AUDIO=true flutter test integration_test/
```

## Continuous Integration

### GitHub Actions Example
```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run integration tests
        run: ./run_integration_tests.sh -p web-server -v
        env:
          ALOUETTE_MOCK_LLM: true
          ALOUETTE_MOCK_TTS: true
```

### Docker Testing
```dockerfile
FROM cirrusci/flutter:stable

WORKDIR /app
COPY . .

RUN flutter pub get
RUN ./run_integration_tests.sh -p web-server
```

## Performance Benchmarks

### Expected Performance Metrics
- **App Initialization**: < 5 seconds
- **Service Setup**: < 3 seconds
- **Translation (short text)**: < 5 seconds
- **Translation (long text)**: < 15 seconds
- **TTS Synthesis (short)**: < 2 seconds
- **TTS Synthesis (long)**: < 10 seconds
- **Engine Switching**: < 3 seconds
- **Voice Loading**: < 5 seconds

### Performance Testing
```bash
# Run performance-focused tests
flutter test integration_test/ --dart-define=PERFORMANCE_TEST=true

# Generate performance reports
flutter test integration_test/ --reporter=json > performance_results.json
```

## Requirements Coverage

These integration tests verify compliance with:

- **Requirement 9.1**: Existing functionality preservation during refactoring
- **Requirement 9.3**: Integration tests for key user flows
- **Cross-platform compatibility**: Engine switching and platform-specific behavior
- **Service integration**: Translation and TTS services working together
- **Error handling**: Graceful error recovery and fallback mechanisms
- **Performance**: Memory management and responsiveness testing

## Test Reports

### Automated Reports
Test execution generates:
- **JSON Results**: Detailed test results in machine-readable format
- **HTML Report**: Human-readable summary with pass/fail status
- **Coverage Report**: Code coverage analysis (when enabled)
- **Performance Metrics**: Timing and resource usage data

### Report Locations
- `test_results/` - All generated reports
- `test_results/test_report.html` - Main HTML summary
- `test_results/*_test_results.json` - Individual app results
- `coverage/` - Coverage reports (when enabled)

## Contributing

### Adding New Tests
1. Create test files in appropriate `integration_test/` directory
2. Follow existing naming conventions
3. Include comprehensive error handling
4. Add appropriate timeouts for operations
5. Update test runner files to include new tests
6. Document test scenarios in README files

### Test Guidelines
- **Isolation**: Tests should not depend on each other
- **Cleanup**: Properly dispose of resources after tests
- **Timeouts**: Use appropriate timeouts for different operations
- **Error Handling**: Test both success and failure scenarios
- **Platform Awareness**: Consider platform-specific behavior
- **Performance**: Monitor resource usage in tests

For questions or issues with integration testing, please refer to the individual application README files or create an issue in the project repository.