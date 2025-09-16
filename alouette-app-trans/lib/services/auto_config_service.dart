import 'package:alouette_lib_trans/alouette_lib_trans.dart';

/// A service that provides automatic configuration functionality
class AutoConfigService {
  /// Attempts to automatically configure LLM settings
  Future<LLMConfig?> attemptAutoConfiguration() async {
    // For now, return a default configuration
    // In the future, this could try to detect running services
    return const LLMConfig(
      provider: 'ollama',
      serverUrl: 'http://localhost:11434',
      selectedModel: 'gemma3:latest',
    );
  }

  /// Check if auto-configuration is possible
  Future<bool> canAutoConfig() async {
    // Simple check - in the future could ping services
    return true;
  }
}
