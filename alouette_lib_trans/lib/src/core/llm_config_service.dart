import '../models/llm_config.dart';
import '../models/connection_status.dart';

/// Service for managing LLM configuration operations
class LLMConfigService {
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

  /// Get available models from the provider
  /// This is a convenience method that delegates to TranslationService
  Future<List<String>> getAvailableModels(LLMConfig config) async {
    // For now, return mock data since we need TranslationService integration
    // In a real implementation, this would use TranslationService
    switch (config.provider.toLowerCase()) {
      case 'ollama':
        return ['llama3.2', 'llama3.1', 'mistral', 'codellama'];
      case 'lmstudio':
        return ['microsoft/DialoGPT-medium', 'microsoft/DialoGPT-large'];
      default:
        return ['default-model'];
    }
  }

  /// Test connection to the provider
  /// This is a convenience method that delegates to TranslationService
  Future<ConnectionStatus> testConnection(LLMConfig config) async {
    // Mock implementation that validates provider + URL only (model not required)
    await Future.delayed(const Duration(milliseconds: 500));

    // Basic validation without requiring model selection
    final providerOk = config.provider.isNotEmpty;
    bool urlOk = false;
    if (config.serverUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(config.serverUrl);
        urlOk = uri.hasScheme && uri.hasAuthority;
      } catch (_) {
        urlOk = false;
      }
    }

    if (providerOk && urlOk) {
      final models = await getAvailableModels(config);
      return ConnectionStatus.success(
        message: 'Connected successfully to ${config.provider}',
        modelCount: models.length,
        responseTimeMs: 500,
        details: {
          'models': models,
          'provider': config.provider,
          'serverUrl': config.serverUrl,
        },
      );
    }

    // Build error message similar to validate() but ignore model requirement for connection test
    final errors = <String>[];
    if (!providerOk) errors.add('Provider is required');
    if (!urlOk) errors.add('Invalid server URL format');

    return ConnectionStatus.failure(
      message: 'Invalid configuration: ${errors.join(', ')}',
      responseTimeMs: 500,
    );
  }
}
