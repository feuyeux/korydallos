import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';

void main() {
  group('Basic TTS Service Unit Tests', () {
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
      expect(service.currentEngineName, null);
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
      expect(engines.isNotEmpty, true);
    });

    test('should check engine availability', () async {
      final flutterAvailable = await service.isEngineAvailable(TTSEngineType.flutter);
      expect(flutterAvailable, true);

      final edgeAvailable = await service.isEngineAvailable(TTSEngineType.edge);
      expect(edgeAvailable, isA<bool>());
    });

    test('should get recommended engine for platform', () {
      final recommended = service.getRecommendedEngine();
      expect(recommended, isA<TTSEngineType>());
    });

    test('should get fallback engines for platform', () {
      final fallbacks = service.getFallbackEngines();
      expect(fallbacks, isA<List<TTSEngineType>>());
      expect(fallbacks.isNotEmpty, isTrue);
    });

    test('should get engine configuration', () {
      final config = service.getEngineConfig(TTSEngineType.flutter);
      expect(config, isA<Map<String, dynamic>>());
    });

    test('should handle multiple dispose calls safely', () {
      service.dispose();
      expect(() => service.dispose(), returnsNormally);
    });
  });

  group('Platform Detector Unit Tests', () {
    late PlatformDetector platformDetector;

    setUp(() {
      platformDetector = PlatformDetector();
    });

    test('should return valid platform info', () {
      final info = platformDetector.getPlatformInfo();
      
      expect(info, containsPair('platform', isA<String>()));
      expect(info, containsPair('isDesktop', isA<bool>()));
      expect(info, containsPair('isMobile', isA<bool>()));
      expect(info, containsPair('isWeb', isA<bool>()));
      expect(info, containsPair('supportsProcessExecution', isA<bool>()));
      expect(info, containsPair('supportsFileSystem', isA<bool>()));
      expect(info, containsPair('isFlutterTTSSupported', isA<bool>()));
    });

    test('should return valid strategy', () {
      final strategy = platformDetector.getTTSStrategy();
      
      expect(strategy, isNotNull);
      expect(strategy.preferredEngine, isA<TTSEngineType>());
      expect(strategy.getFallbackEngines(), isNotEmpty);
    });

    test('should provide fallback engines', () {
      final fallbackEngines = platformDetector.getFallbackEngines();
      
      expect(fallbackEngines, isNotEmpty);
      expect(fallbackEngines, everyElement(isA<TTSEngineType>()));
    });

    test('should get recommended engine', () {
      final recommended = platformDetector.getRecommendedEngine();
      expect(recommended, isA<TTSEngineType>());
    });
  });

  group('TTS Engine Factory Unit Tests', () {
    test('should get platform info', () async {
      final info = await TTSEngineFactory.instance.getPlatformInfo();
      expect(info, isA<Map<String, dynamic>>());
      expect(info.containsKey('platform'), true);
      expect(info.containsKey('recommendedEngine'), true);
      expect(info.containsKey('availableEngines'), true);
    });

    test('should get available engines', () async {
      final engines = await TTSEngineFactory.instance.getAvailableEngines();
      expect(engines, isA<List<TTSEngineType>>());
      expect(engines.isNotEmpty, true);
    });

    test('should check engine availability', () async {
      final flutterAvailable = await TTSEngineFactory.instance.isEngineAvailable(TTSEngineType.flutter);
      expect(flutterAvailable, true);
    });
  });

  group('TTS Strategy Unit Tests', () {
    test('Desktop strategy should prefer Edge TTS', () {
      final desktopStrategy = DesktopTTSStrategy();
      
      expect(desktopStrategy.preferredEngine, equals(TTSEngineType.edge));
      expect(desktopStrategy.isEngineSupported(TTSEngineType.edge), isTrue);
      expect(desktopStrategy.isEngineSupported(TTSEngineType.flutter), isTrue);
      
      final fallbackEngines = desktopStrategy.getFallbackEngines();
      expect(fallbackEngines.first, equals(TTSEngineType.edge));
    });

    test('Mobile strategy should use Flutter TTS only', () {
      final mobileStrategy = MobileTTSStrategy();
      
      expect(mobileStrategy.preferredEngine, equals(TTSEngineType.flutter));
      expect(mobileStrategy.isEngineSupported(TTSEngineType.flutter), isTrue);
      expect(mobileStrategy.isEngineSupported(TTSEngineType.edge), isFalse);
      
      final fallbackEngines = mobileStrategy.getFallbackEngines();
      expect(fallbackEngines, equals([TTSEngineType.flutter]));
    });

    test('Web strategy should use Flutter TTS only', () {
      final webStrategy = WebTTSStrategy();
      
      expect(webStrategy.preferredEngine, equals(TTSEngineType.flutter));
      expect(webStrategy.isEngineSupported(TTSEngineType.flutter), isTrue);
      expect(webStrategy.isEngineSupported(TTSEngineType.edge), isFalse);
      
      final fallbackEngines = webStrategy.getFallbackEngines();
      expect(fallbackEngines, equals([TTSEngineType.flutter]));
    });

    test('Strategy should provide platform-appropriate engines', () {
      final platformDetector = PlatformDetector();
      final strategy = platformDetector.getTTSStrategy();
      final fallbackEngines = strategy.getFallbackEngines();
      
      for (final engine in fallbackEngines) {
        expect(strategy.isEngineSupported(engine), isTrue,
            reason: 'Engine ${engine.name} should be supported by ${strategy.runtimeType}');
      }
    });

    test('Strategy should provide engine configuration', () {
      final platformDetector = PlatformDetector();
      final strategy = platformDetector.getTTSStrategy();
      
      for (final engine in TTSEngineType.values) {
        final config = strategy.getEngineConfig(engine);
        expect(config, isA<Map<String, dynamic>>());
        
        if (strategy.isEngineSupported(engine)) {
          expect(config, isNotEmpty, 
              reason: 'Supported engine ${engine.name} should have configuration');
        }
      }
    });
  });

  group('Voice Model Unit Tests', () {
    test('should create voice model with all properties', () {
      final voice = VoiceModel(
        id: 'test-voice',
        displayName: 'Test Voice',
        languageCode: 'en-US',
        gender: VoiceGender.female,
        quality: VoiceQuality.neural,
        isNeural: true,
      );

      expect(voice.id, equals('test-voice'));
      expect(voice.displayName, equals('Test Voice'));
      expect(voice.languageCode, equals('en-US'));
      expect(voice.gender, equals(VoiceGender.female));
      expect(voice.quality, equals(VoiceQuality.neural));
      expect(voice.isNeural, isTrue);
    });

    test('should serialize and deserialize voice model', () {
      final originalVoice = VoiceModel(
        id: 'test-voice',
        displayName: 'Test Voice',
        languageCode: 'en-US',
        gender: VoiceGender.male,
        quality: VoiceQuality.standard,
        isNeural: false,
      );

      final json = originalVoice.toJson();
      final deserializedVoice = VoiceModel.fromJson(json);

      expect(deserializedVoice.id, equals(originalVoice.id));
      expect(deserializedVoice.displayName, equals(originalVoice.displayName));
      expect(deserializedVoice.languageCode, equals(originalVoice.languageCode));
      expect(deserializedVoice.gender, equals(originalVoice.gender));
      expect(deserializedVoice.quality, equals(originalVoice.quality));
      expect(deserializedVoice.isNeural, equals(originalVoice.isNeural));
    });
  });
}