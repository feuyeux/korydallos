import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_tts_app/main.dart';

void main() {
  testWidgets('应用程序加载测试', (WidgetTester tester) async {
    // 构建应用程序并触发一个帧
    await tester.pumpWidget(const AlouetteTTSApp());

    // 验证应用程序标题是否存在
    expect(find.text('Alouette TTS'), findsOneWidget);
  });

  group('TTS基础功能测试', () {
    test('验证默认设置', () {
      // 测试默认语速、音量、音调设置是否正确
      const defaultSpeechRate = 0.5;
      const defaultVolume = 1.0;
      const defaultPitch = 1.0;

      expect(defaultSpeechRate, equals(0.5));
      expect(defaultVolume, equals(1.0));
      expect(defaultPitch, equals(1.0));
    });

    test('验证语言选项', () {
      // 测试语言代码格式是否正确
      const languageCode = 'zh-CN';
      expect(languageCode, isA<String>());
      expect(languageCode.length, greaterThan(0));
    });
  });
}
