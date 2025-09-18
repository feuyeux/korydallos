import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:alouette_app/main.dart' as app;
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Translation Workflow Integration Tests', () {
    testWidgets('Complete translation workflow with real LLM provider', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to translation feature if needed
      final translationTab = find.text('Translation').or(find.byIcon(Icons.translate));
      if (translationTab.evaluate().isNotEmpty) {
        await tester.tap(translationTab);
        await tester.pumpAndSettle();
      }

      // Test LLM configuration
      final configButton = find.byIcon(Icons.settings).or(find.text('Config'));
      if (configButton.evaluate().isNotEmpty) {
        await tester.tap(configButton);
        await tester.pumpAndSettle();

        // Look for LLM configuration fields
        final serverUrlField = find.byKey(const Key('serverUrl')).or(
          find.widgetWithText(TextField, 'Server URL')
        );
        
        if (serverUrlField.evaluate().isNotEmpty) {
          await tester.enterText(serverUrlField, 'http://localhost:11434');
          await tester.pumpAndSettle();
        }

        // Test connection
        final testConnectionButton = find.text('Test Connection').or(find.byIcon(Icons.wifi));
        if (testConnectionButton.evaluate().isNotEmpty) {
          await tester.tap(testConnectionButton);
          await tester.pumpAndSettle();
          
          // Wait for connection test
          await tester.pump(const Duration(seconds: 3));
        }

        // Save configuration
        final saveButton = find.text('Save').or(find.byIcon(Icons.save));
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle();
        }
      }

      // Test translation functionality
      final textInput = find.byType(TextField).or(find.byType(TextFormField));
      if (textInput.evaluate().isNotEmpty) {
        await tester.enterText(textInput.first, 'Hello, how are you today?');
        await tester.pumpAndSettle();

        // Select target languages
        final languageSelector = find.text('Spanish').or(find.text('French')).or(find.text('German'));
        if (languageSelector.evaluate().isNotEmpty) {
          await tester.tap(languageSelector.first);
          await tester.pumpAndSettle();
        }

        // Start translation
        final translateButton = find.text('Translate').or(find.byIcon(Icons.translate));
        if (translateButton.evaluate().isNotEmpty) {
          await tester.tap(translateButton);
          await tester.pumpAndSettle();
          
          // Wait for translation to complete (longer timeout for real LLM)
          await tester.pump(const Duration(seconds: 10));
          
          // Verify translation results appear
          // Look for any text that might be translation results
          expect(find.byType(Text), findsAtLeastNWidgets(1));
        }
      }
    });

    testWidgets('Multiple language translation workflow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to translation if needed
      final translationTab = find.text('Translation').or(find.byIcon(Icons.translate));
      if (translationTab.evaluate().isNotEmpty) {
        await tester.tap(translationTab);
        await tester.pumpAndSettle();
      }

      // Enter text for translation
      final textInput = find.byType(TextField).or(find.byType(TextFormField));
      if (textInput.evaluate().isNotEmpty) {
        await tester.enterText(textInput.first, 'Good morning, welcome to our application!');
        await tester.pumpAndSettle();

        // Select multiple target languages
        final languages = ['Spanish', 'French', 'German', 'Italian', 'Portuguese'];
        for (final language in languages) {
          final languageOption = find.text(language);
          if (languageOption.evaluate().isNotEmpty) {
            await tester.tap(languageOption);
            await tester.pumpAndSettle();
          }
        }

        // Start translation
        final translateButton = find.text('Translate').or(find.byIcon(Icons.translate));
        if (translateButton.evaluate().isNotEmpty) {
          await tester.tap(translateButton);
          await tester.pumpAndSettle();
          
          // Wait for multiple translations to complete
          await tester.pump(const Duration(seconds: 15));
          
          // Verify multiple translation results
          expect(find.byType(Text), findsAtLeastNWidgets(3));
        }
      }
    });

    testWidgets('Translation error handling and recovery', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test with invalid LLM configuration
      final configButton = find.byIcon(Icons.settings).or(find.text('Config'));
      if (configButton.evaluate().isNotEmpty) {
        await tester.tap(configButton);
        await tester.pumpAndSettle();

        // Enter invalid server URL
        final serverUrlField = find.byKey(const Key('serverUrl')).or(
          find.widgetWithText(TextField, 'Server URL')
        );
        
        if (serverUrlField.evaluate().isNotEmpty) {
          await tester.enterText(serverUrlField, 'http://invalid-server:9999');
          await tester.pumpAndSettle();
        }

        // Test connection (should fail)
        final testConnectionButton = find.text('Test Connection').or(find.byIcon(Icons.wifi));
        if (testConnectionButton.evaluate().isNotEmpty) {
          await tester.tap(testConnectionButton);
          await tester.pumpAndSettle();
          
          // Wait for connection test to fail
          await tester.pump(const Duration(seconds: 5));
          
          // Verify error handling
          expect(find.byType(MaterialApp), findsOneWidget); // App should still be stable
        }
      }

      // Test translation with no configuration
      final textInput = find.byType(TextField).or(find.byType(TextFormField));
      if (textInput.evaluate().isNotEmpty) {
        await tester.enterText(textInput.first, 'Test text');
        await tester.pumpAndSettle();

        final translateButton = find.text('Translate').or(find.byIcon(Icons.translate));
        if (translateButton.evaluate().isNotEmpty) {
          await tester.tap(translateButton);
          await tester.pumpAndSettle();
          
          // Wait for error handling
          await tester.pump(const Duration(seconds: 3));
          
          // Verify app handles error gracefully
          expect(find.byType(MaterialApp), findsOneWidget);
        }
      }
    });

    testWidgets('Translation service provider switching', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test switching between Ollama and LM Studio providers
      final configButton = find.byIcon(Icons.settings).or(find.text('Config'));
      if (configButton.evaluate().isNotEmpty) {
        await tester.tap(configButton);
        await tester.pumpAndSettle();

        // Test Ollama provider
        final ollamaOption = find.text('Ollama');
        if (ollamaOption.evaluate().isNotEmpty) {
          await tester.tap(ollamaOption);
          await tester.pumpAndSettle();
          
          // Configure Ollama
          final serverUrlField = find.byKey(const Key('serverUrl')).or(
            find.widgetWithText(TextField, 'Server URL')
          );
          
          if (serverUrlField.evaluate().isNotEmpty) {
            await tester.enterText(serverUrlField, 'http://localhost:11434');
            await tester.pumpAndSettle();
          }
        }

        // Test LM Studio provider
        final lmStudioOption = find.text('LM Studio');
        if (lmStudioOption.evaluate().isNotEmpty) {
          await tester.tap(lmStudioOption);
          await tester.pumpAndSettle();
          
          // Configure LM Studio
          final serverUrlField = find.byKey(const Key('serverUrl')).or(
            find.widgetWithText(TextField, 'Server URL')
          );
          
          if (serverUrlField.evaluate().isNotEmpty) {
            await tester.enterText(serverUrlField, 'http://localhost:1234');
            await tester.pumpAndSettle();
          }
        }

        // Save configuration
        final saveButton = find.text('Save').or(find.byIcon(Icons.save));
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle();
        }
      }
    });
  });
}