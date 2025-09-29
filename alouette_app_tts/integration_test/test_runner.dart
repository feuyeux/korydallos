import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

// Import all integration test files
import 'tts_app_test.dart' as tts_app_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Alouette TTS App - All Integration Tests', () {
    group('TTS App Tests', () {
      tts_app_test.main();
    });
  });
}