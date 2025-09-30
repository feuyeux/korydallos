/// Translation request model containing all necessary information for a translation operation
///
/// This is the standardized data model used across all Alouette applications
/// for translation requests. It includes comprehensive validation and serialization.
class TranslationRequest {
  /// The text to be translated
  final String text;

  /// List of target language codes (e.g., ['es', 'fr', 'de'])
  final List<String> targetLanguages;

  /// The LLM provider to use for translation
  final String provider;

  /// The server URL for the LLM provider
  final String serverUrl;

  /// The model name to use for translation
  final String modelName;

  /// Optional API key for authentication
  final String? apiKey;

  /// Additional request parameters specific to the provider
  final Map<String, dynamic>? additionalParams;

  /// Source language code (optional, auto-detected if not provided)
  final String? sourceLanguage;

  const TranslationRequest({
    required this.text,
    required this.targetLanguages,
    required this.provider,
    required this.serverUrl,
    required this.modelName,
    this.apiKey,
    this.additionalParams,
    this.sourceLanguage,
  });

  /// Convert to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'target_languages': targetLanguages,
      'provider': provider,
      'server_url': serverUrl,
      'model_name': modelName,
      'api_key': apiKey,
      'additional_params': additionalParams,
      'source_language': sourceLanguage,
    };
  }

  /// Create from JSON representation
  factory TranslationRequest.fromJson(Map<String, dynamic> json) {
    return TranslationRequest(
      text: json['text'] ?? '',
      targetLanguages: List<String>.from(json['target_languages'] ?? []),
      provider: json['provider'] ?? 'ollama',
      serverUrl: json['server_url'] ?? '',
      modelName: json['model_name'] ?? '',
      apiKey: json['api_key'],
      additionalParams: json['additional_params'] != null
          ? Map<String, dynamic>.from(json['additional_params'])
          : null,
      sourceLanguage: json['source_language'],
    );
  }

  /// Create a copy with modified fields
  TranslationRequest copyWith({
    String? text,
    List<String>? targetLanguages,
    String? provider,
    String? serverUrl,
    String? modelName,
    String? apiKey,
    Map<String, dynamic>? additionalParams,
    String? sourceLanguage,
  }) {
    return TranslationRequest(
      text: text ?? this.text,
      targetLanguages: targetLanguages ?? this.targetLanguages,
      provider: provider ?? this.provider,
      serverUrl: serverUrl ?? this.serverUrl,
      modelName: modelName ?? this.modelName,
      apiKey: apiKey ?? this.apiKey,
      additionalParams: additionalParams ?? this.additionalParams,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
    );
  }

  /// Validate the translation request
  ///
  /// Returns a map with validation results including errors and warnings
  Map<String, dynamic> validate() {
    final errors = <String>[];
    final warnings = <String>[];

    // Required field validation
    if (text.trim().isEmpty) {
      errors.add('Text to translate cannot be empty');
    }

    if (targetLanguages.isEmpty) {
      errors.add('At least one target language must be specified');
    }

    if (provider.trim().isEmpty) {
      errors.add('Provider is required');
    }

    if (serverUrl.trim().isEmpty) {
      errors.add('Server URL is required');
    }

    if (modelName.trim().isEmpty) {
      errors.add('Model name is required');
    }

    // URL format validation
    if (serverUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(serverUrl);
        if (!uri.hasScheme || !uri.hasAuthority) {
          errors.add('Invalid server URL format');
        }
      } catch (e) {
        errors.add('Invalid server URL format: $e');
      }
    }

    // Language code validation
    for (final lang in targetLanguages) {
      if (lang.trim().isEmpty) {
        errors.add('Target language codes cannot be empty');
        break;
      }
      if (!RegExp(r'^[a-z]{2}(-[A-Z]{2})?$').hasMatch(lang)) {
        warnings.add(
          'Language code "$lang" may not be in standard format (e.g., "en", "en-US")',
        );
      }
    }

    // Text length validation
    if (text.length > 10000) {
      warnings.add(
        'Text is very long (${text.length} characters). Consider splitting into smaller chunks.',
      );
    }

    // Duplicate language check
    final uniqueLanguages = targetLanguages.toSet();
    if (uniqueLanguages.length != targetLanguages.length) {
      warnings.add('Duplicate target languages detected');
    }

    return {'isValid': errors.isEmpty, 'errors': errors, 'warnings': warnings};
  }

  /// Check if the request is valid (no validation errors)
  bool get isValid => validate()['isValid'] as bool;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TranslationRequest &&
        other.text == text &&
        other.targetLanguages.length == targetLanguages.length &&
        other.targetLanguages.every((lang) => targetLanguages.contains(lang)) &&
        other.provider == provider &&
        other.serverUrl == serverUrl &&
        other.modelName == modelName &&
        other.apiKey == apiKey &&
        other.sourceLanguage == sourceLanguage;
  }

  @override
  int get hashCode {
    return Object.hash(
      text,
      Object.hashAll(targetLanguages),
      provider,
      serverUrl,
      modelName,
      apiKey,
      sourceLanguage,
    );
  }

  @override
  String toString() {
    return 'TranslationRequest(text: ${text.length > 50 ? '${text.substring(0, 50)}...' : text}, '
        'targetLanguages: $targetLanguages, provider: $provider, modelName: $modelName)';
  }
}
