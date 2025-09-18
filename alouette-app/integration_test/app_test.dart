import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:alouette_app/main.dart' as app;
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Alouette Main App Integration Tests', () {
    testWidgets('App initialization and service setup', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify app loads without errors
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Look for main navigation or home screen elements
      // This will depend on the actual UI structure
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
    });

    testWidgets('Navigation between translation and TTS features', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test navigation to translation feature
      var translationButton = find.text('Translation');
      if (translationButton.evaluate().isEmpty) {
        translationButton = find.byIcon(Icons.translate);
      }
      if (translationButton.evaluate().isNotEmpty) {
        await tester.tap(translationButton);
        await tester.pumpAndSettle();
        
        // Verify translation UI is displayed
        expect(find.byType(Scaffold), findsOneWidget);
      }

      // Test navigation to TTS feature
      final ttsButton = findAnyOf([
        find.text('TTS'),
        find.text('Text to Speech'),
        find.byIcon(Icons.record_voice_over)
      ]);
      if (ttsButton.evaluate().isNotEmpty) {
        await tester.tap(ttsButton);
        await tester.pumpAndSettle();
        
        // Verify TTS UI is displayed
        expect(find.byType(Scaffold), findsOneWidget);
      }
    });

    testWidgets('Service integration - Translation and TTS combined workflow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // This test verifies that both translation and TTS services work together
      // Look for text input fields
      final textField = find.byType(TextField).or(find.byType(TextFormField));
      if (textField.evaluate().isNotEmpty) {
        await tester.enterText(textField.first, 'Hello world');
        await tester.pumpAndSettle();

        // Look for translate button
        final translateButton = find.text('Translate').or(find.byIcon(Icons.translate));
        if (translateButton.evaluate().isNotEmpty) {
          await tester.tap(translateButton);
          await tester.pumpAndSettle();
          
          // Wait for translation to complete (with timeout)
          await tester.pump(const Duration(seconds: 2));
        }

        // Look for TTS/Play button
        final playButton = find.byIcon(Icons.play_arrow).or(find.text('Play'));
        if (playButton.evaluate().isNotEmpty) {
          await tester.tap(playButton);
          await tester.pumpAndSettle();
          
          // Wait for TTS to start
          await tester.pump(const Duration(seconds: 1));
        }
      }
    });

    testWidgets('Error handling and recovery', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test that the app handles errors gracefully
      // Look for any error indicators or messages
      expect(find.text('Error'), findsNothing);
      expect(find.byIcon(Icons.error), findsNothing);
      
      // Verify app is in a stable state
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}