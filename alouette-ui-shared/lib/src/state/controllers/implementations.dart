/// Concrete implementations of common UI controllers
library alouette_ui_shared.state.controllers.implementations;

import 'dart:async';

import '../../../alouette_ui_shared.dart';

/// Translation controller implementation
class TranslationController extends BaseStateController
    implements ITranslationController {
  final ITranslationService _translationService;
  final StreamController<Map<String, String>> _translationController =
      StreamController<Map<String, String>>.broadcast();

  String _inputText = '';
  String? _sourceLanguage;
  final List<String> _targetLanguages = [];
  final Map<String, String> _translations = {};

  TranslationController(this._translationService);

  @override
  String get inputText => _inputText;

  @override
  set inputText(String value) {
    ensureNotDisposed();
    if (_inputText != value) {
      _inputText = value;
      clearTranslations();
    }
  }

  @override
  String? get sourceLanguage => _sourceLanguage;

  @override
  List<String> get targetLanguages => List.unmodifiable(_targetLanguages);

  @override
  Map<String, String> get translations => Map.unmodifiable(_translations);

  @override
  Stream<Map<String, String>> get translationStream =>
      _translationController.stream;

  @override
  void setSourceLanguage(String? languageCode) {
    ensureNotDisposed();
    if (_sourceLanguage != languageCode) {
      _sourceLanguage = languageCode;
      clearTranslations();
    }
  }

  @override
  void setTargetLanguages(List<String> languageCodes) {
    ensureNotDisposed();
    _targetLanguages.clear();
    _targetLanguages.addAll(languageCodes);
    clearTranslations();
  }

  @override
  Future<void> translate() async {
    ensureNotDisposed();

    if (_inputText.isEmpty) {
      setError('Input text cannot be empty');
      return;
    }

    if (_targetLanguages.isEmpty) {
      setError('Please select at least one target language');
      return;
    }

    await executeAsync(() async {
      final results = <String, String>{};

      for (final targetLang in _targetLanguages) {
        try {
          final translation = await _translationService.translate(
            text: _inputText,
            sourceLanguage: _sourceLanguage,
            targetLanguage: targetLang,
          );
          results[targetLang] = translation;
        } catch (e) {
          results[targetLang] = 'Translation failed: $e';
        }
      }

      _translations.clear();
      _translations.addAll(results);
      _translationController.add(translations);
    });
  }

  @override
  void clearTranslations() {
    ensureNotDisposed();
    if (_translations.isNotEmpty) {
      _translations.clear();
      _translationController.add(translations);
    }
  }

  @override
  void onDispose() {
    _translationController.close();
    super.onDispose();
  }
}

/// TTS controller implementation
class TTSController extends BaseStateController implements ITTSController {
  final ITTSService _ttsService;
  final StreamController<bool> _speakingController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _pausedController =
      StreamController<bool>.broadcast();

  String _text = '';
  String? _selectedVoice;
  List<String> _availableVoices = [];
  bool _isSpeaking = false;
  bool _isPaused = false;
  double _speechRate = 0.5;
  double _speechPitch = 0.5;
  double _speechVolume = 1.0;

  TTSController(this._ttsService) {
    _initializeVoices();
  }

  @override
  String get text => _text;

  @override
  set text(String value) {
    ensureNotDisposed();
    _text = value;
  }

  @override
  String? get selectedVoice => _selectedVoice;

  @override
  List<String> get availableVoices => List.unmodifiable(_availableVoices);

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  bool get isPaused => _isPaused;

  @override
  double get speechRate => _speechRate;

  @override
  double get speechPitch => _speechPitch;

  @override
  double get speechVolume => _speechVolume;

  @override
  Stream<bool> get speakingStream => _speakingController.stream;

  @override
  Stream<bool> get pausedStream => _pausedController.stream;

  @override
  void setVoice(String voiceId) {
    ensureNotDisposed();
    _selectedVoice = voiceId;
  }

  @override
  void setSpeechRate(double rate) {
    ensureNotDisposed();
    _speechRate = rate.clamp(0.0, 1.0);
  }

  @override
  void setSpeechPitch(double pitch) {
    ensureNotDisposed();
    _speechPitch = pitch.clamp(0.0, 1.0);
  }

  @override
  void setSpeechVolume(double volume) {
    ensureNotDisposed();
    _speechVolume = volume.clamp(0.0, 1.0);
  }

  @override
  Future<void> speak() async {
    ensureNotDisposed();

    if (_text.isEmpty) {
      setError('Text cannot be empty');
      return;
    }

    await executeAsync(() async {
      _setSpeaking(true);
      _setPaused(false);

      await _ttsService.speak(
        _text,
        voiceName: _selectedVoice,
        rate: _speechRate,
        pitch: _speechPitch,
        volume: _speechVolume,
      );

      _setSpeaking(false);
    });
  }

  @override
  Future<void> pause() async {
    ensureNotDisposed();
    await executeAsync(() async {
      await _ttsService.pause();
      _setPaused(true);
    });
  }

  @override
  Future<void> resume() async {
    ensureNotDisposed();
    await executeAsync(() async {
      await _ttsService.resume();
      _setPaused(false);
    });
  }

  @override
  Future<void> stop() async {
    ensureNotDisposed();
    await executeAsync(() async {
      await _ttsService.stop();
      _setSpeaking(false);
      _setPaused(false);
    });
  }

  Future<void> _initializeVoices() async {
    try {
      final voices = await _ttsService.getAvailableVoices();
      _availableVoices = voices.map((voice) => voice.name).toList();
      if (_availableVoices.isNotEmpty && _selectedVoice == null) {
        _selectedVoice = _availableVoices.first;
      }
    } catch (e) {
      setError('Failed to load voices: $e');
    }
  }

  void _setSpeaking(bool speaking) {
    if (_isSpeaking != speaking) {
      _isSpeaking = speaking;
      _speakingController.add(speaking);
    }
  }

  void _setPaused(bool paused) {
    if (_isPaused != paused) {
      _isPaused = paused;
      _pausedController.add(paused);
    }
  }

  @override
  void onDispose() {
    _speakingController.close();
    _pausedController.close();
    super.onDispose();
  }
}

/// Language selection controller implementation
class LanguageSelectionController extends BaseSelectionController<String> {
  final List<String> _availableLanguages;

  LanguageSelectionController(this._availableLanguages);

  List<String> get availableLanguages => List.unmodifiable(_availableLanguages);

  /// Select languages by their codes
  void selectLanguageCodes(List<String> codes) {
    ensureNotDisposed();
    clearSelection();
    for (final code in codes) {
      if (_availableLanguages.contains(code)) {
        select(code);
      }
    }
  }

  /// Check if a language is available
  bool isLanguageAvailable(String languageCode) {
    return _availableLanguages.contains(languageCode);
  }
}

/// Form controller implementation
class FormController extends BaseStateController implements IFormController {
  final StreamController<Map<String, dynamic>> _valuesController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _formValidationController =
      StreamController<bool>.broadcast();
  final StreamController<Map<String, String>> _fieldErrorsController =
      StreamController<Map<String, String>>.broadcast();

  final Map<String, dynamic> _values = {};
  final Map<String, String> _fieldErrors = {};
  final Map<String, bool Function(dynamic)> _validators = {};

  @override
  Map<String, dynamic> get values => Map.unmodifiable(_values);

  @override
  Stream<Map<String, dynamic>> get valuesStream => _valuesController.stream;

  @override
  bool get isFormValid => _fieldErrors.isEmpty && _values.isNotEmpty;

  @override
  Stream<bool> get formValidationStream => _formValidationController.stream;

  @override
  Map<String, String> get fieldErrors => Map.unmodifiable(_fieldErrors);

  @override
  Stream<Map<String, String>> get fieldErrorsStream =>
      _fieldErrorsController.stream;

  /// Add a validator for a field
  void addValidator(String fieldName, bool Function(dynamic) validator) {
    ensureNotDisposed();
    _validators[fieldName] = validator;
  }

  /// Remove a validator for a field
  void removeValidator(String fieldName) {
    ensureNotDisposed();
    _validators.remove(fieldName);
  }

  @override
  T? getValue<T>(String fieldName) {
    final value = _values[fieldName];
    return value is T ? value : null;
  }

  @override
  void setValue(String fieldName, dynamic value) {
    ensureNotDisposed();
    _values[fieldName] = value;
    _valuesController.add(values);
    validateField(fieldName);
  }

  @override
  bool validateField(String fieldName) {
    ensureNotDisposed();

    final validator = _validators[fieldName];
    if (validator == null) {
      _fieldErrors.remove(fieldName);
      _notifyFieldErrors();
      return true;
    }

    final value = _values[fieldName];
    try {
      if (validator(value)) {
        _fieldErrors.remove(fieldName);
        _notifyFieldErrors();
        _notifyFormValidation();
        return true;
      } else {
        _fieldErrors[fieldName] = 'Invalid value';
        _notifyFieldErrors();
        _notifyFormValidation();
        return false;
      }
    } catch (e) {
      _fieldErrors[fieldName] = e.toString();
      _notifyFieldErrors();
      _notifyFormValidation();
      return false;
    }
  }

  @override
  bool validateForm() {
    ensureNotDisposed();

    bool isValid = true;
    for (final fieldName in _validators.keys) {
      if (!validateField(fieldName)) {
        isValid = false;
      }
    }
    return isValid;
  }

  @override
  void reset() {
    ensureNotDisposed();
    _values.clear();
    _fieldErrors.clear();
    _valuesController.add(values);
    _fieldErrorsController.add(fieldErrors);
    _formValidationController.add(isFormValid);
  }

  @override
  Future<void> submit() async {
    ensureNotDisposed();

    if (!validateForm()) {
      setError('Please fix form errors before submitting');
      return;
    }

    await executeAsync(() async {
      // Override this method to implement form submission
      await onSubmit(values);
    });
  }

  /// Override this method to implement custom form submission logic
  Future<void> onSubmit(Map<String, dynamic> formData) async {
    // Default implementation does nothing
  }

  void _notifyFieldErrors() {
    _fieldErrorsController.add(fieldErrors);
  }

  void _notifyFormValidation() {
    _formValidationController.add(isFormValid);
  }

  @override
  void onDispose() {
    _valuesController.close();
    _formValidationController.close();
    _fieldErrorsController.close();
    super.onDispose();
  }
}

/// Search controller implementation
class SearchController extends BaseStateController
    implements ISearchController {
  final StreamController<List<dynamic>> _resultsController =
      StreamController<List<dynamic>>.broadcast();

  String _query = '';
  final List<dynamic> _results = [];
  bool _hasMoreResults = false;
  int _currentPage = 0;
  static const int _pageSize = 20;

  @override
  String get query => _query;

  @override
  set query(String value) {
    ensureNotDisposed();
    if (_query != value) {
      _query = value;
      _results.clear();
      _currentPage = 0;
      _hasMoreResults = false;
      _resultsController.add(results);
    }
  }

  @override
  List<dynamic> get results => List.unmodifiable(_results);

  @override
  Stream<List<dynamic>> get resultsStream => _resultsController.stream;

  @override
  bool get hasMoreResults => _hasMoreResults;

  @override
  Future<void> search() async {
    ensureNotDisposed();

    if (_query.isEmpty) {
      _results.clear();
      _resultsController.add(results);
      return;
    }

    await executeAsync(() async {
      _currentPage = 0;
      final searchResults =
          await performSearch(_query, _currentPage, _pageSize);
      _results.clear();
      _results.addAll(searchResults);
      _hasMoreResults = searchResults.length == _pageSize;
      _resultsController.add(results);
    });
  }

  @override
  Future<void> loadMore() async {
    ensureNotDisposed();

    if (!_hasMoreResults || isLoading) return;

    await executeAsync(() async {
      _currentPage++;
      final searchResults =
          await performSearch(_query, _currentPage, _pageSize);
      _results.addAll(searchResults);
      _hasMoreResults = searchResults.length == _pageSize;
      _resultsController.add(results);
    });
  }

  @override
  void clearSearch() {
    ensureNotDisposed();
    _query = '';
    _results.clear();
    _currentPage = 0;
    _hasMoreResults = false;
    _resultsController.add(results);
  }

  /// Override this method to implement custom search logic
  Future<List<dynamic>> performSearch(
      String query, int page, int pageSize) async {
    // Default implementation returns empty list
    return [];
  }

  @override
  void onDispose() {
    _resultsController.close();
    super.onDispose();
  }
}
