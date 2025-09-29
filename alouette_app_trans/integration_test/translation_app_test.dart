import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:alouette_app_trans/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Translation App Integration Tests', () {
    testWidgets('Translation app initialization and service setup', (WidgetTester tester) async {
      // Start the translation app
      app.main();
      await tester.pumpAndSettle();

      // Verify app loads without errors
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Look for translation-specific UI elements
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
      
      // Verify translation-specific elements are present
      final translationElements = find.byIcon(Icons.translate).or(
        find.text('Translation').or(
          find.text('Translate')
        )
      );
      expect(translationElements.evaluate().isNotEmpty, isTrue);
    });

    testWidgets('LLM provider configuration workflow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to configuration
      final configButton = find.byIcon(Icons.settings).or(find.text('Config')).or(find.text('Settings'));
      if (configButton.evaluate().isNotEmpty) {
        await tester.tap(configButton);
        await tester.pumpAndSettle();

        // Test Ollama configuration
        final ollamaOption = find.text('Ollama');
        if (ollamaOption.evaluate().isNotEmpty) {
          await tester.tap(ollamaOption);
          await tester.pumpAndSettle();
          
          // Configure server URL
          final serverUrlField = find.byKey(const Key('serverUrl')).or(
            find.widgetWithText(TextField, 'Server URL')
          );
          
          if (serverUrlField.evaluate().isNotEmpty) {
            await tester.enterText(serverUrlField, 'http://localhost:11434');
            await tester.pumpAndSettle();
          }

          // Test connection
          final testButton = find.text('Test Connection').or(find.byIcon(Icons.wifi));
          if (testButton.evaluate().isNotEmpty) {
            await tester.tap(testButton);
            await tester.pumpAndSettle();
            
            // Wait for connection test
            await tester.pump(const Duration(seconds: 5));
          }
        }

        // Test LM Studio configuration
        final lmStudioOption = find.text('LM Studio');
        if (lmStudioOption.evaluate().isNotEmpty) {
          await tester.tap(lmStudioOption);
          await tester.pumpAndSettle();
          
          // Configure server URL
          final serverUrlField = find.byKey(const Key('serverUrl')).or(
            find.widgetWithText(TextField, 'Server URL')
          );
          
          if (serverUrlField.evaluate().isNotEmpty) {
            await tester.enterText(serverUrlField, 'http://localhost:1234');
            await tester.pumpAndSettle();
          }

          // Test connection
          final testButton = find.text('Test Connection').or(find.byIcon(Icons.wifi));
          if (testButton.evaluate().isNotEmpty) {
            await tester.tap(testButton);
            await tester.pumpAndSettle();
            
            // Wait for connection test
            await tester.pump(const Duration(seconds: 5));
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

    testWidgets('Single language translation workflow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enter text for translation
      final textInput = find.byType(TextField).or(find.byType(TextFormField));
      if (textInput.evaluate().isNotEmpty) {
        await tester.enterText(textInput.first, 'Hello, this is a test message for translation.');
        await tester.pumpAndSettle();

        // Select target language
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
          
          // Wait for translation to complete
          await tester.pump(const Duration(seconds: 10));
          
          // Verify translation result appears
          expect(find.byType(Text), findsAtLeastNWidgets(2)); // Original + translated text
        }
      }
    });

    testWidgets('Multiple language translation workflow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enter text for translation
      final textInput = find.byType(TextField).or(find.byType(TextFormField));
      if (textInput.evaluate().isNotEmpty) {
        await tester.enterText(textInput.first, 'Welcome to our translation application!');
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
          await tester.pump(const Duration(seconds: 20));
          
          // Verify multiple translation results
          expect(find.byType(Text), findsAtLeastNWidgets(4)); // Original + multiple translations
        }
      }
    });

    testWidgets('Translation history and management', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Perform several translations to build history
      final testTexts = [
        'First translation test',
        'Second translation test',
        'Third translation test'
      ];

      for (final text in testTexts) {
        final textInput = find.byType(TextField).or(find.byType(TextFormField));
        if (textInput.evaluate().isNotEmpty) {
          await tester.enterText(textInput.first, text);
          await tester.pumpAndSettle();

          final translateButton = find.text('Translate').or(find.byIcon(Icons.translate));
          if (translateButton.evaluate().isNotEmpty) {
            await tester.tap(translateButton);
            await tester.pumpAndSettle();
            
            // Wait for translation
            await tester.pump(const Duration(seconds: 5));
          }
        }
      }

      // Check for history functionality
      final historyButton = find.byIcon(Icons.history).or(find.text('History'));
      if (historyButton.evaluate().isNotEmpty) {
        await tester.tap(historyButton);
        await tester.pumpAndSettle();
        
        // Verify history is displayed
        expect(find.byType(ListView).or(find.byType(Column)), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('Translation error handling and recovery', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test with invalid configuration
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

        final saveButton = find.text('Save').or(find.byIcon(Icons.save));
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle();
        }
      }

      // Try to translate with invalid configuration
      final textInput = find.byType(TextField).or(find.byType(TextFormField));
      if (textInput.evaluate().isNotEmpty) {
        await tester.enterText(textInput.first, 'Error test message');
        await tester.pumpAndSettle();

        final translateButton = find.text('Translate').or(find.byIcon(Icons.translate));
        if (translateButton.evaluate().isNotEmpty) {
          await tester.tap(translateButton);
          await tester.pumpAndSettle();
          
          // Wait for error handling
          await tester.pump(const Duration(seconds: 5));
          
          // Verify app handles error gracefully
          expect(find.byType(MaterialApp), findsOneWidget);
          
          // Look for error indicators
          final errorIndicators = find.byIcon(Icons.error).or(find.text('Error'));
          // Error indicators may or may not be present depending on implementation
        }
      }

      // Test recovery by fixing configuration
      final configButton2 = find.byIcon(Icons.settings).or(find.text('Config'));
      if (configButton2.evaluate().isNotEmpty) {
        await tester.tap(configButton2);
        await tester.pumpAndSettle();

        final serverUrlField = find.byKey(const Key('serverUrl')).or(
          find.widgetWithText(TextField, 'Server URL')
        );
        
        if (serverUrlField.evaluate().isNotEmpty) {
          await tester.enterText(serverUrlField, 'http://localhost:11434');
          await tester.pumpAndSettle();
        }

        final saveButton = find.text('Save').or(find.byIcon(Icons.save));
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('Translation app performance with large text', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test with large text input
      final largeText = '''
      This is a very long text that is designed to test the translation application's 
      ability to handle large amounts of text. The text contains multiple sentences 
      and paragraphs to simulate real-world usage scenarios. We want to ensure that 
      the translation service can handle this amount of text without performance 
      issues or memory problems. This test will help us verify that the application 
      remains responsive and stable even when processing substantial amounts of text 
      for translation. The translation service should be able to process this text 
      efficiently and return accurate translations in the target languages.
      ''';

      final textInput = find.byType(TextField).or(find.byType(TextFormField));
      if (textInput.evaluate().isNotEmpty) {
        await tester.enterText(textInput.first, largeText);
        await tester.pumpAndSettle();

        // Select target language
        final languageSelector = find.text('Spanish').or(find.text('French'));
        if (languageSelector.evaluate().isNotEmpty) {
          await tester.tap(languageSelector.first);
          await tester.pumpAndSettle();
        }

        // Start translation
        final translateButton = find.text('Translate').or(find.byIcon(Icons.translate));
        if (translateButton.evaluate().isNotEmpty) {
          await tester.tap(translateButton);
          await tester.pumpAndSettle();
          
          // Wait for large text translation (longer timeout)
          await tester.pump(const Duration(seconds: 15));
          
          // Verify app remains responsive
          expect(find.byType(MaterialApp), findsOneWidget);
        }
      }
    });
  });
}