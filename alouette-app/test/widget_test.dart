// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_app/config/app_config.dart';

void main() {
  test('App configuration test', () async {
    // Test that services can be initialized
    await AppConfig.initializeServices();
    
    // Test that default config is created correctly
    final defaultConfig = AppConfig.defaultLLMConfig;
    expect(defaultConfig.provider, 'ollama');
    expect(defaultConfig.serverUrl, 'http://localhost:11434');
  });
}
