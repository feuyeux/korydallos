import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/llm_config.dart';
import '../models/connection_status.dart';
import '../exceptions/translation_exceptions.dart';
import '../utils/text_cleaner.dart';
import 'translation_provider.dart';

/// Ollama translation provider implementation
class OllamaProvider extends TranslationProvider {
  @override
  String get providerName => 'ollama';

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
    final apiUrl = '${config.serverUrl.trimRight()}/api/generate';

    final requestBody = {
      'model': config.selectedModel,
      'prompt': text,
      'system': systemPrompt,
      'stream': false,
      'options': {
        'temperature': 0.1,
        'num_predict': 150,
        'top_p': 0.1,
        'repeat_penalty': 1.05,
        'top_k': 10,
        'stop': [
          '\n\n',
          'Translation:',
          'Explanation:',
          'Note:',
          'Original:',
          'Source:',
        ],
        'num_ctx': 2048,
        'repeat_last_n': 64,
        ...?additionalParams?['options'],
      },
    };

    try {
      final response = await _postWithFallback(
        apiUrl,
        json.encode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final rawTranslation = responseData['response'] as String?;

        if (rawTranslation == null || rawTranslation.trim().isEmpty) {
          throw TranslationException('Empty translation response from Ollama');
        }

        final cleanedTranslation = TextCleaner.cleanTranslationResult(
          rawTranslation.trim(),
          targetLanguage,
        );

        if (cleanedTranslation.trim().isEmpty) {
          throw TranslationException(
            'Translation result is empty after cleaning',
          );
        }

        return cleanedTranslation;
      } else {
        final errorText = response.body;
        throw TranslationException(
          'Ollama API request failed: HTTP ${response.statusCode}: $errorText',
        );
      }
    } catch (e) {
      if (e is TranslationException) rethrow;

      if (e.toString().contains('Connection refused') ||
          e.toString().contains('network')) {
        throw LLMConnectionException(
          'Cannot connect to Ollama server at ${config.serverUrl}. Please check if the server is running and accessible.',
        );
      } else if (e.toString().contains('timeout')) {
        throw TranslationTimeoutException(
          'Translation request timed out. The server may be overloaded.',
        );
      } else {
        throw TranslationException(
          'Ollama translation failed: ${e.toString()}',
        );
      }
    }
  }

  @override
  Future<ConnectionStatus> testConnection(LLMConfig config) async {
    final startTime = DateTime.now();

    try {
      final apiUrl = '${config.serverUrl.trimRight()}/api/tags';

      final response = await _getWithFallback(
        apiUrl,
        const Duration(seconds: 10),
      );

      final responseTime = DateTime.now().difference(startTime).inMilliseconds;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = data['models'] as List?;
        final modelCount = models?.length ?? 0;

        return ConnectionStatus.success(
          message: 'Successfully connected to Ollama server',
          modelCount: modelCount,
          responseTimeMs: responseTime,
          details: {'models': models?.map((m) => m['name']).toList()},
        );
      } else {
        return ConnectionStatus.failure(
          message: 'Ollama server returned error: ${response.statusCode}',
          responseTimeMs: responseTime,
          details: {'statusCode': response.statusCode, 'body': response.body},
        );
      }
    } catch (e) {
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;

      if (e.toString().contains('Connection refused') ||
          e.toString().contains('network')) {
        return ConnectionStatus.failure(
          message: 'Cannot connect to Ollama server at ${config.serverUrl}',
          responseTimeMs: responseTime,
          details: {'error': e.toString()},
        );
      } else if (e.toString().contains('timeout')) {
        return ConnectionStatus.failure(
          message: 'Connection to Ollama server timed out',
          responseTimeMs: responseTime,
          details: {'error': e.toString()},
        );
      } else {
        return ConnectionStatus.failure(
          message: 'Ollama connection test failed: ${e.toString()}',
          responseTimeMs: responseTime,
          details: {'error': e.toString()},
        );
      }
    }
  }

  @override
  Future<List<String>> getAvailableModels(LLMConfig config) async {
    try {
      final apiUrl = '${config.serverUrl.trimRight()}/api/tags';

      final response = await _getWithFallback(
        apiUrl,
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = data['models'] as List?;

        if (models != null) {
          return models
              .map((model) => model['name'] as String? ?? '')
              .where((name) => name.isNotEmpty)
              .toList();
        }
      } else {
        throw LLMConnectionException(
          'Failed to fetch models: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is LLMConnectionException) rethrow;
      throw LLMConnectionException(
        'Failed to get available models: ${e.toString()}',
      );
    }

    return [];
  }

  // Helper: GET with fallback to 127.0.0.1 if localhost fails with operation not permitted
  Future<http.Response> _getWithFallback(String url, Duration timeout) async {
    try {
      return await http.get(Uri.parse(url)).timeout(timeout);
    } catch (e) {
      // If it's a SocketException with 'Operation not permitted', try 127.0.0.1
      if (e is SocketException &&
          e.osError?.message.contains('Operation not permitted') == true) {
        final fallback = url.replaceFirst(
          RegExp(r'localhost', caseSensitive: false),
          '127.0.0.1',
        );
        return await http.get(Uri.parse(fallback)).timeout(timeout);
      }
      rethrow;
    }
  }

  // Helper: POST with fallback to 127.0.0.1 if localhost fails with operation not permitted
  Future<http.Response> _postWithFallback(
    String url,
    String body, {
    Map<String, String>? headers,
  }) async {
    try {
      return await http
          .post(Uri.parse(url), headers: headers, body: body)
          .timeout(const Duration(seconds: 60));
    } catch (e) {
      if (e is SocketException &&
          e.osError?.message.contains('Operation not permitted') == true) {
        final fallback = url.replaceFirst(
          RegExp(r'localhost', caseSensitive: false),
          '127.0.0.1',
        );
        return await http
            .post(Uri.parse(fallback), headers: headers, body: body)
            .timeout(const Duration(seconds: 60));
      }
      rethrow;
    }
  }
}
