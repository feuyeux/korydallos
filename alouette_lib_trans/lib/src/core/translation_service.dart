import 'package:flutter/foundation.dart';
import '../models/llm_config.dart';
import '../models/translation_request.dart';
import '../models/translation_result.dart';
import '../models/connection_status.dart';
import '../providers/base_translation_provider.dart';
import '../providers/ollama_provider.dart';
import '../providers/lm_studio_provider.dart';
import '../exceptions/translation_exceptions.dart';
import 'dart:io';
import 'dart:async';

/// Core unified translation service that handles all translation operations
///
/// This service provides a consistent API for translation functionality across
/// all applications, with comprehensive error handling and provider management.
class TranslationService extends ChangeNotifier {
  TranslationResult? _currentTranslation;
  bool _isTranslating = false;
  List<String> _availableModels = [];
  ConnectionStatus? _connectionStatus;
  bool _isTestingConnection = false;
  bool _isAutoConfiguring = false;
  LLMConfig? _autoDetectedConfig;

  /// Notifier for translation state changes
  final ValueNotifier<bool> isTranslatingNotifier = ValueNotifier<bool>(false);

  /// Notifier for connection testing state
  final ValueNotifier<bool> isTestingConnectionNotifier = ValueNotifier<bool>(
    false,
  );

  /// Notifier for auto-configuration state
  final ValueNotifier<bool> isAutoConfiguringNotifier = ValueNotifier<bool>(
    false,
  );

  final Map<String, TranslationProvider> _providers;

  /// Constructor with optional provider injection for better testability
  TranslationService({Map<String, TranslationProvider>? providers})
    : _providers =
          providers ??
          {'ollama': OllamaProvider(), 'lmstudio': LMStudioProvider()};

  /// Get the current translation result
  TranslationResult? get currentTranslation => _currentTranslation;

  /// Check if a translation is currently in progress
  bool get isTranslating => _isTranslating;

  /// Get the list of available models from the last successful connection test
  List<String> get availableModels => List.unmodifiable(_availableModels);

  /// Get the last connection status
  ConnectionStatus? get connectionStatus => _connectionStatus;

  /// Check if a connection test is currently in progress
  bool get isTestingConnection => _isTestingConnection;

  /// Check if auto-configuration is in progress
  bool get isAutoConfiguring => _isAutoConfiguring;

  /// Get the auto-detected configuration
  LLMConfig? get autoDetectedConfig => _autoDetectedConfig;

  /// Translate text to multiple target languages with enhanced error handling
  Future<TranslationResult> translateText(
    String inputText,
    List<String> targetLanguages,
    LLMConfig config, {
    Map<String, dynamic>? additionalParams,
    bool enableRetry = true,
  }) async {
    // Enhanced validation
    _validateTranslationRequest(inputText, targetLanguages, config);

    final provider = _getProvider(config.provider);
    if (provider == null) {
      throw UnsupportedProviderException(
        'Provider ${config.provider} is not supported',
        config.provider,
        availableProviders,
      );
    }

    _isTranslating = true;
    isTranslatingNotifier.value = true;
    notifyListeners();

    try {
      final translations = <String, String>{};
      final cleanedText = inputText.trim();
      final errors = <String, String>{};

      // Translate to each target language with retry logic
      for (int i = 0; i < targetLanguages.length; i++) {
        final language = targetLanguages[i];

        try {
          final translation = enableRetry
              ? await _translateWithRetry(
                  provider,
                  cleanedText,
                  language,
                  config,
                  additionalParams: additionalParams,
                )
              : await provider.translateText(
                  text: cleanedText,
                  targetLanguage: language,
                  config: config,
                  additionalParams: additionalParams,
                );

          // Clean the translation result
          final cleanedTranslation = cleanTranslationResult(
            translation,
            language,
          );

          if (cleanedTranslation.trim().isEmpty) {
            throw InvalidTranslationException(
              'Translation result is empty after cleaning',
              cleanedText,
              language,
            );
          }

          translations[language] = cleanedTranslation;
        } catch (e) {
          // Store error for this language but continue with others
          errors[language] = e.toString();

          // If it's a critical error that affects all translations, rethrow
          if (e is LLMConnectionException ||
              e is LLMAuthenticationException ||
              e is UnsupportedProviderException ||
              e is ConfigurationException) {
            rethrow;
          }
        }
      }

      // Check if we got at least some translations
      if (translations.isEmpty) {
        throw TranslationException(
          'All translations failed. Errors: ${errors.values.join('; ')}',
          code: 'ALL_TRANSLATIONS_FAILED',
          details: {'errors': errors},
        );
      }

      _currentTranslation = TranslationResult(
        original: cleanedText,
        translations: translations,
        languages: targetLanguages,
        timestamp: DateTime.now(),
        config: config,
        metadata: {
          'provider': config.provider,
          'model': config.selectedModel,
          'translationCount': translations.length,
          'successfulLanguages': translations.keys.toList(),
          'failedLanguages': errors.keys.toList(),
          'errors': errors,
        },
      );

      notifyListeners();
      return _currentTranslation!;
    } catch (error) {
      // Enhanced error handling with proper exception types
      if (error is TranslationException) {
        rethrow;
      }

      // Convert unknown errors to appropriate exception types
      final handledException = handleException(
        error,
        config.provider,
        config.serverUrl,
      );
      throw handledException;
    } finally {
      _isTranslating = false;
      isTranslatingNotifier.value = false;
      notifyListeners();
    }
  }

  /// Test connection to the LLM provider
  Future<ConnectionStatus> testConnection(LLMConfig config) async {
    if (_isTestingConnection) {
      return ConnectionStatus.failure(
        message: 'Connection test is already in progress',
      );
    }

    _isTestingConnection = true;
    isTestingConnectionNotifier.value = true;
    notifyListeners();

    try {
      final provider = _getProvider(config.provider);
      if (provider == null) {
        throw TranslationException('Unsupported provider: ${config.provider}');
      }

      _connectionStatus = await provider.testConnection(config);

      if (_connectionStatus!.success) {
        // Fetch available models on successful connection
        try {
          _availableModels = await provider.getAvailableModels(config);
        } catch (e) {
          // Don't fail the connection test if model fetching fails
          _availableModels = [];
        }
      } else {
        _availableModels = [];
      }

      notifyListeners();
      return _connectionStatus!;
    } catch (e) {
      _connectionStatus = ConnectionStatus.failure(
        message: 'Connection test failed: ${e.toString()}',
      );
      _availableModels = [];
      notifyListeners();
      return _connectionStatus!;
    } finally {
      _isTestingConnection = false;
      isTestingConnectionNotifier.value = false;
      notifyListeners();
    }
  }

  /// Get available models from the provider
  Future<List<String>> getAvailableModels(LLMConfig config) async {
    final provider = _getProvider(config.provider);
    if (provider == null) {
      throw TranslationException('Unsupported provider: ${config.provider}');
    }

    try {
      final models = await provider.getAvailableModels(config);
      _availableModels = models;
      notifyListeners();
      return models;
    } catch (e) {
      throw TranslationException(
        'Failed to get available models: ${e.toString()}',
      );
    }
  }

  /// Create a translation request from the given parameters
  TranslationRequest createRequest(
    String text,
    List<String> targetLanguages,
    LLMConfig config, {
    Map<String, dynamic>? additionalParams,
  }) {
    return TranslationRequest(
      text: text,
      targetLanguages: targetLanguages,
      provider: config.provider,
      serverUrl: config.serverUrl,
      modelName: config.selectedModel,
      apiKey: config.apiKey,
      additionalParams: additionalParams,
    );
  }

  /// Get the translation provider for the given provider name
  TranslationProvider? _getProvider(String providerName) {
    return _providers[providerName.toLowerCase()];
  }

  /// Register a custom translation provider
  void registerProvider(String name, TranslationProvider provider) {
    _providers[name.toLowerCase()] = provider;
  }

  /// Get all available provider names
  List<String> get availableProviders => _providers.keys.toList();

  /// Check if a provider is supported
  bool isProviderSupported(String providerName) {
    return _providers.containsKey(providerName.toLowerCase());
  }

  /// Clear the current translation
  void clearTranslation() {
    _currentTranslation = null;
    notifyListeners();
  }

  /// Clear connection status and cached models
  void clearConnection() {
    _availableModels.clear();
    _connectionStatus = null;
    notifyListeners();
  }

  /// Get the current translation state
  Map<String, dynamic> getTranslationState() {
    return {
      'isTranslating': _isTranslating,
      'hasTranslation': _currentTranslation != null,
      'currentTranslation': _currentTranslation?.toJson(),
    };
  }

  /// Format translation result for display
  Map<String, dynamic>? formatForDisplay([TranslationResult? translation]) {
    final trans = translation ?? _currentTranslation;
    if (trans == null) return null;

    return {
      'original': trans.original,
      'translations': trans.translations,
      'languages': trans.languages,
      'timestamp': trans.timestamp.toLocal().toString(),
      'model': trans.config.selectedModel,
      'provider': trans.config.provider,
      'isComplete': trans.isComplete,
      'availableLanguages': trans.availableLanguages,
    };
  }

  /// Get translation statistics
  Map<String, dynamic> getTranslationStats([TranslationResult? translation]) {
    final trans = translation ?? _currentTranslation;
    if (trans == null) {
      return {
        'totalTranslations': 0,
        'completedTranslations': 0,
        'completionRate': 0.0,
      };
    }

    final completed = trans.availableLanguages.length;
    final total = trans.languages.length;

    return {
      'totalTranslations': total,
      'completedTranslations': completed,
      'completionRate': total > 0 ? completed / total : 0.0,
      'originalLength': trans.original.length,
      'averageTranslationLength': completed > 0
          ? trans.translations.values
                    .where((t) => t.isNotEmpty)
                    .map((t) => t.length)
                    .reduce((a, b) => a + b) /
                completed
          : 0.0,
    };
  }

  /// Get connection summary for display
  Map<String, dynamic> getConnectionSummary() {
    return {
      'isConnected': _connectionStatus?.success ?? false,
      'lastConnectionTime': _connectionStatus?.timestamp.toIso8601String(),
      'modelCount': _availableModels.length,
      'availableModels': _availableModels,
      'lastMessage': _connectionStatus?.message,
      'responseTime': _connectionStatus?.responseTimeMs,
    };
  }

  /// Validate LLM configuration using the model's validation
  Map<String, dynamic> validateConfig(LLMConfig config) {
    return config.validate();
  }

  /// Auto-detect LLM configuration by testing common endpoints
  Future<LLMConfig?> autoDetectConfig() async {
    final commonConfigs = [
      // Ollama configurations with qwen2.5 as preferred model
      LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'qwen2.5:latest',
      ),
      LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://127.0.0.1:11434',
        selectedModel: 'qwen2.5:latest',
      ),
      // LM Studio configurations
      LLMConfig(
        provider: 'lmstudio',
        serverUrl: 'http://localhost:1234',
        selectedModel: '',
      ),
      LLMConfig(
        provider: 'lmstudio',
        serverUrl: 'http://127.0.0.1:1234',
        selectedModel: '',
      ),
    ];

    for (final config in commonConfigs) {
      try {
        final status = await testConnection(config);
        if (status.success && _availableModels.isNotEmpty) {
          // Prefer qwen2.5 models if available
          String selectedModel = _availableModels.first;

          // Look for qwen2.5 models (various versions)
          final qwenModels = _availableModels
              .where((model) => model.toLowerCase().contains('qwen2.5'))
              .toList();

          if (qwenModels.isNotEmpty) {
            // Prefer qwen2.5:latest, then qwen2.5:7b, then any qwen2.5
            if (qwenModels.any((m) => m.contains('latest'))) {
              selectedModel = qwenModels.firstWhere(
                (m) => m.contains('latest'),
              );
            } else if (qwenModels.any((m) => m.contains('7b'))) {
              selectedModel = qwenModels.firstWhere((m) => m.contains('7b'));
            } else {
              selectedModel = qwenModels.first;
            }
          }

          return config.copyWith(selectedModel: selectedModel);
        }
      } catch (e) {
        // Continue to next configuration
        continue;
      }
    }

    return null; // No working configuration found
  }

  /// Auto-detect configuration with platform-specific optimizations
  Future<LLMConfig?> autoDetectConfigWithPlatformSupport({
    bool isAndroid = false,
  }) async {
    // Use different base URL for Android to avoid localhost issues
    final baseUrl = isAndroid ? 'http://10.0.2.2' : 'http://localhost';

    final commonConfigs = [
      // Ollama configurations
      LLMConfig(
        provider: 'ollama',
        serverUrl: '$baseUrl:11434',
        selectedModel: 'qwen2.5:latest',
      ),
      // LM Studio configurations
      LLMConfig(
        provider: 'lmstudio',
        serverUrl: '$baseUrl:1234',
        selectedModel: '',
      ),
    ];

    for (final config in commonConfigs) {
      try {
        final status = await testConnection(config);
        if (status.success && _availableModels.isNotEmpty) {
          String selectedModel = _selectBestModel(_availableModels);
          return config.copyWith(selectedModel: selectedModel);
        }
      } catch (e) {
        // Continue to next configuration
        continue;
      }
    }

    return null;
  }

  /// Select the best available model from a list
  String _selectBestModel(List<String> models) {
    if (models.isEmpty) return '';

    // Prefer qwen2.5 models
    final qwenModels = models
        .where((model) => model.toLowerCase().contains('qwen2.5'))
        .toList();

    if (qwenModels.isNotEmpty) {
      // Prefer qwen2.5:latest, then qwen2.5:7b, then any qwen2.5
      if (qwenModels.any((m) => m.contains('latest'))) {
        return qwenModels.firstWhere((m) => m.contains('latest'));
      } else if (qwenModels.any((m) => m.contains('7b'))) {
        return qwenModels.firstWhere((m) => m.contains('7b'));
      } else {
        return qwenModels.first;
      }
    }

    // Fallback to other good models
    final preferredModels = ['llama3.2', 'llama3.1', 'mistral', 'gemma2'];
    for (final preferred in preferredModels) {
      final match = models.firstWhere(
        (model) => model.toLowerCase().contains(preferred),
        orElse: () => '',
      );
      if (match.isNotEmpty) return match;
    }

    return models.first;
  }

  /// Auto-configure LLM connection with comprehensive platform support and retry mechanism
  Future<LLMConfig?> autoConfigureLLM({
    bool enableRetry = true,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
    bool isAndroid = false,
  }) async {
    if (_isAutoConfiguring) {
      return _autoDetectedConfig;
    }

    _isAutoConfiguring = true;
    isAutoConfiguringNotifier.value = true;
    notifyListeners();

    try {
      // Use enhanced auto-detection logic with platform support and retry mechanism
      for (
        int attempt = 1;
        attempt <= (enableRetry ? maxRetries : 1);
        attempt++
      ) {
        try {
          // Try platform-specific auto-detection first
          final autoDetected = await autoDetectConfigWithPlatformSupport(
            isAndroid: isAndroid,
          );

          if (autoDetected != null) {
            _autoDetectedConfig = autoDetected;
            notifyListeners();
            return autoDetected;
          }

          // Fallback to basic auto-detection
          final basicAutoDetected = await autoDetectConfig();
          if (basicAutoDetected != null) {
            _autoDetectedConfig = basicAutoDetected;
            notifyListeners();
            return basicAutoDetected;
          }

          if (attempt < (enableRetry ? maxRetries : 1)) {
            await Future.delayed(retryDelay);
          }
        } catch (e) {
          if (attempt < (enableRetry ? maxRetries : 1)) {
            await Future.delayed(retryDelay);
          }
        }
      }

      return null;
    } finally {
      _isAutoConfiguring = false;
      isAutoConfiguringNotifier.value = false;
      notifyListeners();
    }
  }

  /// Comprehensive auto-configuration that attempts multiple strategies
  /// This replaces the duplicate AutoConfigService implementations in applications
  Future<LLMConfig?> attemptAutoConfiguration({
    bool isAndroid = false,
    bool enableFileSystemCheck = true,
    bool enableNetworkCheck = true,
  }) async {
    try {
      // Strategy 1: Network-based auto-detection (existing logic)
      if (enableNetworkCheck) {
        final networkConfig = await autoConfigureLLM(isAndroid: isAndroid);
        if (networkConfig != null) {
          return networkConfig;
        }
      }

      // Strategy 2: File system-based detection (from removed AutoConfigService)
      if (enableFileSystemCheck) {
        final fileSystemConfig = await _detectConfigFromFileSystem();
        if (fileSystemConfig != null) {
          // Verify the detected config works
          final testResult = await testConnection(fileSystemConfig);
          if (testResult.success) {
            _autoDetectedConfig = fileSystemConfig;
            notifyListeners();
            return fileSystemConfig;
          }
        }
      }

      return null;
    } catch (e) {
      throw ConfigurationException(
        'Auto-configuration failed: ${e.toString()}',
        details: {'originalError': e.toString()},
      );
    }
  }

  /// Detect configuration from file system (consolidated from removed AutoConfigService)
  Future<LLMConfig?> _detectConfigFromFileSystem() async {
    try {
      if (Platform.isLinux || Platform.isMacOS) {
        return await _configureForLinuxOrMac();
      } else if (Platform.isWindows) {
        return await _configureForWindows();
      }
    } catch (e) {
      // Don't throw, just return null for graceful fallback
      return null;
    }
    return null;
  }

  /// Linux/macOS configuration detection
  Future<LLMConfig?> _configureForLinuxOrMac() async {
    final home = Platform.environment['HOME'];
    if (home != null) {
      final ollamaConfig = File('$home/.ollama/config.json');
      if (await ollamaConfig.exists()) {
        return LLMConfig(
          provider: 'ollama',
          serverUrl: 'http://localhost:11434',
          selectedModel: 'qwen2.5:latest', // Use preferred model
        );
      }
    }
    return null;
  }

  /// Windows configuration detection
  Future<LLMConfig?> _configureForWindows() async {
    final home = Platform.environment['USERPROFILE'];
    if (home != null) {
      final ollamaConfig = File('$home\\.ollama\\config.json');
      if (await ollamaConfig.exists()) {
        return LLMConfig(
          provider: 'ollama',
          serverUrl: 'http://localhost:11434',
          selectedModel: 'qwen2.5:latest', // Use preferred model
        );
      }
    }
    return null;
  }

  /// Get recommended settings for a provider
  Map<String, dynamic> getRecommendedSettings(
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

  /// Clear auto-detected configuration
  void clearAutoConfig() {
    _autoDetectedConfig = null;
    notifyListeners();
  }

  /// Get auto-configuration summary
  Map<String, dynamic> getAutoConfigSummary() {
    return {
      'isAutoConfiguring': _isAutoConfiguring,
      'hasAutoConfig': _autoDetectedConfig != null,
      'autoDetectedProvider': _autoDetectedConfig?.provider,
      'autoDetectedModel': _autoDetectedConfig?.selectedModel,
    };
  }

  /// Unified API method for applications to perform translation with auto-configuration
  /// This provides a single entry point that handles configuration and translation
  Future<TranslationResult> translateWithAutoConfig(
    String inputText,
    List<String> targetLanguages, {
    LLMConfig? config,
    Map<String, dynamic>? additionalParams,
    bool enableRetry = true,
    bool isAndroid = false,
  }) async {
    LLMConfig? workingConfig = config;

    // If no config provided or config is invalid, try auto-configuration
    if (workingConfig == null || !validateConfig(workingConfig)['isValid']) {
      workingConfig = await attemptAutoConfiguration(isAndroid: isAndroid);

      if (workingConfig == null) {
        throw ConfigurationException(
          'No valid configuration available and auto-configuration failed. Please configure LLM settings manually.',
        );
      }
    }

    // Perform translation with the working config
    return await translateText(
      inputText,
      targetLanguages,
      workingConfig,
      additionalParams: additionalParams,
      enableRetry: enableRetry,
    );
  }

  /// Check if the service is ready for translation (has valid config)
  bool get isReady {
    return _autoDetectedConfig != null &&
        validateConfig(_autoDetectedConfig!)['isValid'] as bool;
  }

  /// Get the current working configuration
  LLMConfig? get currentConfig => _autoDetectedConfig;

  /// Initialize the service with auto-configuration
  Future<bool> initialize({bool isAndroid = false}) async {
    try {
      final config = await attemptAutoConfiguration(isAndroid: isAndroid);
      return config != null;
    } catch (e) {
      return false;
    }
  }

  /// Convert generic exceptions to specific translation exceptions with enhanced error handling
  AlouetteTranslationError handleException(
    Object error,
    String providerName,
    String serverUrl,
  ) {
    if (error is TranslationException) {
      return error;
    }

    if (error is SocketException) {
      if (error.message.contains('Connection refused') ||
          error.message.contains('network is unreachable') ||
          error.message.contains('No route to host')) {
        return LLMConnectionException(
          'Cannot connect to $providerName server at $serverUrl. Please check if the server is running and accessible.',
          details: {
            'provider': providerName,
            'serverUrl': serverUrl,
            'originalError': error.message,
          },
        );
      } else if (error.message.contains('timeout') ||
          error.message.contains('timed out')) {
        return TranslationTimeoutException(
          'Translation request timed out. The server may be overloaded.',
          details: {'provider': providerName, 'serverUrl': serverUrl},
        );
      } else if (error.message.contains('Connection reset') ||
          error.message.contains('Broken pipe')) {
        return LLMConnectionException(
          'Connection to $providerName server was reset. The server may have restarted.',
          details: {'provider': providerName, 'serverUrl': serverUrl},
        );
      }
    }

    if (error is FormatException) {
      return TranslationException(
        'Invalid response format from $providerName server. The server may be misconfigured.',
        code: 'INVALID_RESPONSE_FORMAT',
        details: {'provider': providerName, 'originalError': error.message},
      );
    }

    if (error is TimeoutException) {
      return TranslationTimeoutException(
        'Translation request timed out after waiting for server response.',
        timeout: error.duration,
        details: {'provider': providerName, 'serverUrl': serverUrl},
      );
    }

    // Handle HTTP-related errors
    if (error.toString().contains('XMLHttpRequest')) {
      return LLMConnectionException(
        'Network request failed. This may be due to CORS issues or network connectivity problems.',
        details: {
          'provider': providerName,
          'serverUrl': serverUrl,
          'hint': 'Check CORS settings if running in web browser',
        },
      );
    }

    return TranslationException(
      '$providerName translation failed: ${error.toString()}',
      code: 'UNKNOWN_ERROR',
      details: {
        'provider': providerName,
        'serverUrl': serverUrl,
        'errorType': error.runtimeType.toString(),
      },
    );
  }

  /// Create HTTP-specific exceptions based on status codes
  AlouetteTranslationError createHttpException(
    int statusCode,
    String body,
    String providerName,
  ) {
    switch (statusCode) {
      case 401:
        return LLMAuthenticationException(
          '$providerName API authentication failed',
        );
      case 404:
        return LLMModelNotFoundException(
          '$providerName model not found',
          'unknown',
        );
      case 429:
        return RateLimitException('$providerName rate limit exceeded');
      case 500:
        return TranslationException(
          '$providerName server error: $body',
          code: 'SERVER_ERROR',
        );
      case 503:
        return TranslationException(
          '$providerName service unavailable: $body',
          code: 'SERVICE_UNAVAILABLE',
        );
      default:
        return TranslationException(
          '$providerName API request failed: HTTP $statusCode: $body',
          code: 'HTTP_ERROR',
        );
    }
  }

  /// Validate translation request before processing
  void _validateTranslationRequest(
    String inputText,
    List<String> targetLanguages,
    LLMConfig config,
  ) {
    if (inputText.trim().isEmpty) {
      throw TranslationException(
        'Input text cannot be empty',
        code: 'EMPTY_INPUT',
      );
    }

    if (targetLanguages.isEmpty) {
      throw TranslationException(
        'At least one target language must be specified',
        code: 'NO_TARGET_LANGUAGES',
      );
    }

    if (inputText.length > 10000) {
      throw TranslationException(
        'Input text is too long (maximum 10,000 characters)',
        code: 'TEXT_TOO_LONG',
      );
    }

    final validation = config.validate();
    if (!validation['isValid']) {
      throw ConfigurationException(
        'Invalid configuration: ${validation['errors'].join(', ')}',
      );
    }

    if (!isProviderSupported(config.provider)) {
      throw UnsupportedProviderException(
        'Provider ${config.provider} is not supported',
        config.provider,
        availableProviders,
      );
    }
  }

  /// Enhanced error recovery with retry logic
  Future<String> _translateWithRetry(
    TranslationProvider provider,
    String text,
    String targetLanguage,
    LLMConfig config, {
    Map<String, dynamic>? additionalParams,
    int maxRetries = 2,
  }) async {
    Exception? lastException;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await provider.translateText(
          text: text,
          targetLanguage: targetLanguage,
          config: config,
          additionalParams: additionalParams,
        );
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        // Don't retry on certain errors
        if (e is LLMAuthenticationException ||
            e is UnsupportedProviderException ||
            e is ConfigurationException) {
          rethrow;
        }

        // Wait before retry (exponential backoff)
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      }
    }

    // All retries failed
    throw lastException!;
  }

  /// Clean translation result by removing unwanted prefixes, suffixes, and formatting
  String cleanTranslationResult(String rawText, String targetLanguage) {
    if (rawText.trim().isEmpty) {
      return '';
    }

    String cleaned = rawText.trim();

    // Remove think tags and their content
    cleaned = _removeThinkTags(cleaned);

    // Remove common translation prefixes
    cleaned = _removePrefixes(cleaned);

    // Remove trailing punctuation that might be artifacts
    cleaned = _removeTrailingArtifacts(cleaned);

    // Remove quotes if they wrap the entire text
    cleaned = _removeWrappingQuotes(cleaned);

    // Handle multi-line responses by taking the first meaningful line
    cleaned = _extractMainTranslation(cleaned);

    // Final cleanup
    cleaned = cleaned.trim();

    // If cleaning resulted in empty text, return the first non-empty line of original
    if (cleaned.isEmpty) {
      cleaned = _fallbackExtraction(rawText);
    }

    return cleaned;
  }

  /// Remove common translation prefixes
  String _removePrefixes(String text) {
    final prefixPatterns = [
      // English prefixes
      RegExp(r'^translation:\s*', caseSensitive: false),
      RegExp(r'^translated text:\s*', caseSensitive: false),
      RegExp(r'^here is the translation:\s*', caseSensitive: false),
      RegExp(r'^the translation is:\s*', caseSensitive: false),
      RegExp(r'^answer:\s*', caseSensitive: false),
      RegExp(r'^response:\s*', caseSensitive: false),
      RegExp(r'^result:\s*', caseSensitive: false),
      RegExp(r'^output:\s*', caseSensitive: false),

      // Numbered prefixes
      RegExp(r'^\d+\.\s*'),
      RegExp(r'^\d+\)\s*'),
      RegExp(r'^[-*]\s*'),

      // Generic patterns - more specific to avoid removing actual translation content
      RegExp(r'^[a-zA-Z\s]*translation[a-zA-Z\s]*:\s*', caseSensitive: false),
      RegExp(r'^[a-zA-Z\s]*answer[a-zA-Z\s]*:\s*', caseSensitive: false),
      RegExp(r'^[a-zA-Z\s]*response[a-zA-Z\s]*:\s*', caseSensitive: false),
      RegExp(r'^[a-zA-Z\s]*result[a-zA-Z\s]*:\s*', caseSensitive: false),
      RegExp(r'^[a-zA-Z\s]*output[a-zA-Z\s]*:\s*', caseSensitive: false),
    ];

    String result = text;
    for (final pattern in prefixPatterns) {
      result = result.replaceFirst(pattern, '');
    }

    return result.trim();
  }

  /// Remove think tags and their content
  String _removeThinkTags(String text) {
    String result = text;

    // Remove <think>...</think> blocks including multiline content
    result = result.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '');

    // Remove <thinking>...</thinking> blocks including multiline content
    result = result.replaceAll(
      RegExp(r'<thinking>.*?</thinking>', dotAll: true),
      '',
    );

    // Remove standalone opening/closing tags in case they got separated
    result = result.replaceAll(RegExp(r'</?think>', caseSensitive: false), '');
    result = result.replaceAll(
      RegExp(r'</?thinking>', caseSensitive: false),
      '',
    );

    return result.trim();
  }

  /// Remove quotes that wrap the entire text
  String _removeWrappingQuotes(String text) {
    String result = text.trim();

    // Remove outer quotes if they wrap the entire text
    if (result.length >= 2) {
      if ((result.startsWith('"') && result.endsWith('"')) ||
          (result.startsWith("'") && result.endsWith("'")) ||
          (result.startsWith('`') && result.endsWith('`'))) {
        result = result.substring(1, result.length - 1).trim();
      }

      // Handle smart quotes
      if ((result.startsWith('"') && result.endsWith('"')) ||
          (result.startsWith(''') && result.endsWith('''))) {
        result = result.substring(1, result.length - 1).trim();
      }
    }

    return result;
  }

  /// Remove trailing artifacts that might be added by the model
  String _removeTrailingArtifacts(String text) {
    String result = text.trim();

    // Remove trailing explanatory text
    final trailingPatterns = [
      RegExp(r'\s*\(.*translation.*\)$', caseSensitive: false),
      RegExp(r'\s*\[.*translation.*\]$', caseSensitive: false),
      RegExp(r'\s*\(.*\)$'), // Remove any parenthetical at the end
      RegExp(r'\s*--.*$'),
      RegExp(r'\s*\.\.\.$'),
    ];

    for (final pattern in trailingPatterns) {
      result = result.replaceFirst(pattern, '');
    }

    return result.trim();
  }

  /// Extract the main translation from multi-line responses
  String _extractMainTranslation(String text) {
    final lines = text.split('\n').map((line) => line.trim()).toList();

    // If single line, return as is
    if (lines.length == 1) {
      return lines.first;
    }

    // Find the first substantial line (not empty, not just punctuation)
    for (final line in lines) {
      if (line.isNotEmpty && _isSubstantialText(line)) {
        return line;
      }
    }

    // Fallback to first non-empty line
    for (final line in lines) {
      if (line.isNotEmpty) {
        return line;
      }
    }

    return text; // Return original if no good line found
  }

  /// Check if text is substantial (not just punctuation or very short)
  bool _isSubstantialText(String text) {
    if (text.length < 1) return false;

    // Check if it's mostly punctuation - be more lenient
    final alphanumericCount = text.replaceAll(RegExp(r'[^\w\s]'), '').length;
    return alphanumericCount >= text.length * 0.3; // Reduced from 0.5 to 0.3
  }

  /// Fallback extraction when main cleaning fails
  String _fallbackExtraction(String rawText) {
    final lines = rawText.split('\n');

    // Find first non-empty line
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    return rawText.trim();
  }
}
