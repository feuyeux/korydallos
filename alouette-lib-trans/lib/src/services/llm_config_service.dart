import '../models/llm_config.dart';
import '../models/connection_status.dart';
import '../providers/ollama_provider.dart';
import '../providers/lmstudio_provider.dart';

/// A service that provides LLM configuration management functionality
/// This is a wrapper around the individual provider implementations
class LLMConfigService {
  final OllamaProvider _ollamaProvider = OllamaProvider();
  final LMStudioProvider _lmStudioProvider = LMStudioProvider();

  /// Test connection to the LLM provider
  Future<ConnectionStatus> testConnection(LLMConfig config) async {
    switch (config.provider) {
      case 'ollama':
        return await _ollamaProvider.testConnection(config);
      case 'lmstudio':
        return await _lmStudioProvider.testConnection(config);
      default:
        return ConnectionStatus.failure(
          message: 'Unsupported provider: ${config.provider}',
        );
    }
  }

  /// Get available models from the LLM provider
  Future<List<String>> getAvailableModels(LLMConfig config) async {
    switch (config.provider) {
      case 'ollama':
        return await _ollamaProvider.getAvailableModels(config);
      case 'lmstudio':
        return await _lmStudioProvider.getAvailableModels(config);
      default:
        return [];
    }
  }

  /// Save configuration (placeholder implementation)
  Future<void> saveConfig(LLMConfig config) async {
    // For now, just a placeholder
    // In the future, could save to shared preferences or file
  }

  /// Load saved configuration (placeholder implementation)
  Future<LLMConfig?> loadConfig() async {
    // For now, just return null
    // In the future, could load from shared preferences or file
    return null;
  }
}
