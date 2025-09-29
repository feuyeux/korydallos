import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

// Import all integration test files
import 'translation_app_test.dart' as translation_app_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Alouette Translation App - All Integration Tests', () {
    group('Translation App Tests', () {
      translation_app_test.main();
    });
  });
}