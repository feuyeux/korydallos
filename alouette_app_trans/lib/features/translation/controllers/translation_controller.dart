import 'package:flutter/material.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'package:alouette_ui/alouette_ui.dart';

class AppTranslationController extends ChangeNotifier {
  final TranslationService _translationService;

  AppTranslationController()
    : _translationService = ServiceLocator.get<TranslationService>();

  LLMConfig _llmConfig = const LLMConfig(
    provider: 'ollama',
    serverUrl: 'http://localhost:11434',
    selectedModel: '',
  );

  final TextEditingController textController = TextEditingController();
  final List<String> _selectedLanguages = [];
  bool _isConfigured = false;
  bool _isAutoConfiguring = false;
  String _autoConfigStatus = '';
  bool _isTranslating = false;

  // Getters
  LLMConfig get llmConfig => _llmConfig;
  List<String> get selectedLanguages => List.unmodifiable(_selectedLanguages);
  bool get isConfigured => _isConfigured;
  bool get isAutoConfiguring => _isAutoConfiguring;
  String get autoConfigStatus => _autoConfigStatus;
  bool get isTranslating => _isTranslating;
  TranslationService get translationService => _translationService;

  /// Initialize the controller and perform auto-configuration
  Future<void> initialize() async {
    // Load saved configuration if available
    await _loadSavedConfiguration();

    // Perform auto-configuration if no saved config
    if (!_isConfigured) {
      await _performAutoConfiguration();
    }
  }

  /// Load saved configuration from persistent storage
  Future<void> _loadSavedConfiguration() async {
    try {
      final configManager = ServiceLocator.get<ConfigurationManager>();
      final appConfig = await configManager.getConfiguration();

      if (appConfig.translationConfig != null) {
        _llmConfig = appConfig.translationConfig!;
        _isConfigured = _llmConfig.selectedModel.isNotEmpty;
        notifyListeners();
      }
    } catch (e) {
      // If loading fails, continue with default config
      debugPrint('Failed to load saved configuration: $e');
    }
  }

  /// Update LLM configuration and save to persistent storage
  Future<void> updateLLMConfig(LLMConfig config) async {
    _llmConfig = config;
    _isConfigured = config.selectedModel.isNotEmpty;

    // Save to persistent storage
    try {
      final configManager = ServiceLocator.get<ConfigurationManager>();
      final currentAppConfig = await configManager.getConfiguration();
      final updatedAppConfig = currentAppConfig.copyWith(
        translationConfig: config,
      );

      await configManager.updateConfiguration(updatedAppConfig);
    } catch (e) {
      debugPrint('Failed to save configuration: $e');
      // Don't rethrow - we still want to update the UI even if saving fails
    }

    notifyListeners();
  }

  /// Add or remove a language from selection
  void toggleLanguage(String language, bool selected) {
    if (selected) {
      if (!_selectedLanguages.contains(language)) {
        _selectedLanguages.add(language);
      }
    } else {
      _selectedLanguages.remove(language);
    }
    notifyListeners();
  }

  /// Update selected languages list
  void updateSelectedLanguages(List<String> languages) {
    _selectedLanguages.clear();
    _selectedLanguages.addAll(languages);
    notifyListeners();
  }

  /// Perform translation
  Future<String?> translateText() async {
    if (textController.text.trim().isEmpty) {
      return 'Please enter text to translate';
    }

    if (_selectedLanguages.isEmpty) {
      return 'Please select target languages';
    }

    if (!_isConfigured) {
      return 'Please configure LLM settings first';
    }

    try {
      _isTranslating = true;
      notifyListeners();

      await _translationService.translateText(
        textController.text,
        _selectedLanguages,
        _llmConfig,
      );

      _isTranslating = false;
      notifyListeners();
      return null; // Success
    } catch (error) {
      _isTranslating = false;
      notifyListeners();
      return error.toString();
    }
  }

  /// Show LLM configuration dialog
  Future<LLMConfig?> showConfigDialog(BuildContext context) async {
    final result = await showDialog<LLMConfig>(
      context: context,
      builder: (context) => LLMConfigDialog(
        initialConfig: _llmConfig,
        translationService: _translationService,
      ),
    );

    // If user saved a new configuration, update and save it
    if (result != null) {
      await updateLLMConfig(result);
    }

    return result;
  }

  /// Perform automatic configuration
  Future<void> _performAutoConfiguration() async {
    _isAutoConfiguring = true;
    _autoConfigStatus = 'Testing connection to ollama...';
    notifyListeners();

    try {
      // Use unified translation service auto-configuration
      final autoConfig = await _translationService.attemptAutoConfiguration();

      if (autoConfig != null) {
        await updateLLMConfig(autoConfig);
        _isAutoConfiguring = false;
        _autoConfigStatus = '';
        notifyListeners();
      } else {
        _isAutoConfiguring = false;
        _autoConfigStatus = '';
        notifyListeners();
      }
    } catch (error) {
      _isAutoConfiguring = false;
      _autoConfigStatus = '';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}
