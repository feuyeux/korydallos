import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_app_trans/app/translation_app.dart';

void main() {
  testWidgets('Translation app loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const TranslationApp());
    expect(find.text('Alouette Translator'), findsOneWidget);
  });
}
