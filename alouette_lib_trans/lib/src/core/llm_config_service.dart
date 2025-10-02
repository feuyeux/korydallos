import '../models/llm_config.dart';

/// Pure utility class for LLM configuration management
/// This class provides static methods for configuration validation and recommendations
/// For actual connection testing and model fetching, use TranslationService
class LLMConfigService {
  // Private constructor to prevent instantiation
  LLMConfigService._();

  /// Validate LLM configuration
  static Map<String, dynamic> validateConfig(LLMConfig config) {
    return config.validate();
  }

  /// Get recommended settings for a provider
  static Map<String, dynamic> getRecommendedSettings(
    String provider, {
    bool isAndroid = false,
  }) {
    // Use different base URL for Android to avoid localhost issues
    final baseUrl = isAndroid ? 'http://10.0.2.2' : 'http://localhost';

    switch (provider.toLowerCase()) {
      case 'ollama':
        return {
          'serverUrl': '$baseUrl:11434',
          'apiKey': '',
          'description': 'Ollama typically runs on port 11434',
          'setupInstructions': [
            'Install Ollama from https://ollama.ai',
            'Run "ollama serve" to start the server',
            'Pull a model with "ollama pull llama3.2" or similar',
          ],
          'commonModels': ['llama3.2', 'llama3.1', 'mistral', 'codellama'],
        };

      case 'lmstudio':
        return {
          'serverUrl': '$baseUrl:1234',
          'apiKey': '',
          'description': 'LM Studio typically runs on port 1234',
          'setupInstructions': [
            'Install LM Studio from https://lmstudio.ai',
            'Download and load a model in LM Studio',
            'Start the local server from the server tab',
            'Enable CORS if accessing from web applications',
          ],
          'commonModels': [
            'microsoft/DialoGPT-medium',
            'microsoft/DialoGPT-large',
            'huggingface models',
          ],
        };

      default:
        return {
          'serverUrl': '$baseUrl:11434',
          'apiKey': '',
          'description': 'Default configuration',
          'setupInstructions': [],
          'commonModels': [],
        };
    }
  }

  /// Create default configuration for a provider
  static LLMConfig createDefaultConfig(String provider) {
    final settings = getRecommendedSettings(provider);
    return LLMConfig(
      provider: provider,
      serverUrl: settings['serverUrl'] as String,
      selectedModel: '',
      apiKey: settings['apiKey'] as String?,
    );
  }

  /// Check if a configuration is complete and ready to use
  static bool isConfigurationComplete(LLMConfig config) {
    final validation = validateConfig(config);
    return validation['isValid'] as bool;
  }

  /// Get configuration summary for display
  static Map<String, dynamic> getConfigSummary(LLMConfig config) {
    final validation = validateConfig(config);
    return {
      'provider': config.provider,
      'serverUrl': config.serverUrl,
      'selectedModel': config.selectedModel,
      'hasApiKey': config.apiKey?.isNotEmpty ?? false,
      'isValid': validation['isValid'],
      'errors': validation['errors'],
      'warnings': validation['warnings'],
    };
  }
}
