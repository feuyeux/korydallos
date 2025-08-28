import 'package:alouette_lib_trans/alouette_lib_trans.dart';

Future<void> main() async {
  final provider = OllamaProvider();
  final config = LLMConfig(provider: 'ollama', serverUrl: 'http://localhost:11434', selectedModel: '');
  final status = await provider.testConnection(config);
  print('Success: \\${status.success}, message: \\${status.message}');
}
