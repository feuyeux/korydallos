# Alouette Translation App - Integration Tests

This directory contains integration tests specifically for the Alouette Translation application, which focuses on AI-powered translation functionality.

## Test Structure

### Test Files

- **`translation_app_test.dart`** - Comprehensive translation app functionality tests
- **`test_runner.dart`** - Runs all translation app integration tests

### Test Coverage

#### Translation App Tests
- Translation app initialization and service setup
- LLM provider configuration workflow (Ollama, LM Studio)
- Single language translation workflow
- Multiple language translation workflow
- Translation history and management
- Translation error handling and recovery
- Translation app performance with large text

## Prerequisites

### LLM Provider Setup
1. **Ollama Setup**:
   ```bash
   # Install Ollama
   curl -fsSL https://ollama.ai/install.sh | sh
   
   # Pull and run a model
   ollama pull llama2
   ollama run llama2
   ```

2. **LM Studio Setup**:
   - Download and install LM Studio
   - Load a compatible model
   - Start the local server (default: http://localhost:1234)

### Network Configuration
- **Ollama**: Default URL `http://localhost:11434`
- **LM Studio**: Default URL `http://localhost:1234`
- **Mobile Testing**: Use `http://10.0.2.2:11434` for Android emulator

## Running the Tests

### Run All Translation App Tests
```bash
# Navigate to the translation app directory
cd alouette-app-trans

# Run all integration tests
flutter test integration_test/test_runner.dart
```

### Run Individual Tests
```bash
# Translation app functionality tests
flutter test integration_test/translation_app_test.dart
```

### Platform-Specific Testing
```bash
# Desktop
flutter test integration_test/ -d windows  # or macos, linux

# Mobile
flutter test integration_test/ -d android  # or ios

# Web
flutter test integration_test/ -d chrome   # or firefox
```

## Test Scenarios

### 1. LLM Provider Configuration
- Tests configuration of Ollama and LM Studio providers
- Validates connection testing functionality
- Verifies configuration persistence

### 2. Translation Workflows
- **Single Language**: Translate text to one target language
- **Multiple Languages**: Translate text to multiple target languages simultaneously
- **Large Text**: Performance testing with substantial text content

### 3. Error Handling
- Invalid LLM configuration handling
- Network connectivity issues
- Service recovery after errors

### 4. Performance Testing
- Large text translation performance
- Memory management during multiple translations
- App responsiveness during long-running operations

## Configuration

### Environment Variables
```bash
# Set LLM provider URL
export ALOUETTE_TRANS_LLM_URL="http://localhost:11434"

# Set preferred provider
export ALOUETTE_TRANS_PROVIDER="ollama"  # or "lmstudio"

# Enable debug logging
export ALOUETTE_TRANS_DEBUG="true"
```

### Test Configuration
The tests automatically configure the translation service with:
- Default server URLs for each provider
- Appropriate timeouts for translation operations
- Error recovery mechanisms

## Troubleshooting

### Common Issues

1. **LLM Connection Failures**:
   ```bash
   # Check if Ollama is running
   curl http://localhost:11434/api/tags
   
   # Check if LM Studio is running
   curl http://localhost:1234/v1/models
   ```

2. **Translation Timeouts**:
   - Increase timeout values for slower models
   - Ensure sufficient system resources
   - Check model performance

3. **Network Issues**:
   - Verify firewall settings
   - Check proxy configuration
   - Ensure localhost access is allowed

### Debug Mode
```bash
# Run with verbose output
flutter test integration_test/ --verbose

# Run with debug logging
flutter test integration_test/ --dart-define=DEBUG=true
```

## Requirements Coverage

These integration tests verify:

- **Requirement 9.1**: Translation functionality preservation
- **Requirement 9.3**: Integration tests for translation workflows
- **LLM Integration**: Real provider testing with Ollama and LM Studio
- **Error Recovery**: Graceful handling of translation failures
- **Performance**: Large text and multiple language handling
- **Configuration**: Provider switching and connection testing

## Continuous Integration

For automated testing in CI/CD:

```bash
# Headless testing
flutter test integration_test/ -d web-server --headless

# With mock LLM server
ALOUETTE_TRANS_LLM_URL="http://mock-server:11434" flutter test integration_test/
```

## Mock Testing

For testing without real LLM providers, you can use mock servers:

```bash
# Start mock Ollama server
docker run -p 11434:11434 mock-ollama-server

# Run tests against mock server
ALOUETTE_TRANS_LLM_URL="http://localhost:11434" flutter test integration_test/
```