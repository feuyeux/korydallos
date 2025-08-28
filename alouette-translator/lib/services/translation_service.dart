import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/translation_models.dart';

/// 翻译服务，处理文本翻译逻辑
class TranslationService {
  TranslationResult? _currentTranslation;
  bool _isTranslating = false;

  TranslationResult? get currentTranslation => _currentTranslation;
  bool get isTranslating => _isTranslating;

  /// 翻译文本到多个目标语言
  Future<TranslationResult> translateText(
    String inputText,
    List<String> targetLanguages,
    LLMConfig config,
  ) async {
    if (inputText.trim().isEmpty) {
      throw Exception('Please enter text to translate');
    }

    if (targetLanguages.isEmpty) {
      throw Exception('Please select at least one target language');
    }

    if (config.serverUrl.isEmpty || config.selectedModel.isEmpty) {
      throw Exception('Please configure LLM settings first');
    }

    _isTranslating = true;

    try {
      print('Starting translation request:');
      print('Text: $inputText');
      print('Target languages: $targetLanguages');
      print('Provider: ${config.provider}');
      print('Server URL: ${config.serverUrl}');
      print('Model: ${config.selectedModel}');

      final request = TranslationRequest(
        text: inputText.trim(),
        targetLanguages: targetLanguages,
        provider: config.provider,
        serverUrl: config.serverUrl,
        modelName: config.selectedModel,
        apiKey: config.apiKey,
      );

      final translations = <String, String>{};

      // 逐个语言进行翻译
      for (int i = 0; i < targetLanguages.length; i++) {
        final language = targetLanguages[i];
        print('Translating to $language (${i + 1}/${targetLanguages.length})...');

        String translation;
        switch (config.provider) {
          case 'ollama':
            translation = await _callOllamaTranslate(
              request.text,
              language,
              config.serverUrl,
              config.selectedModel,
            );
            break;
          case 'lmstudio':
            translation = await _callLMStudioTranslate(
              request.text,
              language,
              config.serverUrl,
              config.selectedModel,
              config.apiKey,
            );
            break;
          default:
            throw Exception('Unsupported provider: ${config.provider}');
        }

        translations[language] = translation;
        print('Successfully translated to $language: $translation');
      }

      _currentTranslation = TranslationResult(
        original: inputText.trim(),
        translations: translations,
        timestamp: DateTime.now(),
        languages: targetLanguages,
        config: config,
      );

      print('Translation completed successfully');
      return _currentTranslation!;
    } catch (error) {
      print('Translation failed: $error');

      // 提供更具体的错误信息
      final errorMsg = error.toString();
      if (errorMsg.contains('Connection refused') || errorMsg.contains('network')) {
        throw Exception(
            'Cannot connect to ${config.provider} server at ${config.serverUrl}. Please check if the server is running and accessible.');
      } else if (errorMsg.contains('Unauthorized') || errorMsg.contains('401')) {
        throw Exception('Authentication failed. Please check your API key.');
      } else if (errorMsg.contains('Not found') || errorMsg.contains('404')) {
        throw Exception(
            'Model "${config.selectedModel}" not found. Please check if the model is available.');
      } else if (errorMsg.contains('timeout')) {
        throw Exception('Translation request timed out. The server may be busy.');
      } else {
        throw Exception('Translation failed: $errorMsg');
      }
    } finally {
      _isTranslating = false;
    }
  }

  /// 调用 Ollama 进行翻译
  Future<String> _callOllamaTranslate(
    String text,
    String targetLang,
    String serverUrl,
    String modelName,
  ) async {
    print('Calling Ollama for translation to $targetLang');

    // 构建系统提示，使用明确的语言规范
    final systemPrompt = _getSystemPrompt(targetLang);
    final apiUrl = '${serverUrl.trimRight()}/api/generate';

    final requestBody = {
      'model': modelName,
      'prompt': text,
      'system': systemPrompt,
      'stream': false,
      'options': {
        'temperature': 0.1,
        'num_predict': 150,
        'top_p': 0.1,
        'repeat_penalty': 1.05,
        'top_k': 10,
        'stop': ['\n\n', 'Translation:', 'Explanation:', 'Note:', 'Original:', 'Source:'],
        'num_ctx': 2048,
        'repeat_last_n': 64,
      },
    };

    print('Sending request to: $apiUrl');

    final response = await http
        .post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestBody),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final rawTranslation = responseData['response'] as String?;

      if (rawTranslation == null || rawTranslation.trim().isEmpty) {
        throw Exception('Empty translation response');
      }

      // 清理翻译结果，移除可能的前缀、后缀和解释性文本
      final translation = _cleanTranslationResult(rawTranslation.trim(), targetLang);

      if (translation.trim().isEmpty) {
        throw Exception('Translation result is empty after cleaning');
      }

      return translation;
    } else {
      final errorText = response.body;
      throw Exception('HTTP ${response.statusCode}: $errorText');
    }
  }

  /// 调用 LM Studio 进行翻译
  Future<String> _callLMStudioTranslate(
    String text,
    String targetLang,
    String serverUrl,
    String modelName,
    String? apiKey,
  ) async {
    print('Calling LM Studio for translation to $targetLang');

    final systemPrompt = _getSystemPrompt(targetLang);
    final apiUrl = '${serverUrl.trimRight()}/v1/chat/completions';

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': text},
    ];

    final requestBody = {
      'model': modelName,
      'messages': messages,
      'temperature': 0.1,
      'max_tokens': 150,
      'stream': false,
    };

    final headers = {'Content-Type': 'application/json'};
    if (apiKey != null && apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    print('Sending request to LM Studio: $apiUrl');

    final response = await http
        .post(
          Uri.parse(apiUrl),
          headers: headers,
          body: json.encode(requestBody),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final choices = responseData['choices'] as List?;

      if (choices != null && choices.isNotEmpty) {
        final choice = choices.first;
        final message = choice['message'];
        final rawTranslation = message['content'] as String?;

        if (rawTranslation != null && rawTranslation.trim().isNotEmpty) {
          // 清理翻译结果
          final translation = _cleanTranslationResult(rawTranslation.trim(), targetLang);
          print('LM Studio translation result: $translation');
          return translation;
        }
      }

      throw Exception('No valid translation in response');
    } else {
      final errorText = response.body;
      throw Exception('HTTP ${response.statusCode}: $errorText');
    }
  }

  /// 获取系统提示模板
  String _getSystemPrompt(String targetLang) {
    final explicitLang = _getExplicitLanguageSpec(targetLang);
    return '''You are a professional translator. Translate the given text directly to $explicitLang. 
Requirements:
- Provide ONLY the translation, no explanations
- Maintain the original meaning and tone
- Use natural, fluent language
- Do not include phrases like "Translation:" or any prefixes''';
  }

  /// 获取明确的语言规范，避免相似语言之间的混淆
  String _getExplicitLanguageSpec(String targetLang) {
    switch (targetLang.toLowerCase()) {
      case 'chinese':
      case 'zh':
      case 'cn':
        return 'Simplified Chinese (中文)';
      case 'traditional chinese':
      case 'zh-tw':
        return 'Traditional Chinese (繁体中文)';
      case 'english':
      case 'en':
        return 'English';
      case 'japanese':
      case 'ja':
      case 'jp':
        return 'Japanese (日本語)';
      case 'korean':
      case 'ko':
      case 'kr':
        return 'Korean (한국어)';
      case 'french':
      case 'fr':
        return 'French (Français)';
      case 'german':
      case 'de':
        return 'German (Deutsch)';
      case 'spanish':
      case 'es':
        return 'Spanish (Español)';
      case 'italian':
      case 'it':
        return 'Italian (Italiano)';
      case 'russian':
      case 'ru':
        return 'Russian (Русский)';
      case 'arabic':
      case 'ar':
        return 'Arabic (العربية)';
      case 'hindi':
      case 'hi':
        return 'Hindi (हिन्दी)';
      case 'greek':
      case 'el':
        return 'Greek (Ελληνικά)';
      default:
        return targetLang;
    }
  }

  /// 清理翻译结果，移除不需要的前缀、后缀和解释性文本
  String _cleanTranslationResult(String rawText, String targetLang) {
    String cleaned = rawText;

    // 移除常见的前缀
    final prefixesToRemove = [
      'Translation:',
      'Translated text:',
      'Here is the translation:',
      'The translation is:',
      RegExp(r'^[Tt]ranslation.*?:'),
      RegExp(r'^[Hh]ere.*?:'),
      RegExp(r'^\d+\.\s*'),
    ];

    for (final prefix in prefixesToRemove) {
      if (prefix is String) {
        cleaned = cleaned.replaceFirst(RegExp('^$prefix\\s*', caseSensitive: false), '');
      } else if (prefix is RegExp) {
        cleaned = cleaned.replaceFirst(prefix, '');
      }
    }

    // 移除引号
    if (cleaned.startsWith('"')) cleaned = cleaned.substring(1);
    if (cleaned.startsWith("'")) cleaned = cleaned.substring(1);
    if (cleaned.endsWith('"')) cleaned = cleaned.substring(0, cleaned.length - 1);
    if (cleaned.endsWith("'")) cleaned = cleaned.substring(0, cleaned.length - 1);

    // 移除多余的空白
    cleaned = cleaned.trim();

    // 如果清理后的结果为空，返回原始文本的第一行
    if (cleaned.isEmpty) {
      cleaned = rawText.split('\n').first.trim();
    }

    return cleaned;
  }

  /// 获取当前翻译
  TranslationResult? getCurrentTranslation() {
    return _currentTranslation;
  }

  /// 清除当前翻译
  void clearTranslation() {
    _currentTranslation = null;
  }

  /// 获取翻译状态
  Map<String, dynamic> getTranslationState() {
    return {
      'isTranslating': _isTranslating,
      'hasTranslation': _currentTranslation != null,
      'currentTranslation': _currentTranslation,
    };
  }

  /// 格式化翻译结果用于显示
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
    };
  }
}
