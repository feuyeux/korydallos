# Alouette TTS App - Integration Tests

This directory contains integration tests specifically for the Alouette TTS (Text-to-Speech) application, which focuses on multi-platform TTS functionality.

## Test Structure

### Test Files

- **`tts_app_test.dart`** - Comprehensive TTS app functionality tests
- **`test_runner.dart`** - Runs all TTS app integration tests

### Test Coverage

#### TTS App Tests
- TTS app initialization and service setup
- TTS engine initialization and voice loading
- Basic TTS synthesis workflow
- TTS engine switching functionality (Edge TTS ↔ Flutter TTS)
- Voice selection and configuration
- TTS playback control functionality (play, pause, stop)
- TTS error handling and fallback
- Cross-platform TTS engine compatibility
- TTS app performance and memory management

## Prerequisites

### Platform-Specific Requirements

#### Desktop Platforms (Windows, macOS, Linux)
1. **Edge TTS** (Primary):
   - Automatically available on Windows 10/11
   - Available via Edge browser on macOS/Linux
   - No additional installation required

2. **Flutter TTS** (Fallback):
   - Uses system TTS engines
   - Ensure system has TTS voices installed

#### Mobile Platforms (Android, iOS)
1. **System TTS**:
   - Android: Google TTS or Samsung TTS
   - iOS: Built-in system TTS
   - Ensure TTS voices are installed and enabled

#### Web Platform
1. **Web Speech API**:
   - Supported browsers: Chrome, Firefox, Safari, Edge
   - No additional setup required
   - Voice availability depends on browser and OS

### Voice Installation

#### Windows
```powershell
# Check installed voices
Get-WmiObject -Class Win32_SystemDriver | Where-Object {$_.Name -like "*speech*"}

# Install additional voices via Settings > Time & Language > Speech
```

#### macOS
```bash
# Check installed voices
say -v ?

# Install additional voices via System Preferences > Accessibility > Speech
```

#### Linux
```bash
# Install espeak (common TTS engine)
sudo apt-get install espeak espeak-data

# Install festival
sudo apt-get install festival festvox-kallpc16k
```

## Running the Tests

### Run All TTS App Tests
```bash
# Navigate to the TTS app directory
cd alouette-app-tts

# Run all integration tests
flutter test integration_test/test_runner.dart
```

### Run Individual Tests
```bash
# TTS app functionality tests
flutter test integration_test/tts_app_test.dart
```

### Platform-Specific Testing

#### Desktop Testing
```bash
# Windows (tests Edge TTS + Flutter TTS)
flutter test integration_test/ -d windows

# macOS (tests system TTS via Flutter TTS)
flutter test integration_test/ -d macos

# Linux (tests system TTS via Flutter TTS)
flutter test integration_test/ -d linux
```

#### Mobile Testing
```bash
# Android (tests system TTS)
flutter test integration_test/ -d android

# iOS (tests system TTS)
flutter test integration_test/ -d ios
```

#### Web Testing
```bash
# Chrome (tests Web Speech API)
flutter test integration_test/ -d chrome

# Firefox (tests Web Speech API)
flutter test integration_test/ -d firefox
```

## Test Scenarios

### 1. Engine Initialization
- Automatic platform detection
- Engine availability verification
- Voice loading and enumeration
- Engine status reporting

### 2. TTS Synthesis
- Basic text-to-speech conversion
- Voice selection and switching
- Parameter adjustment (speed, pitch, volume)
- Audio output verification

### 3. Engine Switching
- **Desktop**: Edge TTS ↔ Flutter TTS switching
- **Mobile/Web**: Flutter TTS engine management
- Fallback mechanism testing
- Engine preference persistence

### 4. Playback Controls
- Play/pause/stop functionality
- Progress tracking
- Multiple synthesis queue management
- Interruption handling

### 5. Error Handling
- Empty text handling
- Very long text processing
- Engine failure recovery
- Voice unavailability handling

### 6. Performance Testing
- Multiple synthesis operations
- Memory management verification
- Large text processing
- Concurrent operation handling

## Configuration

### Environment Variables
```bash
# Set preferred TTS engine
export ALOUETTE_TTS_ENGINE="edge"     # or "flutter"

# Set voice preferences
export ALOUETTE_TTS_VOICE="en-US-AriaNeural"

# Enable debug logging
export ALOUETTE_TTS_DEBUG="true"

# Set synthesis parameters
export ALOUETTE_TTS_RATE="1.0"       # Speech rate
export ALOUETTE_TTS_PITCH="1.0"      # Voice pitch
export ALOUETTE_TTS_VOLUME="1.0"     # Audio volume
```

### Test Configuration
The tests automatically configure:
- Platform-appropriate engine selection
- Default voice selection
- Appropriate timeouts for synthesis operations
- Error recovery mechanisms

## Platform-Specific Behavior

### Desktop Platforms
1. **Primary Engine**: Edge TTS (if available)
   - High-quality neural voices
   - Fast synthesis
   - Offline capability

2. **Fallback Engine**: Flutter TTS
   - System TTS integration
   - Platform-native voices
   - Reliable compatibility

### Mobile Platforms
1. **Engine**: Flutter TTS only
   - Native system integration
   - Platform-optimized performance
   - Device-specific voice availability

### Web Platform
1. **Engine**: Flutter TTS (Web Speech API)
   - Browser-dependent voice availability
   - Network-dependent for some voices
   - Limited parameter control

## Troubleshooting

### Common Issues

1. **No Voices Available**:
   ```bash
   # Check system TTS configuration
   # Windows: Settings > Time & Language > Speech
   # macOS: System Preferences > Accessibility > Speech
   # Linux: Install espeak or festival
   ```

2. **Edge TTS Not Working**:
   - Ensure Windows 10/11 or Edge browser is installed
   - Check internet connectivity for voice downloads
   - Verify Edge TTS service is running

3. **Audio Output Issues**:
   - Check system audio settings
   - Verify audio device is working
   - Test with system TTS utilities

4. **Performance Issues**:
   - Reduce text length for testing
   - Check available system memory
   - Close other audio applications

### Debug Mode
```bash
# Run with verbose output
flutter test integration_test/ --verbose

# Enable TTS debug logging
flutter test integration_test/ --dart-define=TTS_DEBUG=true
```

### Manual Testing
```bash
# Test Edge TTS directly (Windows)
edge-tts --text "Hello world" --write-media hello.wav

# Test system TTS (macOS)
say "Hello world"

# Test system TTS (Linux)
espeak "Hello world"
```

## Requirements Coverage

These integration tests verify:

- **Requirement 9.1**: TTS functionality preservation during refactoring
- **Requirement 9.3**: Integration tests for TTS workflows
- **Platform Compatibility**: Engine switching and platform-specific behavior
- **Voice Management**: Voice selection and configuration
- **Error Recovery**: Graceful handling of TTS failures
- **Performance**: Memory management and synthesis speed
- **Cross-Platform**: Consistent behavior across platforms

## Continuous Integration

For automated testing in CI/CD:

```bash
# Headless testing (no audio output)
flutter test integration_test/ --headless

# Mock audio testing
flutter test integration_test/ --dart-define=MOCK_AUDIO=true

# Platform-specific CI testing
flutter test integration_test/ -d web-server --web-port=7357
```

## Mock Testing

For testing without audio output:

```bash
# Use mock TTS engines
ALOUETTE_TTS_MOCK=true flutter test integration_test/

# Test with simulated voices
ALOUETTE_TTS_MOCK_VOICES=true flutter test integration_test/
```

## Performance Benchmarks

Expected performance metrics:
- **Engine Initialization**: < 3 seconds
- **Voice Loading**: < 5 seconds
- **Short Text Synthesis** (< 100 chars): < 2 seconds
- **Long Text Synthesis** (> 1000 chars): < 10 seconds
- **Engine Switching**: < 3 seconds