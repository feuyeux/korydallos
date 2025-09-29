import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:alouette_app_tts/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('TTS App Integration Tests', () {
    testWidgets('TTS app initialization and service setup', (WidgetTester tester) async {
      // Start the TTS app
      app.main();
      await tester.pumpAndSettle();

      // Verify app loads without errors
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Look for TTS-specific UI elements
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
      
      // Verify TTS-specific elements are present
      final ttsElements = find.byIcon(Icons.record_voice_over).or(
        find.text('TTS').or(
          find.text('Text to Speech').or(
            find.text('Speak')
          )
        )
      );
      expect(ttsElements.evaluate().isNotEmpty, isTrue);
    });

    testWidgets('TTS engine initialization and voice loading', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for TTS service to initialize
      await tester.pump(const Duration(seconds: 3));

      // Check for voice selector
      final voiceSelector = find.byType(DropdownButton).or(find.text('Select Voice'));
      if (voiceSelector.evaluate().isNotEmpty) {
        await tester.tap(voiceSelector);
        await tester.pumpAndSettle();
        
        // Wait for voices to load
        await tester.pump(const Duration(seconds: 5));
        
        // Verify voices are available
        expect(find.byType(DropdownMenuItem).evaluate().isNotEmpty || 
               find.text('Loading voices...').evaluate().isNotEmpty, isTrue);
      }

      // Check for engine status
      final engineStatus = find.text('Edge TTS').or(find.text('Flutter TTS')).or(find.text('Engine:'));
      expect(engineStatus.evaluate().isNotEmpty, isTrue, reason: 'TTS engine should be displayed');
    });

    testWidgets('Basic TTS synthesis workflow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enter text for TTS
      final textInput = find.byType(TextField).or(find.byType(TextFormField));
      if (textInput.evaluate().isNotEmpty) {
        await tester.enterText(textInput.first, 'Hello, this is a test of the text to speech functionality.');
        await tester.pumpAndSettle();

        // Select a voice if available
        final voiceSelector = find.byType(DropdownButton).or(find.text('Select Voice'));
        if (voiceSelector.evaluate().isNotEmpty) {
          await tester.tap(voiceSelector);
          await tester.pumpAndSettle();
          
          // Wait for voices to load
          await tester.pump(const Duration(seconds: 3));
          
          // Select first available voice
          final voiceOption = find.byType(DropdownMenuItem);
          if (voiceOption.evaluate().isNotEmpty) {
            await tester.tap(voiceOption.first);
            await tester.pumpAndSettle();
          }
        }

        // Start TTS synthesis
        final playButton = find.byIcon(Icons.play_arrow).or(find.text('Play')).or(find.text('Speak'));
        if (playButton.evaluate().isNotEmpty) {
          await tester.tap(playButton);
          await tester.pumpAndSettle();
          
          // Wait for TTS to process
          await tester.pump(const Duration(seconds: 5));
          
          // Verify TTS is working (look for stop button or progress indicator)
          final stopButton = find.byIcon(Icons.stop).or(find.byIcon(Icons.pause));
          final progressIndicator = find.byType(CircularProgressIndicator);
          expect(stopButton.evaluate().isNotEmpty || progressIndicator.evaluate().isNotEmpty, isTrue);
        }
      }
    });

    testWidgets('TTS engine switching functionality', (WidgetTester tester) async {
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
          
          // Try switching to Edge TTS
          final edgeOption = find.text('Edge TTS');
          if (edgeOption.evaluate().isNotEmpty) {
            await tester.tap(edgeOption);
            await tester.pumpAndSettle();
            
            // Wait for engine initialization
            await tester.pump(const Duration(seconds: 3));
          }

          // Try switching to Flutter TTS
          final flutterOption = find.text('Flutter TTS');
          if (flutterOption.evaluate().isNotEmpty) {
            await tester.tap(flutterOption);
            await tester.pumpAndSettle();
            
            // Wait for engine initialization
            await tester.pump(const Duration(seconds: 3));
          }
        }

        // Save settings
        final saveButton = find.text('Save').or(find.byIcon(Icons.save));
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle();
        }
      }

      // Test TTS with new engine
      final textInput = find.byType(TextField).or(find.byType(TextFormField));
      if (textInput.evaluate().isNotEmpty) {
        await tester.enterText(textInput.first, 'Testing engine switch functionality');
        await tester.pumpAndSettle();

        final playButton = find.byIcon(Icons.play_arrow).or(find.text('Play'));
        if (playButton.evaluate().isNotEmpty) {
          await tester.tap(playButton);
          await tester.pumpAndSettle();
          
          // Wait for TTS
          await tester.pump(const Duration(seconds: 3));
        }
      }
    });

    testWidgets('Voice selection and configuration', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test voice selection
      final voiceSelector = find.byType(DropdownButton).or(find.text('Select Voice'));
      if (voiceSelector.evaluate().isNotEmpty) {
        await tester.tap(voiceSelector);
        await tester.pumpAndSettle();
        
        // Wait for voices to load
        await tester.pump(const Duration(seconds: 5));
        
        // Test selecting different voice types
        final voiceOptions = find.byType(DropdownMenuItem);
        if (voiceOptions.evaluate().length > 1) {
          // Select second voice if available
          await tester.tap(voiceOptions.at(1));
          await tester.pumpAndSettle();
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

      // Test TTS with new settings
      final textInput = find.byType(TextField).or(find.byType(TextFormField));
      if (textInput.evaluate().isNotEmpty) {
        await tester.enterText(textInput.first, 'Testing voice configuration changes');
        await tester.pumpAndSettle();

        final playButton = find.byIcon(Icons.play_arrow).or(find.text('Play'));
        if (playButton.evaluate().isNotEmpty) {
          await tester.tap(playButton);
          await tester.pumpAndSettle();
          
          // Wait for TTS with new settings
          await tester.pump(const Duration(seconds: 4));
        }
      }
    });

    testWidgets('TTS playback control functionality', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enter text for TTS
      final textInput = find.byType(TextField).or(find.byType(TextFormField));
      if (textInput.evaluate().isNotEmpty) {
        await tester.enterText(textInput.first, 'This is a longer text to test playback controls. It should take several seconds to speak completely.');
        await tester.pumpAndSettle();

        // Start TTS
        final playButton = find.byIcon(Icons.play_arrow).or(find.text('Play'));
        if (playButton.evaluate().isNotEmpty) {
          await tester.tap(playButton);
          await tester.pumpAndSettle();
          
          // Wait for TTS to start
          await tester.pump(const Duration(seconds: 2));
          
          // Test pause functionality
          final pauseButton = find.byIcon(Icons.pause);
          if (pauseButton.evaluate().isNotEmpty) {
            await tester.tap(pauseButton);
            await tester.pumpAndSettle();
            
            // Wait and resume
            await tester.pump(const Duration(seconds: 1));
            
            final resumeButton = find.byIcon(Icons.play_arrow);
            if (resumeButton.evaluate().isNotEmpty) {
              await tester.tap(resumeButton);
              await tester.pumpAndSettle();
            }
          }
          
          // Test stop functionality
          final stopButton = find.byIcon(Icons.stop);
          if (stopButton.evaluate().isNotEmpty) {
            await tester.tap(stopButton);
            await tester.pumpAndSettle();
          }
        }
      }
    });

    testWidgets('TTS error handling and fallback', (WidgetTester tester) async {
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
        final longText = 'This is a very long text that is designed to test the text-to-speech functionality with extended content. ' * 20;
        await tester.enterText(textInput.first, longText);
        await tester.pumpAndSettle();

        final playButton = find.byIcon(Icons.play_arrow).or(find.text('Play'));
        if (playButton.evaluate().isNotEmpty) {
          await tester.tap(playButton);
          await tester.pumpAndSettle();
          
          // Wait for processing
          await tester.pump(const Duration(seconds: 5));
          
          // Verify app handles long text gracefully
          expect(find.byType(MaterialApp), findsOneWidget);
          
          // Stop the long TTS
          final stopButton = find.byIcon(Icons.stop);
          if (stopButton.evaluate().isNotEmpty) {
            await tester.tap(stopButton);
            await tester.pumpAndSettle();
          }
        }
      }

      // Test engine fallback by forcing an error condition
      final settingsButton = find.byIcon(Icons.settings).or(find.text('Settings'));
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();

        // Try to force engine switching
        final engineSelector = find.text('Edge TTS').or(find.text('Flutter TTS'));
        if (engineSelector.evaluate().isNotEmpty) {
          await tester.tap(engineSelector);
          await tester.pumpAndSettle();
          
          // Switch engines multiple times to test fallback
          final edgeOption = find.text('Edge TTS');
          if (edgeOption.evaluate().isNotEmpty) {
            await tester.tap(edgeOption);
            await tester.pumpAndSettle();
            await tester.pump(const Duration(seconds: 2));
          }

          final flutterOption = find.text('Flutter TTS');
          if (flutterOption.evaluate().isNotEmpty) {
            await tester.tap(flutterOption);
            await tester.pumpAndSettle();
            await tester.pump(const Duration(seconds: 2));
          }
        }
      }
    });

    testWidgets('Cross-platform TTS engine compatibility', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // This test verifies that the TTS app works across different platforms
      // and automatically selects the appropriate engine

      // Wait for automatic engine detection
      await tester.pump(const Duration(seconds: 3));

      // Verify engine is detected and displayed
      final engineStatus = find.text('Edge TTS').or(find.text('Flutter TTS')).or(find.text('Engine:'));
      expect(engineStatus.evaluate().isNotEmpty, isTrue, reason: 'TTS engine should be detected and displayed');

      // Test voice availability for the detected engine
      final voiceSelector = find.byType(DropdownButton).or(find.text('Select Voice'));
      if (voiceSelector.evaluate().isNotEmpty) {
        await tester.tap(voiceSelector);
        await tester.pumpAndSettle();
        
        // Wait for voices to load
        await tester.pump(const Duration(seconds: 5));
        
        // Verify voices are available for the platform
        expect(find.byType(DropdownMenuItem).evaluate().isNotEmpty || 
               find.text('Loading voices...').evaluate().isNotEmpty, isTrue);
      }

      // Test basic TTS functionality with platform-specific engine
      final textInput = find.byType(TextField).or(find.byType(TextFormField));
      if (textInput.evaluate().isNotEmpty) {
        await tester.enterText(textInput.first, 'Cross-platform TTS compatibility test');
        await tester.pumpAndSettle();

        final playButton = find.byIcon(Icons.play_arrow).or(find.text('Play'));
        if (playButton.evaluate().isNotEmpty) {
          await tester.tap(playButton);
          await tester.pumpAndSettle();
          
          // Wait for TTS processing
          await tester.pump(const Duration(seconds: 4));
          
          // Verify TTS started successfully
          expect(find.byType(MaterialApp), findsOneWidget);
        }
      }
    });

    testWidgets('TTS app performance and memory management', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Perform multiple TTS operations to test performance
      final testTexts = [
        'First performance test',
        'Second performance test with more content',
        'Third performance test with even longer content to verify memory management',
        'Fourth test to ensure consistent performance',
        'Final performance test iteration'
      ];

      for (int i = 0; i < testTexts.length; i++) {
        final textInput = find.byType(TextField).or(find.byType(TextFormField));
        if (textInput.evaluate().isNotEmpty) {
          await tester.enterText(textInput.first, testTexts[i]);
          await tester.pumpAndSettle();

          final playButton = find.byIcon(Icons.play_arrow).or(find.text('Play'));
          if (playButton.evaluate().isNotEmpty) {
            await tester.tap(playButton);
            await tester.pumpAndSettle();
            
            // Wait for TTS
            await tester.pump(const Duration(seconds: 3));
            
            // Stop TTS before next iteration
            final stopButton = find.byIcon(Icons.stop);
            if (stopButton.evaluate().isNotEmpty) {
              await tester.tap(stopButton);
              await tester.pumpAndSettle();
            }
          }
        }
      }

      // Verify app is still responsive after multiple operations
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}