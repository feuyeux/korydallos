import 'dart:convert';
import '../models/llm_config.dart';
import '../models/connection_status.dart';
import '../exceptions/translation_exceptions.dart';
import '../network/http_client_interface.dart';
import 'base_translation_provider.dart';
import 'dart:async';

/// Ollama translation provider implementation
class OllamaProvider extends TranslationProvider {
  final HttpClient _httpClient;

  OllamaProvider({HttpClient? httpClient})
    : _httpClient = httpClient ?? DefaultHttpClient();

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

    // Use a more specific system prompt for Qwen models
    String systemPrompt;
    if (config.selectedModel.contains('qwen')) {
      systemPrompt =
          '''You are a professional translator. Translate the given text directly to ${getExplicitLanguageSpec(targetLanguage)}.

IMPORTANT: You are a Qwen model. Qwen models should follow these special instructions:
- Provide ONLY the translation, no explanations, no thinking, no reasoning
- Do not output any internal thought process
- Do not explain your translation steps
- Do not use <thinking> tags or any similar tags
- Output ONLY the final translated text
- Do not output any text other than the translation

CRITICAL REQUIREMENTS:
- Maintain the original meaning and tone
- Use natural, fluent language
- Do not include phrases like "Translation:" or any prefixes
- NEVER output any thinking process or reasoning
- Output ONLY the final translated text with no additional content
- Respond with the translation directly''';
    } else {
      systemPrompt = getSystemPrompt(targetLanguage);
    }

    final apiUrl = '${config.normalizedServerUrl}/api/generate';

    final requestBody = {
      'model': config.selectedModel,
      'prompt': text,
      'system': systemPrompt,
      'stream': false,
      'options': {
        'temperature': 0.1, // Reduced for more deterministic output
        'num_predict': 100, // Reduced for shorter output
        'top_p': 0.1, // Reduced for more focused output
        'repeat_penalty': 1.05,
        'top_k': 10, // Reduced for more focused output
        'num_ctx': 2048,
        'repeat_last_n': 64,
        ...?additionalParams?['options'],
      },
    };

    try {
      final response = await _httpClient.post(
        apiUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
        timeout: const Duration(seconds: 60),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final rawTranslation = responseData['response'] as String?;

        if (rawTranslation == null || rawTranslation.trim().isEmpty) {
          throw TranslationException(
            'Empty translation response from Ollama. Response data: ${responseData.toString()}',
          );
        }

        // Enhanced cleaning to extract only the actual translation
        String cleanedTranslation = rawTranslation.trim();
        // Specific cleaning for Qwen models
        if (config.selectedModel.contains('qwen')) {
          List<String> lines = cleanedTranslation.split('\n');
          List<String> validLines = [];
          for (String line in lines) {
            String trimmedLine = line.trim();
            if (trimmedLine.isEmpty ||
                trimmedLine.toLowerCase().contains('let me') ||
                trimmedLine.toLowerCase().contains('first') ||
                trimmedLine.toLowerCase().contains('thinking') ||
                trimmedLine.toLowerCase().contains('translation') ||
                trimmedLine.toLowerCase().contains('user wants') ||
                trimmedLine.contains('<|') ||
                trimmedLine.startsWith('====') ||
                trimmedLine.contains('think>')) {
              continue;
            }
            validLines.add(trimmedLine);
          }
          // 优先选取最后一条有效行，否则返回原始内容
          if (validLines.isNotEmpty) {
            cleanedTranslation = validLines.last;
          } else {
            cleanedTranslation = rawTranslation.trim();
          }
        }

        // Remove special characters at the beginning and end
        cleanedTranslation = cleanedTranslation.replaceAll(
          RegExp(r'^[^A-Za-zÀ-ÿ0-9]*'),
          '',
        );
        cleanedTranslation = cleanedTranslation.replaceAll(
          RegExp(r'[^A-Za-zÀ-ÿ0-9.!?]*$'),
          '',
        );

        // Final trim
        cleanedTranslation = cleanedTranslation.trim();

        // If cleaning removed everything, return raw translation
        if (cleanedTranslation.isEmpty) {
          return rawTranslation.trim();
        }

        return cleanedTranslation;
      } else {
        throw TranslationException(
          'Ollama API request failed: HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      if (e is TranslationException) {
        rethrow;
      }
      throw TranslationException('Ollama translation failed: ${e.toString()}');
    }
  }

  @override
  Future<ConnectionStatus> testConnection(LLMConfig config) async {
    final startTime = DateTime.now();

    try {
      final apiUrl = '${config.normalizedServerUrl}/api/tags';
      final response = await _httpClient.get(
        apiUrl,
        timeout: const Duration(seconds: 10),
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

      if (e is TranslationException) {
        return ConnectionStatus.failure(
          message: 'Ollama connection test failed: ${e.toString()}',
          responseTimeMs: responseTime,
          details: {'error': e.toString()},
        );
      }

      return ConnectionStatus.failure(
        message: 'Ollama connection test failed: ${e.toString()}',
        responseTimeMs: responseTime,
        details: {'error': e.toString()},
      );
    }
  }

  @override
  Future<List<String>> getAvailableModels(LLMConfig config) async {
    try {
      final apiUrl = '${config.normalizedServerUrl}/api/tags';
      final response = await _httpClient.get(
        apiUrl,
        timeout: const Duration(seconds: 10),
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
        throw TranslationException(
          'Ollama API request failed: HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      if (e is TranslationException) {
        rethrow;
      }
      throw TranslationException('Ollama translation failed: ${e.toString()}');
    }

    return [];
  }
}
