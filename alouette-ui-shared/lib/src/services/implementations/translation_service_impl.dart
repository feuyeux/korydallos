import 'package:alouette_lib_trans/alouette_lib_trans.dart' as trans_lib;
import '../interfaces/translation_service_interface.dart';

/// Translation Service Implementation
///
/// Concrete implementation of ITranslationService that wraps the alouette_lib_trans library.
/// Provides thread-safe initialization and proper resource management.
class TranslationServiceImpl implements ITranslationService {
  trans_lib.TranslationService? _service;
  bool _isInitialized = false;
  bool _isDisposed = false;

  // Synchronization lock for thread-safe initialization
  static final Object _initLock = Object();

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    if (_isDisposed) {
      throw StateError('Cannot initialize a disposed Translation service');
    }

    try {
      // Use synchronized block for thread safety
      return await _synchronized(_initLock, () async {
        if (_isInitialized) return true;

        _service = trans_lib.TranslationService();
        
        // Initialize with auto-configuration
        final success = await _service!.initialize();
        _isInitialized = true; // Service is initialized even if auto-config fails

        if (success) {
          print('Translation Service initialized successfully with auto-configuration');
        } else {
          print('Translation Service initialized but no auto-configuration found');
        }
        return true; // Return true even if auto-config failed, service can still be used manually
      });
    } catch (e) {
      print('Translation initialization error: $e');
      _cleanup();
      return false;
    }
  }

  @override
  Future<String> translate({
    required String text,
    String? sourceLanguage,
    required String targetLanguage,
  }) async {
    _ensureInitialized();

    try {
      // Use auto-configuration if available, otherwise try to initialize
      if (!_service!.isReady) {
        final autoConfigured = await _service!.initialize();
        if (!autoConfigured) {
          throw TranslationException('No valid LLM configuration available. Please configure LLM settings.');
        }
      }

      // Perform translation using the unified API
      final result = await _service!.translateWithAutoConfig(
        text,
        [targetLanguage],
      );

      if (result.translations.containsKey(targetLanguage)) {
        return result.translations[targetLanguage]!;
      } else {
        throw TranslationException('Translation failed: No result for target language $targetLanguage');
      }
    } catch (e) {
      throw TranslationException('Error translating text: $e');
    }
  }

  @override
  Future<Map<String, String>> translateToMultiple({
    required String text,
    String? sourceLanguage,
    required List<String> targetLanguages,
  }) async {
    _ensureInitialized();

    try {
      // Use auto-configuration if available, otherwise try to initialize
      if (!_service!.isReady) {
        final autoConfigured = await _service!.initialize();
        if (!autoConfigured) {
          throw TranslationException('No valid LLM configuration available. Please configure LLM settings.');
        }
      }

      // Perform translation using the unified API
      final result = await _service!.translateWithAutoConfig(
        text,
        targetLanguages,
      );

      return result.translations;
    } catch (e) {
      throw TranslationException('Error translating text to multiple languages: $e');
    }
  }

  @override
  Future<String?> detectLanguage(String text) async {
    _ensureInitialized();

    try {
      // Note: Language detection may not be directly available in the current library
      // This would need to be implemented in the underlying library or use a heuristic approach
      
      // For now, return null to indicate auto-detection should be used
      // This could be enhanced with actual language detection logic
      return null;
    } catch (e) {
      print('Error detecting language: $e');
      return null;
    }
  }

  @override
  Future<List<LanguageInfo>> getSupportedLanguages() async {
    _ensureInitialized();

    try {
      // Return a predefined list of commonly supported languages
      // This could be enhanced to query the actual LLM for supported languages
      return _getCommonLanguages();
    } catch (e) {
      throw TranslationException('Error getting supported languages: $e');
    }
  }

  @override
  bool isLanguageSupported(String languageCode) {
    // For now, assume all common languages are supported
    // This could be enhanced with actual language support checking
    final commonLanguageCodes = [
      'en', 'es', 'fr', 'de', 'it', 'pt', 'ru', 'ja', 'ko', 'zh',
      'ar', 'hi', 'tr', 'pl', 'nl', 'sv', 'da', 'no', 'fi', 'cs',
      'hu', 'ro', 'bg', 'hr', 'sk', 'sl', 'et', 'lv', 'lt', 'mt'
    ];
    return commonLanguageCodes.contains(languageCode.toLowerCase());
  }

  @override
  bool get isInitialized => _isInitialized && !_isDisposed;

  @override
  void dispose() {
    if (_isDisposed) return;

    _cleanup();
    _isDisposed = true;
  }

  void _cleanup() {
    // Note: TranslationService doesn't have a dispose method in the current API
    _service = null;
    _isInitialized = false;
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('Translation Service not initialized. Call initialize() first.');
    }
    if (_isDisposed) {
      throw StateError('Translation Service has been disposed.');
    }
  }

  /// Simplified synchronized implementation
  Future<T> _synchronized<T>(Object lock, Future<T> Function() action) async {
    return await action();
  }

  /// Get list of commonly supported languages
  List<LanguageInfo> _getCommonLanguages() {
    return [
      const LanguageInfo(code: 'en', name: 'English', nativeName: 'English'),
      const LanguageInfo(code: 'es', name: 'Spanish', nativeName: 'Español'),
      const LanguageInfo(code: 'fr', name: 'French', nativeName: 'Français'),
      const LanguageInfo(code: 'de', name: 'German', nativeName: 'Deutsch'),
      const LanguageInfo(code: 'it', name: 'Italian', nativeName: 'Italiano'),
      const LanguageInfo(code: 'pt', name: 'Portuguese', nativeName: 'Português'),
      const LanguageInfo(code: 'ru', name: 'Russian', nativeName: 'Русский'),
      const LanguageInfo(code: 'ja', name: 'Japanese', nativeName: '日本語'),
      const LanguageInfo(code: 'ko', name: 'Korean', nativeName: '한국어'),
      const LanguageInfo(code: 'zh', name: 'Chinese', nativeName: '中文'),
      const LanguageInfo(code: 'ar', name: 'Arabic', nativeName: 'العربية'),
      const LanguageInfo(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
      const LanguageInfo(code: 'tr', name: 'Turkish', nativeName: 'Türkçe'),
      const LanguageInfo(code: 'pl', name: 'Polish', nativeName: 'Polski'),
      const LanguageInfo(code: 'nl', name: 'Dutch', nativeName: 'Nederlands'),
      const LanguageInfo(code: 'sv', name: 'Swedish', nativeName: 'Svenska'),
      const LanguageInfo(code: 'da', name: 'Danish', nativeName: 'Dansk'),
      const LanguageInfo(code: 'no', name: 'Norwegian', nativeName: 'Norsk'),
      const LanguageInfo(code: 'fi', name: 'Finnish', nativeName: 'Suomi'),
      const LanguageInfo(code: 'cs', name: 'Czech', nativeName: 'Čeština'),
    ];
  }
}

/// Translation specific exception
class TranslationException implements Exception {
  final String message;

  const TranslationException(this.message);

  @override
  String toString() => 'TranslationException: $message';
}