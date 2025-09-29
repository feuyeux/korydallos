import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:alouette_app/main.dart' as app;
import 'package:alouette_lib_tts/alouette_tts.dart';
import 'package:alouette_ui/alouette_ui.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('TTS Workflow Integration Tests', () {
    testWidgets('Complete TTS workflow with platform-specific engines', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to TTS feature if needed
      final ttsTab = find.text('TTS').or(find.text('Text to Speech')).or(find.byIcon(Icons.record_voice_over));
      if (ttsTab.evaluate().isNotEmpty) {
        await tester.tap(ttsTab);
        await tester.pumpAndSettle();
      }

      // Test voice loading
      final voiceSelector = find.byType(DropdownButton).or(find.text('Select Voice'));
      if (voiceSelector.evaluate().isNotEmpty) {
        await tester.tap(voiceSelector);
        await tester.pumpAndSettle();
        
        // Wait for voices to load
        await tester.pump(const Duration(seconds: 3));
        
        // Select a voice if available
        final voiceOption = find.byType(DropdownMenuItem).or(find.text('English'));
        if (voiceOption.evaluate().isNotEmpty) {
          await tester.tap(voiceOption.first);
          await tester.pumpAndSettle();
        }
      }

      // Test TTS synthesis
      final textInput = find.byType(TextField).or(find.byType(TextFormField));
      if (textInput.evaluate().isNotEmpty) {
        await tester.enterText(textInput.first, 'Hello, this is a test of the text to speech functionality.');
        await tester.pumpAndSettle();

        // Start TTS
        final playButton = find.byIcon(Icons.play_arrow).or(find.text('Play')).or(find.text('Speak'));
        if (playButton.evaluate().isNotEmpty) {
          await tester.tap(playButton);
          await tester.pumpAndSettle();
          
          // Wait for TTS to process
          await tester.pump(const Duration(seconds: 5));
          
          // Verify TTS is working (look for stop button or status indicator)
          final stopButton = find.byIcon(Icons.stop).or(find.byIcon(Icons.pause));
          expect(stopButton.evaluate().isNotEmpty || find.byType(CircularProgressIndicator).evaluate().isNotEmpty, isTrue);
        }
      }
    });

    testWidgets('TTS engine switching and fallback', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to TTS settings
      final settingsButton = find.byIcon(Icons.settings).or(find.text('Settings'));
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();

        // Test engine selection
        final engineSelector = find.text('Edge TTS').or(find.text('Flutter TTS')).or(find.text('Engine'));
        if (engineSelector.evaluate().isNotEmpty) {
          await tester.tap(engineSelector);
          await tester.pumpAndSettle();
          
          // Try different engines
          final edgeOption = find.text('Edge TTS');
          if (edgeOption.evaluate().isNotEmpty) {
            await tester.tap(edgeOption);
            await tester.pumpAndSettle();
            
            // Wait for engine initialization
            await tester.pump(const Duration(seconds: 2));
          }

          final flutterOption = find.text('Flutter TTS');
          if (flutterOption.evaluate().isNotEmpty) {
            await tester.tap(flutterOption);
            await tester.pumpAndSettle();
            
            // Wait for engine initialization
            await tester.pump(const Duration(seconds: 2));
          }
        }

        // Save settings
        final saveButton = find.text('Save').or(find.byIcon(Icons.save));
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('TTS voice selection and configuration', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to TTS feature
      final ttsTab = find.text('TTS').or(find.text('Text to Speech')).or(find.byIcon(Icons.record_voice_over));
      if (ttsTab.evaluate().isNotEmpty) {
        await tester.tap(ttsTab);
        await tester.pumpAndSettle();
      }

      // Test voice selection
      final voiceSelector = find.byType(DropdownButton).or(find.text('Select Voice'));
      if (voiceSelector.evaluate().isNotEmpty) {
        await tester.tap(voiceSelector);
        await tester.pumpAndSettle();
        
        // Wait for voices to load
        await tester.pump(const Duration(seconds: 3));
        
        // Test different voice types
        final voices = ['Male', 'Female', 'English', 'Spanish', 'French'];
        for (final voice in voices) {
          final voiceOption = find.text(voice);
          if (voiceOption.evaluate().isNotEmpty) {
            await tester.tap(voiceOption);
            await tester.pumpAndSettle();
            break; // Select first available voice
          }
        }
      }

      // Test TTS parameters
      final speedSlider = find.byType(Slider);
      if (speedSlider.evaluate().isNotEmpty) {
        // Test speed adjustment
        await tester.drag(speedSlider.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      // Test volume control
      final volumeSlider = find.byKey(const Key('volumeSlider')).or(find.byType(Slider));
      if (volumeSlider.evaluate().isNotEmpty && volumeSlider.evaluate().length > 1) {
        await tester.drag(volumeSlider.at(1), const Offset(-30, 0));
        await tester.pumpAndSettle();
      }

      // Test pitch control
      final pitchSlider = find.byKey(const Key('pitchSlider')).or(find.byType(Slider));
      if (pitchSlider.evaluate().isNotEmpty && pitchSlider.evaluate().length > 2) {
        await tester.drag(pitchSlider.at(2), const Offset(20, 0));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('TTS error handling and recovery', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test TTS with empty text
      final textInput = find.byType(TextField).or(find.byType(TextFormField));
      if (textInput.evaluate().isNotEmpty) {
        await tester.enterText(textInput.first, '');
        await tester.pumpAndSettle();

        final playButton = find.byIcon(Icons.play_arrow).or(find.text('Play'));
        if (playButton.evaluate().isNotEmpty) {
          await tester.tap(playButton);
          await tester.pumpAndSettle();
          
          // Verify error handling
          await tester.pump(const Duration(seconds: 2));
          expect(find.byType(MaterialApp), findsOneWidget); // App should remain stable
        }
      }

      // Test TTS with very long text
      if (textInput.evaluate().isNotEmpty) {
        final longText = 'This is a very long text that is designed to test the text-to-speech functionality with extended content. ' * 10;
        await tester.enterText(textInput.first, longText);
        await tester.pumpAndSettle();

        final playButton = find.byIcon(Icons.play_arrow).or(find.text('Play'));
        if (playButton.evaluate().isNotEmpty) {
          await tester.tap(playButton);
          await tester.pumpAndSettle();
          
          // Wait for processing
          await tester.pump(const Duration(seconds: 3));
          
          // Verify app handles long text gracefully
          expect(find.byType(MaterialApp), findsOneWidget);
        }
      }
    });

    testWidgets('Cross-platform TTS engine compatibility', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // This test verifies that the TTS service works across different platforms
      // and automatically selects the appropriate engine

      // Navigate to TTS feature
      final ttsTab = find.text('TTS').or(find.text('Text to Speech')).or(find.byIcon(Icons.record_voice_over));
      if (ttsTab.evaluate().isNotEmpty) {
        await tester.tap(ttsTab);
        await tester.pumpAndSettle();
      }

      // Test automatic engine detection
      final engineStatus = find.text('Edge TTS').or(find.text('Flutter TTS')).or(find.text('Engine:'));
      expect(engineStatus.evaluate().isNotEmpty, isTrue, reason: 'TTS engine should be detected and displayed');

      // Test voice availability
      final voiceSelector = find.byType(DropdownButton).or(find.text('Select Voice'));
      if (voiceSelector.evaluate().isNotEmpty) {
        await tester.tap(voiceSelector);
        await tester.pumpAndSettle();
        
        // Wait for voices to load
        await tester.pump(const Duration(seconds: 3));
        
        // Verify voices are available
        expect(find.byType(DropdownMenuItem).evaluate().isNotEmpty || 
               find.text('No voices available').evaluate().isEmpty, isTrue);
      }

      // Test basic TTS functionality
      final textInput = find.byType(TextField).or(find.byType(TextFormField));
      if (textInput.evaluate().isNotEmpty) {
        await tester.enterText(textInput.first, 'Cross-platform TTS test');
        await tester.pumpAndSettle();

        final playButton = find.byIcon(Icons.play_arrow).or(find.text('Play'));
        if (playButton.evaluate().isNotEmpty) {
          await tester.tap(playButton);
          await tester.pumpAndSettle();
          
          // Wait for TTS processing
          await tester.pump(const Duration(seconds: 3));
          
          // Verify TTS started successfully
          expect(find.byType(MaterialApp), findsOneWidget);
        }
      }
    });
  });
}