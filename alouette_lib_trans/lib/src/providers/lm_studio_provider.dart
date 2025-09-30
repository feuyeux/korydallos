import 'dart:convert';
import '../models/llm_config.dart';
import '../models/connection_status.dart';
import '../exceptions/translation_exceptions.dart';
import '../network/http_client_interface.dart';
import 'base_translation_provider.dart';
import 'dart:async';

/// LM Studio translation provider implementation
class LMStudioProvider extends TranslationProvider {
  final HttpClient _httpClient;

  LMStudioProvider({HttpClient? httpClient})
    : _httpClient = httpClient ?? DefaultHttpClient();

  @override
  String get providerName => 'lmstudio';

  @override
  Future<String> translateText({
    required String text,
    required String targetLanguage,
    required LLMConfig config,
    Map<String, dynamic>? additionalParams,
  }) async {
    if (!supportsConfig(config)) {
      throw TranslationException('Unsupported provider: ${config.provider}');
    }

    final systemPrompt = getSystemPrompt(targetLanguage);
    final apiUrl = '${config.normalizedServerUrl}/v1/chat/completions';

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': text},
    ];

    final requestBody = {
      'model': config.selectedModel,
      'messages': messages,
      'temperature': 0.1,
      'max_tokens': 150,
      'stream': false,
      ...?additionalParams,
    };

    final headers = {'Content-Type': 'application/json'};
    if (config.apiKey != null && config.apiKey!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${config.apiKey}';
    }

    try {
      final response = await _httpClient.post(
        apiUrl,
        headers: headers,
        body: json.encode(requestBody),
        timeout: const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final choices = responseData['choices'] as List?;

        if (choices != null && choices.isNotEmpty) {
          final choice = choices.first;
          final message = choice['message'];
          final rawTranslation = message['content'] as String?;

          if (rawTranslation != null && rawTranslation.trim().isNotEmpty) {
            // Enhanced cleaning similar to Ollama provider
            String cleanedTranslation = _cleanTranslationResult(
              rawTranslation,
              targetLanguage,
            );

            if (cleanedTranslation.trim().isEmpty) {
              throw InvalidTranslationException(
                'Translation result is empty after cleaning',
                text,
                targetLanguage,
              );
            }

            return cleanedTranslation;
          }
        }

        throw TranslationException(
          'No valid translation in LM Studio response',
        );
      } else {
        throw TranslationException(
          'LM Studio API request failed: HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      if (e is TranslationException) {
        rethrow;
      }
      throw TranslationException(
        'LM Studio translation failed: ${e.toString()}',
      );
    }
  }

  @override
  Future<ConnectionStatus> testConnection(LLMConfig config) async {
    final startTime = DateTime.now();

    try {
      final apiUrl = '${config.normalizedServerUrl}/v1/models';

      final headers = {'Content-Type': 'application/json'};
      if (config.apiKey != null && config.apiKey!.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${config.apiKey}';
      }

      final response = await _httpClient.get(
        apiUrl,
        headers: headers,
        timeout: const Duration(seconds: 10),
      );

      final responseTime = DateTime.now().difference(startTime).inMilliseconds;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = data['data'] as List?;
        final modelCount = models?.length ?? 0;

        return ConnectionStatus.success(
          message: 'Successfully connected to LM Studio server',
          modelCount: modelCount,
          responseTimeMs: responseTime,
          details: {'models': models?.map((m) => m['id']).toList()},
        );
      } else {
        return ConnectionStatus.failure(
          message: 'LM Studio server returned error: ${response.statusCode}',
          responseTimeMs: responseTime,
          details: {'statusCode': response.statusCode, 'body': response.body},
        );
      }
    } catch (e) {
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;

      if (e is TranslationException) {
        return ConnectionStatus.failure(
          message: 'LM Studio connection test failed: ${e.toString()}',
          responseTimeMs: responseTime,
          details: {'error': e.toString()},
        );
      }

      return ConnectionStatus.failure(
        message: 'LM Studio connection test failed: ${e.toString()}',
        responseTimeMs: responseTime,
        details: {'error': e.toString()},
      );
    }
  }

  @override
  Future<List<String>> getAvailableModels(LLMConfig config) async {
    try {
      final apiUrl = '${config.normalizedServerUrl}/v1/models';

      final headers = {'Content-Type': 'application/json'};
      if (config.apiKey != null && config.apiKey!.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${config.apiKey}';
      }

      final response = await _httpClient.get(
        apiUrl,
        headers: headers,
        timeout: const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = data['data'] as List?;

        if (models != null) {
          return models
              .map((model) => model['id'] as String? ?? '')
              .where((id) => id.isNotEmpty)
              .toList();
        }
      } else {
        throw TranslationException(
          'LM Studio API request failed: HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      if (e is TranslationException) {
        rethrow;
      }
      throw TranslationException(
        'LM Studio translation failed: ${e.toString()}',
      );
    }

    return [];
  }

  /// Clean translation result by removing unwanted prefixes, suffixes, and formatting
  String _cleanTranslationResult(String rawText, String targetLanguage) {
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
    ];

    String result = text;
    for (final pattern in prefixPatterns) {
      result = result.replaceFirst(pattern, '');
    }

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
    final lines = rawText.split('\n').map((line) => line.trim()).toList();

    // Return first non-empty line
    for (final line in lines) {
      if (line.isNotEmpty) {
        return line;
      }
    }

    return rawText.trim();
  }
}
