import 'package:flutter/material.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';

class AppTranslationController extends ChangeNotifier {
  final TranslationService _translationService;
  final LLMConfigService _llmConfigService;

  AppTranslationController()
      : _translationService = ServiceLocator.get<TranslationService>(),
        _llmConfigService = LLMConfigService();

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
    await _performAutoConfiguration();
  }

  /// Update LLM configuration
  void updateLLMConfig(LLMConfig config) {
    _llmConfig = config;
    _isConfigured = config.selectedModel.isNotEmpty;
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
    return await showDialog<LLMConfig>(
      context: context,
      builder: (context) => LLMConfigDialog(
        initialConfig: _llmConfig,
        llmConfigService: _llmConfigService,
      ),
    );
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
        _llmConfig = autoConfig;
        _isConfigured = true;
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