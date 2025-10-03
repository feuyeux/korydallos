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
    final String systemPrompt;
    
    if (config.selectedModel.contains('qwen')) {
      // For Qwen models, use explicit examples to prevent emoji responses
      final langSpec = getExplicitLanguageSpec(targetLanguage);
      systemPrompt = '''You are a professional translator. Your task is to translate text to $langSpec.

CRITICAL RULES:
1. Output ONLY the translated text in the target language
2. NO emojis, NO symbols, NO English explanations
3. Use proper words in the target language
4. If the input is a single word, translate it to a single word or short phrase
5. Never respond with emojis like 😊 or 👍

Examples:
Input: "great" → Output: "훌륭한" (Korean) or "素晴らしい" (Japanese) or "很好" (Chinese)
Input: "hello" → Output: "안녕하세요" (Korean) or "こんにちは" (Japanese) or "你好" (Chinese)

Now translate this text to $langSpec:''';
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
        'temperature': 0.3, // Slightly higher for better translations
        'num_predict': 200, // Allow longer outputs for proper translations
        'top_p': 0.5, // More diversity for natural translations
        'repeat_penalty': 1.1,
        'top_k': 40, // More options for word selection
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
