import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_lib_trans/src/providers/ollama_provider.dart';
import 'package:alouette_lib_trans/src/models/llm_config.dart';

void main() {
  group('OllamaProvider', () {
    late OllamaProvider provider;
    late LLMConfig config;

    setUp(() {
      provider = OllamaProvider();
      config = const LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'qwen2.5:latest',
      );
    });

    group('translateText', () {
      test('should translate a sentence successfully', () async {
        // Note: This test requires a running Ollama server
        // Act
        final result = await provider.translateText(
          text: 'Hello, how are you today?',
          targetLanguage: 'es', // Spanish
          config: config,
        );
        
        // Log result
        print('Translation result: $result');
        print('====');
        // Assert
        expect(result, isNotNull);
        expect(result, isNotEmpty);
        // The translation should be different from the original text
        expect(result, 'Hola, ¿cómo estás hoy?');
      });
    });
  });
}