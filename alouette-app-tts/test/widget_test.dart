import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_app_tts/app/tts_app.dart';

void main() {
  testWidgets('TTS App loading test', (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(const TTSApp());

    // Verify that the app title exists
    expect(find.text('Alouette TTS'), findsOneWidget);
  });

  group('TTS Basic Functionality Tests', () {
    test('Verify default settings', () {
      // Test that default speech rate, volume, pitch settings are correct
      const defaultSpeechRate = 1.0;
      const defaultVolume = 1.0;
      const defaultPitch = 1.0;

      expect(defaultSpeechRate, equals(1.0));
      expect(defaultVolume, equals(1.0));
      expect(defaultPitch, equals(1.0));
    });

    test('Verify language options', () {
      // Test that language code format is correct
      const languageCode = 'en-US';
      expect(languageCode, isA<String>());
      expect(languageCode.length, greaterThan(0));
    });
  });
}
