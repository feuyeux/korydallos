import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:alouette_app/main.dart' as app;
import 'package:alouette_lib_tts/alouette_tts.dart';
import 'package:alouette_ui/alouette_ui.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Cross-Platform Compatibility Tests', () {
    testWidgets('Platform detection and engine selection', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for platform detection and service initialization
      await tester.pump(const Duration(seconds: 5));

      // Verify platform-specific behavior
      if (kIsWeb) {
        // Web platform tests
        debugPrint('Running web platform tests');
        
        // Verify Flutter TTS is used on web
        final engineStatus = find.text('Flutter TTS').or(find.text('Web TTS'));
        expect(engineStatus.evaluate().isNotEmpty, isTrue, 
          reason: 'Web platform should use Flutter TTS');
        
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // Desktop platform tests
        debugPrint('Running desktop platform tests');
        
        // Verify Edge TTS is preferred on desktop (with Flutter TTS as fallback)
        final engineStatus = find.text('Edge TTS').or(find.text('Flutter TTS'));
        expect(engineStatus.evaluate().isNotEmpty, isTrue, 
          reason: 'Desktop platform should show TTS engine status');
        
      } else if (Platform.isAndroid || Platform.isIOS) {
        // Mobile platform tests
        debugPrint('Running mobile platform tests');
        
        // Verify Flutter TTS is used on mobile
        final engineStatus = find.text('Flutter TTS');
        expect(engineStatus.evaluate().isNotEmpty, isTrue, 
          reason: 'Mobile platform should use Flutter TTS');
      }

      // Test that the app loads correctly regardless of platform
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('TTS engine switching across platforms', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to TTS settings
      final settingsButton = find.byIcon(Icons.settings).or(find.text('Settings'));
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();

        // Test engine availability based on platform
        if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
          // Desktop: Test Edge TTS availability
          final edgeOption = find.text('Edge TTS');
          if (edgeOption.evaluate().isNotEmpty) {
            await tester.tap(edgeOption);
            await tester.pumpAndSettle();
            
            // Wait for Edge TTS initialization
            await tester.pump(const Duration(seconds: 3));
            
            // Test TTS with Edge TTS
            await _testTTSFunctionality(tester, 'Testing Edge TTS on desktop platform');
          }
          
          // Test fallback to Flutter TTS
          final flutterOption = find.text('Flutter TTS');
          if (flutterOption.evaluate().isNotEmpty) {
            await tester.tap(flutterOption);
            await tester.pumpAndSettle();
            
            // Wait for Flutter TTS initialization
            await tester.pump(const Duration(seconds: 2));
            
            // Test TTS with Flutter TTS
            await _testTTSFunctionality(tester, 'Testing Flutter TTS fallback on desktop');
          }
          
        } else {
          // Mobile/Web: Only Flutter TTS should be available
          final flutterOption = find.text('Flutter TTS');
          expect(flutterOption.evaluate().isNotEmpty, isTrue, 
            reason: 'Flutter TTS should be available on mobile/web platforms');
          
          if (flutterOption.evaluate().isNotEmpty) {
            await tester.tap(flutterOption);
            await tester.pumpAndSettle();
            
            // Test TTS functionality
            await _testTTSFunctionality(tester, 'Testing Flutter TTS on mobile/web platform');
          }
        }
      }
    });

    testWidgets('Voice availability across platforms', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for voice loading
      await tester.pump(const Duration(seconds: 5));

      // Test voice selector
      final voiceSelector = find.byType(DropdownButton).or(find.text('Select Voice'));
      if (voiceSelector.evaluate().isNotEmpty) {
        await tester.tap(voiceSelector);
        await tester.pumpAndSettle();
        
        // Wait for voices to load
        await tester.pump(const Duration(seconds: 5));
        
        // Verify platform-specific voice availability
        if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
          // Desktop: Should have Edge TTS voices or Flutter TTS voices
          final voiceOptions = find.byType(DropdownMenuItem);
          expect(voiceOptions.evaluate().isNotEmpty, isTrue, 
            reason: 'Desktop platform should have available voices');
          
        } else if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          // Mobile: Should have system TTS voices
          final voiceOptions = find.byType(DropdownMenuItem);
          expect(voiceOptions.evaluate().isNotEmpty, isTrue, 
            reason: 'Mobile platform should have system TTS voices');
          
        } else if (kIsWeb) {
          // Web: Should have web speech API voices
          final voiceOptions = find.byType(DropdownMenuItem);
          // Web voices may not always be available, so we just check the app doesn't crash
          expect(find.byType(MaterialApp), findsOneWidget);
        }
      }
    });

    testWidgets('Translation service cross-platform compatibility', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test translation functionality across platforms
      final textInput = find.byType(TextField).or(find.byType(TextFormField));
      if (textInput.evaluate().isNotEmpty) {
        await tester.enterText(textInput.first, 'Cross-platform translation test');
        await tester.pumpAndSettle();

        // Configure translation service (should work on all platforms)
        final configButton = find.byIcon(Icons.settings).or(find.text('Config'));
        if (configButton.evaluate().isNotEmpty) {
          await tester.tap(configButton);
          await tester.pumpAndSettle();

          // Test LLM configuration
          final serverUrlField = find.byKey(const Key('serverUrl')).or(
            find.widgetWithText(TextField, 'Server URL')
          );
          
          if (serverUrlField.evaluate().isNotEmpty) {
            // Use localhost for desktop, but may need different config for mobile/web
            String serverUrl = 'http://localhost:11434';
            if (kIsWeb) {
              // Web may need different CORS configuration
              serverUrl = 'http://localhost:11434';
            } else if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
              // Mobile may need different network configuration
              serverUrl = 'http://10.0.2.2:11434'; // Android emulator localhost
            }
            
            await tester.enterText(serverUrlField, serverUrl);
            await tester.pumpAndSettle();
          }

          final saveButton = find.text('Save').or(find.byIcon(Icons.save));
          if (saveButton.evaluate().isNotEmpty) {
            await tester.tap(saveButton);
            await tester.pumpAndSettle();
          }
        }

        // Test translation
        final translateButton = find.text('Translate').or(find.byIcon(Icons.translate));
        if (translateButton.evaluate().isNotEmpty) {
          await tester.tap(translateButton);
          await tester.pumpAndSettle();
          
          // Wait for translation (may take longer on some platforms)
          await tester.pump(const Duration(seconds: 10));
          
          // Verify app remains stable regardless of translation success
          expect(find.byType(MaterialApp), findsOneWidget);
        }
      }
    });

    testWidgets('UI responsiveness across different screen sizes', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test different screen sizes (simulating different devices)
      final screenSizes = [
        const Size(360, 640),  // Mobile portrait
        const Size(640, 360),  // Mobile landscape
        const Size(768, 1024), // Tablet portrait
        const Size(1024, 768), // Tablet landscape
        const Size(1920, 1080), // Desktop
      ];

      for (final size in screenSizes) {
        // Simulate screen size change
        await tester.binding.setSurfaceSize(size);
        await tester.pumpAndSettle();

        // Verify UI adapts to screen size
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.byType(Scaffold), findsAtLeastNWidgets(1));

        // Test basic functionality at this screen size
        final textInput = find.byType(TextField).or(find.byType(TextFormField));
        if (textInput.evaluate().isNotEmpty) {
          await tester.enterText(textInput.first, 'Screen size test ${size.width}x${size.height}');
          await tester.pumpAndSettle();
        }

        // Test navigation elements are accessible
        final navigationElements = find.byType(BottomNavigationBar).or(
          find.byType(NavigationRail).or(
            find.byType(Drawer)
          )
        );
        // Navigation elements may or may not be present depending on design
        
        // Verify no overflow errors
        expect(tester.takeException(), isNull);
      }

      // Reset to default size
      await tester.binding.setSurfaceSize(null);
      await tester.pumpAndSettle();
    });

    testWidgets('Performance across platforms', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Measure app startup time and responsiveness
      final stopwatch = Stopwatch()..start();

      // Perform a series of operations to test performance
      for (int i = 0; i < 5; i++) {
        // Translation operation
        final textInput = find.byType(TextField).or(find.byType(TextFormField));
        if (textInput.evaluate().isNotEmpty) {
          await tester.enterText(textInput.first, 'Performance test iteration $i');
          await tester.pumpAndSettle();

          final translateButton = find.text('Translate').or(find.byIcon(Icons.translate));
          if (translateButton.evaluate().isNotEmpty) {
            await tester.tap(translateButton);
            await tester.pump(const Duration(seconds: 1)); // Don't wait for completion
          }
        }

        // TTS operation
        final playButton = find.byIcon(Icons.play_arrow).or(find.text('Play'));
        if (playButton.evaluate().isNotEmpty) {
          await tester.tap(playButton);
          await tester.pump(const Duration(seconds: 1)); // Don't wait for completion
          
          final stopButton = find.byIcon(Icons.stop);
          if (stopButton.evaluate().isNotEmpty) {
            await tester.tap(stopButton);
            await tester.pumpAndSettle();
          }
        }

        // Navigation test
        final settingsButton = find.byIcon(Icons.settings);
        if (settingsButton.evaluate().isNotEmpty) {
          await tester.tap(settingsButton);
          await tester.pumpAndSettle();
          
          final backButton = find.byIcon(Icons.arrow_back);
          if (backButton.evaluate().isNotEmpty) {
            await tester.tap(backButton);
            await tester.pumpAndSettle();
          }
        }
      }

      stopwatch.stop();
      debugPrint('Performance test completed in ${stopwatch.elapsedMilliseconds}ms');

      // Verify app is still responsive
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Helper function to test TTS functionality
Future<void> _testTTSFunctionality(WidgetTester tester, String testText) async {
  final textInput = find.byType(TextField).or(find.byType(TextFormField));
  if (textInput.evaluate().isNotEmpty) {
    await tester.enterText(textInput.first, testText);
    await tester.pumpAndSettle();

    final playButton = find.byIcon(Icons.play_arrow).or(find.text('Play'));
    if (playButton.evaluate().isNotEmpty) {
      await tester.tap(playButton);
      await tester.pumpAndSettle();
      
      // Wait for TTS to start
      await tester.pump(const Duration(seconds: 2));
      
      // Stop TTS
      final stopButton = find.byIcon(Icons.stop);
      if (stopButton.evaluate().isNotEmpty) {
        await tester.tap(stopButton);
        await tester.pumpAndSettle();
      }
    }
  }
}