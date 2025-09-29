import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

// Import all integration test files
import 'app_test.dart' as app_test;
import 'translation_workflow_test.dart' as translation_test;
import 'tts_workflow_test.dart' as tts_test;
import 'combined_workflow_test.dart' as combined_test;
import 'cross_platform_test.dart' as platform_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Alouette Main App - All Integration Tests', () {
    group('Basic App Tests', () {
      app_test.main();
    });

    group('Translation Workflow Tests', () {
      translation_test.main();
    });

    group('TTS Workflow Tests', () {
      tts_test.main();
    });

    group('Combined Workflow Tests', () {
      combined_test.main();
    });

    group('Cross-Platform Compatibility Tests', () {
      platform_test.main();
    });
  });
}