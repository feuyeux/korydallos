import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';

void main() {
  group('TTSService Tests', () {
    late TTSService service;

    setUp(() {
      service = TTSService();
    });

    tearDown(() {
      service.dispose();
    });

    test('should not be initialized initially', () {
      expect(service.isInitialized, false);
      expect(service.currentEngine, null);
      expect(service.currentBackend, null);
    });

    test('should throw error when accessing methods before initialization', () async {
      expect(
        () async => await service.getVoices(),
        throwsA(isA<TTSError>()),
      );

      expect(
        () async => await service.synthesizeText('test', 'voice'),
        throwsA(isA<TTSError>()),
      );
    });

    test('should get platform info without initialization', () async {
      final info = await service.getPlatformInfo();
      expect(info, isA<Map<String, dynamic>>());
      expect(info.containsKey('platform'), true);
      expect(info.containsKey('isInitialized'), true);
      expect(info['isInitialized'], false);
    });

    test('should get available engines', () async {
      final engines = await service.getAvailableEngines();
      expect(engines, isA<List<TTSEngineType>>());
      // At least Flutter TTS should be available
      expect(engines.isNotEmpty, true);
    });

    test('should check engine availability', () async {
      final flutterAvailable = await service.isEngineAvailable(TTSEngineType.flutter);
      expect(flutterAvailable, true); // Flutter TTS should always be available

      final edgeAvailable = await service.isEngineAvailable(TTSEngineType.edge);
      expect(edgeAvailable, isA<bool>()); // May or may not be available
    });
  });

  group('PlatformTTSFactory Tests', () {
    test('should get recommended engine type', () {
      final recommended = PlatformTTSFactory.instance.recommendedEngineType;
      expect(recommended, isA<TTSEngineType>());
    });

    test('should get platform info', () async {
      final info = await PlatformTTSFactory.instance.getPlatformInfo();
      expect(info, isA<Map<String, dynamic>>());
      expect(info.containsKey('platform'), true);
      expect(info.containsKey('recommendedEngine'), true);
      expect(info.containsKey('availableEngines'), true);
    });

    test('should get available engines', () async {
      final engines = await PlatformTTSFactory.instance.getAvailableEngines();
      expect(engines, isA<List<TTSEngineType>>());
      expect(engines.isNotEmpty, true);
    });
  });
}