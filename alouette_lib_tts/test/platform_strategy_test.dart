import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';

void main() {
  group('Platform-Specific TTS Engine Selection Tests', () {
    late PlatformDetector platformDetector;
    late TTSEngineFactory engineFactory;

    setUp(() {
      platformDetector = PlatformDetector();
      engineFactory = TTSEngineFactory.instance;
    });

    test('Platform detector should return valid strategy', () {
      final strategy = platformDetector.getTTSStrategy();
      
      expect(strategy, isNotNull);
      expect(strategy.preferredEngine, isA<TTSEngineType>());
      expect(strategy.getFallbackEngines(), isNotEmpty);
    });

    test('Strategy should provide platform-appropriate engines', () {
      final strategy = platformDetector.getTTSStrategy();
      final fallbackEngines = strategy.getFallbackEngines();
      
      // All fallback engines should be supported on current platform
      for (final engine in fallbackEngines) {
        expect(strategy.isEngineSupported(engine), isTrue,
            reason: 'Engine ${engine.name} should be supported by ${strategy.runtimeType}');
      }
    });

    test('Strategy should provide engine configuration', () {
      final strategy = platformDetector.getTTSStrategy();
      
      for (final engine in TTSEngineType.values) {
        final config = strategy.getEngineConfig(engine);
        expect(config, isA<Map<String, dynamic>>());
        
        if (strategy.isEngineSupported(engine)) {
          // Supported engines should have meaningful configuration
          expect(config, isNotEmpty, 
              reason: 'Supported engine ${engine.name} should have configuration');
        }
      }
    });

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

    test('Platform detector should return correct platform info', () {
      final platformInfo = platformDetector.getPlatformInfo();
      
      expect(platformInfo, containsPair('platform', isA<String>()));
      expect(platformInfo, containsPair('isDesktop', isA<bool>()));
      expect(platformInfo, containsPair('isMobile', isA<bool>()));
      expect(platformInfo, containsPair('isWeb', isA<bool>()));
      expect(platformInfo, containsPair('supportsProcessExecution', isA<bool>()));
      expect(platformInfo, containsPair('supportsFileSystem', isA<bool>()));
      expect(platformInfo, containsPair('isFlutterTTSSupported', isA<bool>()));
    });

    test('Platform detector should provide fallback engines', () {
      final fallbackEngines = platformDetector.getFallbackEngines();
      
      expect(fallbackEngines, isNotEmpty);
      expect(fallbackEngines, everyElement(isA<TTSEngineType>()));
    });
  });

  group('TTS Service Platform Integration Tests', () {
    late TTSService ttsService;

    setUp(() {
      ttsService = TTSService();
    });

    tearDown(() {
      ttsService.dispose();
    });

    test('TTS service should provide platform information', () async {
      final platformInfo = await ttsService.getPlatformInfo();
      
      expect(platformInfo, containsPair('strategy', isA<String>()));
      expect(platformInfo, containsPair('fallbackEngines', isA<List>()));
      expect(platformInfo, containsPair('supportedEngines', isA<List>()));
    });

    test('TTS service should provide recommended engine', () {
      final recommendedEngine = ttsService.getRecommendedEngine();
      expect(recommendedEngine, isA<TTSEngineType>());
    });

    test('TTS service should provide fallback engines', () {
      final fallbackEngines = ttsService.getFallbackEngines();
      expect(fallbackEngines, isNotEmpty);
      expect(fallbackEngines, everyElement(isA<TTSEngineType>()));
    });

    test('TTS service should provide engine configuration', () {
      for (final engine in TTSEngineType.values) {
        final config = ttsService.getEngineConfig(engine);
        expect(config, isA<Map<String, dynamic>>());
      }
    });
  });
}