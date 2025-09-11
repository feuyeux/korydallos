import 'package:flutter/foundation.dart';
import '../models/llm_config.dart';
import '../models/connection_status.dart';
import 'llm_config_service.dart';

/// Auto-configuration service for LLM connections
/// 
/// This service handles automatic detection and configuration of LLM providers,
/// including fallback strategies and retry mechanisms.
class AutoConfigService extends ChangeNotifier {
  final LLMConfigService _llmConfigService;
  bool _isAutoConfiguring = false;
  LLMConfig? _autoDetectedConfig;
  List<String> _detectionLog = [];

  /// Notifier for auto-configuration state
  final ValueNotifier<bool> isAutoConfiguringNotifier = ValueNotifier<bool>(false);

  AutoConfigService({LLMConfigService? llmConfigService})
      : _llmConfigService = llmConfigService ?? LLMConfigService();

  /// Get the auto-detected configuration
  LLMConfig? get autoDetectedConfig => _autoDetectedConfig;

  /// Check if auto-configuration is in progress
  bool get isAutoConfiguring => _isAutoConfiguring;

  /// Get the detection log
  List<String> get detectionLog => List.unmodifiable(_detectionLog);

  /// Auto-configure LLM connection with retry mechanism
  Future<LLMConfig?> autoConfigureLLM({
    bool enableRetry = true,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    if (_isAutoConfiguring) {
      return _autoDetectedConfig;
    }

    _isAutoConfiguring = true;
    isAutoConfiguringNotifier.value = true;
    _detectionLog.clear();
    notifyListeners();

    try {
      _addToLog('Starting auto-configuration...');

      // Try with preferred configurations first
      final preferredConfigs = _getPreferredConfigurations();
      
      for (final config in preferredConfigs) {
        _addToLog('Testing ${config.provider} at ${config.serverUrl}...');
        
        final result = await _testConfigurationWithRetry(
          config,
          enableRetry ? maxRetries : 1,
          retryDelay,
        );

        if (result != null) {
          _autoDetectedConfig = result;
          _addToLog('✓ Successfully configured ${result.provider} with model ${result.selectedModel}');
          notifyListeners();
          return result;
        }
      }

      // If no preferred config works, try the full auto-detection
      _addToLog('Preferred configurations failed, trying full auto-detection...');
      final autoDetected = await _llmConfigService.autoDetectConfig();
      
      if (autoDetected != null) {
        _autoDetectedConfig = autoDetected;
        _addToLog('✓ Auto-detected ${autoDetected.provider} with model ${autoDetected.selectedModel}');
        notifyListeners();
        return autoDetected;
      }

      _addToLog('✗ No working configuration found');
      return null;

    } catch (e) {
      _addToLog('✗ Auto-configuration failed: $e');
      return null;
    } finally {
      _isAutoConfiguring = false;
      isAutoConfiguringNotifier.value = false;
      notifyListeners();
    }
  }

  /// Auto-configure with progress reporting
  Stream<AutoConfigProgress> autoConfigureWithProgress({
    bool enableRetry = true,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async* {
    if (_isAutoConfiguring) {
      yield AutoConfigProgress(
        isComplete: true,
        config: _autoDetectedConfig,
        message: 'Auto-configuration already in progress',
        progress: 1.0,
      );
      return;
    }

    _isAutoConfiguring = true;
    isAutoConfiguringNotifier.value = true;
    _detectionLog.clear();
    notifyListeners();

    try {
      final configs = _getPreferredConfigurations();
      final totalSteps = configs.length + 1; // +1 for full auto-detection
      int currentStep = 0;

      yield AutoConfigProgress(
        isComplete: false,
        message: 'Starting auto-configuration...',
        progress: 0.0,
      );

      for (final config in configs) {
        currentStep++;
        yield AutoConfigProgress(
          isComplete: false,
          message: 'Testing ${config.provider} at ${config.serverUrl}...',
          progress: currentStep / totalSteps,
        );

        final result = await _testConfigurationWithRetry(
          config,
          enableRetry ? maxRetries : 1,
          retryDelay,
        );

        if (result != null) {
          _autoDetectedConfig = result;
          yield AutoConfigProgress(
            isComplete: true,
            config: result,
            message: 'Successfully configured ${result.provider}',
            progress: 1.0,
          );
          notifyListeners();
          return;
        }
      }

      // Try full auto-detection
      currentStep++;
      yield AutoConfigProgress(
        isComplete: false,
        message: 'Running full auto-detection...',
        progress: currentStep / totalSteps,
      );

      final autoDetected = await _llmConfigService.autoDetectConfig();
      
      if (autoDetected != null) {
        _autoDetectedConfig = autoDetected;
        yield AutoConfigProgress(
          isComplete: true,
          config: autoDetected,
          message: 'Auto-detected ${autoDetected.provider}',
          progress: 1.0,
        );
        notifyListeners();
        return;
      }

      yield AutoConfigProgress(
        isComplete: true,
        message: 'No working configuration found',
        progress: 1.0,
      );

    } catch (e) {
      yield AutoConfigProgress(
        isComplete: true,
        message: 'Auto-configuration failed: $e',
        progress: 1.0,
        hasError: true,
      );
    } finally {
      _isAutoConfiguring = false;
      isAutoConfiguringNotifier.value = false;
      notifyListeners();
    }
  }

  /// Get preferred configurations in priority order
  List<LLMConfig> _getPreferredConfigurations() {
    return [
      // Ollama with qwen2.5 (most preferred)
      LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'qwen2.5:latest',
      ),
      LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'qwen2.5:7b',
      ),
      LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'qwen2.5:1.5b',
      ),
      // LM Studio configurations
      LLMConfig(
        provider: 'lmstudio',
        serverUrl: 'http://localhost:1234/v1',
        selectedModel: '',
      ),
    ];
  }

  /// Test configuration with retry mechanism
  Future<LLMConfig?> _testConfigurationWithRetry(
    LLMConfig config,
    int maxRetries,
    Duration retryDelay,
  ) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final status = await _llmConfigService.testConnection(config);
        
        if (status.success && _llmConfigService.availableModels.isNotEmpty) {
          // Find the best model for this configuration
          final bestModel = _selectBestModel(_llmConfigService.availableModels);
          return config.copyWith(selectedModel: bestModel);
        }

        if (attempt < maxRetries) {
          _addToLog('  Attempt $attempt failed, retrying in ${retryDelay.inSeconds}s...');
          await Future.delayed(retryDelay);
        }

      } catch (e) {
        _addToLog('  Attempt $attempt error: $e');
        if (attempt < maxRetries) {
          await Future.delayed(retryDelay);
        }
      }
    }

    _addToLog('  All attempts failed for ${config.provider}');
    return null;
  }

  /// Select the best model from available models
  String _selectBestModel(List<String> models) {
    // Prefer qwen2.5 models
    final qwenModels = models.where((m) => m.toLowerCase().contains('qwen2.5')).toList();
    if (qwenModels.isNotEmpty) {
      // Prefer latest, then 7b, then others
      for (final suffix in ['latest', '7b', '3b', '1.5b']) {
        final match = qwenModels.firstWhere(
          (m) => m.contains(suffix),
          orElse: () => '',
        );
        if (match.isNotEmpty) return match;
      }
      return qwenModels.first;
    }

    // Fallback to first available model
    return models.isNotEmpty ? models.first : '';
  }

  /// Add message to detection log
  void _addToLog(String message) {
    final timestamp = DateTime.now().toLocal().toString().substring(11, 19);
    _detectionLog.add('[$timestamp] $message');
    notifyListeners();
  }

  /// Clear auto-detected configuration and log
  void clearAutoConfig() {
    _autoDetectedConfig = null;
    _detectionLog.clear();
    notifyListeners();
  }

  /// Get auto-configuration summary
  Map<String, dynamic> getAutoConfigSummary() {
    return {
      'isAutoConfiguring': _isAutoConfiguring,
      'hasAutoConfig': _autoDetectedConfig != null,
      'autoDetectedProvider': _autoDetectedConfig?.provider,
      'autoDetectedModel': _autoDetectedConfig?.selectedModel,
      'detectionSteps': _detectionLog.length,
      'lastDetection': _detectionLog.isNotEmpty ? _detectionLog.last : null,
    };
  }
}

/// Progress information for auto-configuration
class AutoConfigProgress {
  final bool isComplete;
  final LLMConfig? config;
  final String message;
  final double progress;
  final bool hasError;

  const AutoConfigProgress({
    required this.isComplete,
    this.config,
    required this.message,
    required this.progress,
    this.hasError = false,
  });
}