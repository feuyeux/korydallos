# Alouette Translation Library

A Flutter library for AI-powered translation functionality with support for multiple LLM providers.

## Features

- Support for multiple LLM providers (Ollama, LM Studio)
- Unified API for translation operations
- Configuration management and connection testing
- Comprehensive error handling with specific exception types
- Cross-platform support (Android, iOS, Web, Windows, macOS, Linux)
- Dependency injection for better testability
- HTTP client abstraction for flexible network implementations
- Text cleaning utilities for processing translation results

## Testing Requirements

The test suite includes tests that require a running LLM server:

- `should translate text successfully` - Requires Ollama server running on port 11434
- `should test connection to LLM provider` - Requires Ollama server running on port 11434
- `should get available models` - Requires Ollama server running on port 11434

To run all tests successfully, start the Ollama server before running tests.

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  alouette_lib_trans: ^1.0.0
```

## Usage

```dart
import 'package:alouette_lib_trans/alouette_lib_trans.dart';

// Configure LLM
final config = LLMConfig(
  provider: 'ollama',
  serverUrl: 'http://localhost:11434',
  selectedModel: 'llama2',
);

// Create translation service (with default providers)
final translationService = TranslationService();

// Translate text
final result = await translationService.translateText(
  'Hello, world!',
  ['es', 'fr', 'de'],
  config,
);

print(result.translations['es']); // Hola, mundo!
```

## Supported Providers

- **Ollama**: Local LLM server
- **LM Studio**: Local LLM server with OpenAI-compatible API

## Architecture

The library follows a simplified modular architecture with clear separation of concerns:

- **Models**: Data models for configuration and results
- **Services**: Core business logic ([TranslationService](file:///d:/coding/korydallos/alouette-lib-trans/lib/src/services/translation_service.dart#L12-L376), [LLMConfigService](file:///d:/coding/korydallos/alouette-lib-trans/lib/src/services/llm_config_service.dart#L12-L185), [AutoConfigService](file:///d:/coding/korydallos/alouette-lib-trans/lib/src/services/auto_config_service.dart#L8-L246))
- **Providers**: Implementation for specific LLM providers
- **Exceptions**: Comprehensive error handling
- **Utils**: Utility classes for text cleaning and constants
- **Network**: HTTP client abstraction for flexible implementations

## Simplified Structure

The library has been reorganized to reduce complexity while maintaining all functionality:

1. **Consolidated Services**: Core functionality is now in three main services instead of being spread across many files
2. **Reduced File Count**: Eliminated unnecessary files and consolidated related functionality
3. **Clearer Organization**: Simplified directory structure with fewer layers
4. **Backward Compatibility**: All existing APIs remain functional without changes

## Error Handling

The library provides specific exception types for different error scenarios:

- `TranslationException`: Base exception for all translation errors
- `LLMConnectionException`: Network/connection issues
- `LLMAuthenticationException`: Authentication failures
- `LLMModelNotFoundException`: Model not found errors
- `TranslationTimeoutException`: Timeout issues
- `InvalidTranslationException`: Invalid translation results
- `ConfigurationException`: Configuration errors
- `UnsupportedProviderException`: Unsupported provider errors
- `RateLimitException`: Rate limiting errors

## Testing

The library is designed with testability in mind:

- Dependency injection for services and providers
- HTTP client abstraction for easy mocking
- Clear separation of concerns
- Simplified architecture reduces testing complexity

For development, tests that use mocks have been removed. The remaining tests focus on real LLM interactions.

## License

MIT License