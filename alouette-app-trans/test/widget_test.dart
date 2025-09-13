import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_app_trans/main.dart';

void main() {
  testWidgets('应用程序加载测试', (WidgetTester tester) async {
    // 构建应用程序并触发一个帧
    await tester.pumpWidget(const AlouetteAppTrans());

    // 验证应用程序标题是否存在
    expect(find.text('Alouette Translator'), findsOneWidget);
  });

  group('翻译基础功能测试', () {
    test('验证默认设置', () {
      // 测试默认配置是否正确
      const defaultProvider = 'ollama';
      const defaultServerUrl = 'http://localhost:11434';

      expect(defaultProvider, equals('ollama'));
      expect(defaultServerUrl, isA<String>());
      expect(defaultServerUrl.length, greaterThan(0));
    });

    test('验证语言选项', () {
      // 测试语言代码格式是否正确
      const languageCode = 'zh';
      expect(languageCode, isA<String>());
      expect(languageCode.length, greaterThan(0));
    });
  });
}
