import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_app_tts/app/tts_app.dart';

void main() {
  testWidgets('TTS app loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const TTSApp());
    expect(find.text('Alouette TTS'), findsOneWidget);
  });
}
