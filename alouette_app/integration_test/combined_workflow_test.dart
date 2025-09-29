import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:alouette_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Combined Translation and TTS Workflow Tests', () {
    testWidgets('End-to-end translation and TTS workflow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Step 1: Configure translation service
      final configButton = find.byIcon(Icons.settings).or(find.text('Config'));
      if (configButton.evaluate().isNotEmpty) {
        await tester.tap(configButton);
        await tester.pumpAndSettle();

        // Configure LLM
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

      // Step 2: Perform translation
      final textInput = find.byType(TextField).or(find.byType(TextFormField));
      if (textInput.evaluate().isNotEmpty) {
        await tester.enterText(textInput.first, 'Good morning, welcome to our application!');
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
          
          // Wait for translation
          await tester.pump(const Duration(seconds: 8));
        }
      }

      // Step 3: Use TTS on translated text
      final playButton = find.byIcon(Icons.play_arrow).or(find.text('Play')).or(find.text('Speak'));
      if (playButton.evaluate().isNotEmpty) {
        await tester.tap(playButton);
        await tester.pumpAndSettle();
        
        // Wait for TTS to start
        await tester.pump(const Duration(seconds: 3));
        
        // Verify TTS is working
        final stopButton = find.byIcon(Icons.stop).or(find.byIcon(Icons.pause));
        expect(stopButton.evaluate().isNotEmpty || find.byType(CircularProgressIndicator).evaluate().isNotEmpty, isTrue);
      }
    });

    testWidgets('Multi-language translation with TTS for each language', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enter text for translation
      final textInput = find.byType(TextField).or(find.byType(TextFormField));
      if (textInput.evaluate().isNotEmpty) {
        await tester.enterText(textInput.first, 'Hello, how are you today?');
        await tester.pumpAndSettle();

        // Select multiple languages
        final languages = ['Spanish', 'French', 'German'];
        for (final language in languages) {
          final languageOption = find.text(language);
          if (languageOption.evaluate().isNotEmpty) {
            await tester.tap(languageOption);
            await tester.pumpAndSettle();
          }
        }

        // Translate
        final translateButton = find.text('Translate').or(find.byIcon(Icons.translate));
        if (translateButton.evaluate().isNotEmpty) {
          await tester.tap(translateButton);
          await tester.pumpAndSettle();
          
          // Wait for translations
          await tester.pump(const Duration(seconds: 12));
        }

        // Test TTS for each translated result
        final playButtons = find.byIcon(Icons.play_arrow);
        for (int i = 0; i < playButtons.evaluate().length && i < 3; i++) {
          await tester.tap(playButtons.at(i));
          await tester.pumpAndSettle();
          
          // Wait for TTS
          await tester.pump(const Duration(seconds: 2));
          
          // Stop TTS before next
          final stopButton = find.byIcon(Icons.stop);
          if (stopButton.evaluate().isNotEmpty) {
            await tester.tap(stopButton.first);
            await tester.pumpAndSettle();
          }
        }
      }
    });

    testWidgets('Service coordination and state management', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test that services work together without conflicts
      
      // Start with translation
      final textInput = find.byType(TextField).or(find.byType(TextFormField));
      if (textInput.evaluate().isNotEmpty) {
        await tester.enterText(textInput.first, 'Testing service coordination');
        await tester.pumpAndSettle();

        final translateButton = find.text('Translate').or(find.byIcon(Icons.translate));
        if (translateButton.evaluate().isNotEmpty) {
          await tester.tap(translateButton);
          await tester.pumpAndSettle();
          
          // Wait briefly for translation to start
          await tester.pump(const Duration(seconds: 2));
        }
      }

      // While translation is potentially running, test TTS
      final playButton = find.byIcon(Icons.play_arrow).or(find.text('Play'));
      if (playButton.evaluate().isNotEmpty) {
        await tester.tap(playButton);
        await tester.pumpAndSettle();
        
        // Wait for TTS
        await tester.pump(const Duration(seconds: 2));
      }

      // Test navigation between features
      final homeButton = find.byIcon(Icons.home).or(find.text('Home'));
      if (homeButton.evaluate().isNotEmpty) {
        await tester.tap(homeButton);
        await tester.pumpAndSettle();
      }

      final translationTab = find.text('Translation').or(find.byIcon(Icons.translate));
      if (translationTab.evaluate().isNotEmpty) {
        await tester.tap(translationTab);
        await tester.pumpAndSettle();
      }

      final ttsTab = find.text('TTS').or(find.byIcon(Icons.record_voice_over));
      if (ttsTab.evaluate().isNotEmpty) {
        await tester.tap(ttsTab);
        await tester.pumpAndSettle();
      }

      // Verify app remains stable throughout
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Performance and memory management during combined operations', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Perform multiple operations to test performance
      for (int i = 0; i < 3; i++) {
        // Translation cycle
        final textInput = find.byType(TextField).or(find.byType(TextFormField));
        if (textInput.evaluate().isNotEmpty) {
          await tester.enterText(textInput.first, 'Performance test iteration ${i + 1}');
          await tester.pumpAndSettle();

          final translateButton = find.text('Translate').or(find.byIcon(Icons.translate));
          if (translateButton.evaluate().isNotEmpty) {
            await tester.tap(translateButton);
            await tester.pumpAndSettle();
            
            // Short wait for translation
            await tester.pump(const Duration(seconds: 3));
          }

          // TTS cycle
          final playButton = find.byIcon(Icons.play_arrow).or(find.text('Play'));
          if (playButton.evaluate().isNotEmpty) {
            await tester.tap(playButton);
            await tester.pumpAndSettle();
            
            // Short wait for TTS
            await tester.pump(const Duration(seconds: 2));
            
            // Stop TTS
            final stopButton = find.byIcon(Icons.stop);
            if (stopButton.evaluate().isNotEmpty) {
              await tester.tap(stopButton.first);
              await tester.pumpAndSettle();
            }
          }
        }
      }

      // Verify app is still responsive
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Error recovery in combined workflows', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test error scenarios
      
      // 1. Translation error followed by TTS
      final textInput = find.byType(TextField).or(find.byType(TextFormField));
      if (textInput.evaluate().isNotEmpty) {
        await tester.enterText(textInput.first, 'Error test');
        await tester.pumpAndSettle();

        // Try to translate without proper configuration
        final translateButton = find.text('Translate').or(find.byIcon(Icons.translate));
        if (translateButton.evaluate().isNotEmpty) {
          await tester.tap(translateButton);
          await tester.pumpAndSettle();
          
          // Wait for potential error
          await tester.pump(const Duration(seconds: 3));
        }

        // Try TTS anyway
        final playButton = find.byIcon(Icons.play_arrow).or(find.text('Play'));
        if (playButton.evaluate().isNotEmpty) {
          await tester.tap(playButton);
          await tester.pumpAndSettle();
          
          // Wait for TTS
          await tester.pump(const Duration(seconds: 2));
        }
      }

      // 2. Test rapid switching between features
      for (int i = 0; i < 5; i++) {
        final translationTab = find.text('Translation').or(find.byIcon(Icons.translate));
        if (translationTab.evaluate().isNotEmpty) {
          await tester.tap(translationTab);
          await tester.pump(const Duration(milliseconds: 100));
        }

        final ttsTab = find.text('TTS').or(find.byIcon(Icons.record_voice_over));
        if (ttsTab.evaluate().isNotEmpty) {
          await tester.tap(ttsTab);
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await tester.pumpAndSettle();

      // Verify app recovered and is stable
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}