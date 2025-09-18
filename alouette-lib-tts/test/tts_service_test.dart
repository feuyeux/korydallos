import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import 'mocks/mock_tts_processor.dart';
import 'mocks/mock_tts_engine_factory.dart';

void main() {
  group('TTSService Tests', () {
    late TTSService service;
    late MockTTSEngineFactory mockFactory;
    late MockTTSProcessor mockProcessor;

    setUp(() {
      mockProcessor = MockTTSProcessor();
      mockFactory = MockTTSEngineFactory();
      mockFactory.setMockProcessor(mockProcessor);
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
      // At least Flutter TTS should be available
      expect(engines.isNotEmpty, true);
    });

    test('should check engine availability', () async {
      final flutterAvailable = await service.isEngineAvailable(TTSEngineType.flutter);
      expect(flutterAvailable, true); // Flutter TTS should always be available

      final edgeAvailable = await service.isEngineAvailable(TTSEngineType.edge);
      expect(edgeAvailable, isA<bool>()); // May or may not be available
    });

    test('should initialize with default engine', () async {
      // Act
      await service.initialize();

      // Assert
      expect(service.isInitialized, isTrue);
      expect(service.currentEngine, isNotNull);
      expect(service.currentEngineName, isNotNull);
    });

    test('should initialize with preferred engine', () async {
      // Act
      await service.initialize(preferredEngine: TTSEngineType.flutter);

      // Assert
      expect(service.isInitialized, isTrue);
      expect(service.currentEngine, equals(TTSEngineType.flutter));
    });

    test('should handle initialization failure gracefully', () async {
      // Arrange
      mockFactory.setShouldFail(true);

      // Act & Assert
      expect(
        () async => await service.initialize(),
        throwsA(isA<TTSError>()),
      );
      expect(service.isInitialized, isFalse);
    });

    test('should switch engines successfully', () async {
      // Arrange
      await service.initialize(preferredEngine: TTSEngineType.flutter);
      expect(service.currentEngine, equals(TTSEngineType.flutter));

      // Act
      await service.switchEngine(TTSEngineType.edge);

      // Assert
      expect(service.currentEngine, equals(TTSEngineType.edge));
    });

    test('should handle engine switch failure', () async {
      // Arrange
      await service.initialize(preferredEngine: TTSEngineType.flutter);
      mockFactory.setFailForEngine(TTSEngineType.edge);

      // Act & Assert
      expect(
        () async => await service.switchEngine(TTSEngineType.edge),
        throwsA(isA<TTSError>()),
      );
      // Should maintain original engine on failure
      expect(service.currentEngine, equals(TTSEngineType.flutter));
    });

    test('should get voices after initialization', () async {
      // Arrange
      await service.initialize();
      mockProcessor.setMockVoices([
        VoiceModel(
          id: 'voice1',
          displayName: 'Voice 1',
          languageCode: 'en-US',
          gender: VoiceGender.female,
          quality: VoiceQuality.neural,
          isNeural: true,
        ),
        VoiceModel(
          id: 'voice2',
          displayName: 'Voice 2',
          languageCode: 'es-ES',
          gender: VoiceGender.male,
          quality: VoiceQuality.standard,
          isNeural: false,
        ),
      ]);

      // Act
      final voices = await service.getVoices();

      // Assert
      expect(voices.length, equals(2));
      expect(voices[0].id, equals('voice1'));
      expect(voices[1].id, equals('voice2'));
    });

    test('should synthesize text successfully', () async {
      // Arrange
      await service.initialize();
      final mockAudio = [1, 2, 3, 4, 5];
      mockProcessor.setMockAudio(mockAudio);

      // Act
      final audio = await service.synthesizeText('Hello world', 'voice1');

      // Assert
      expect(audio, equals(mockAudio));
    });

    test('should handle synthesis errors', () async {
      // Arrange
      await service.initialize();
      mockProcessor.setShouldFailSynthesis(true);

      // Act & Assert
      expect(
        () async => await service.synthesizeText('Hello world', 'voice1'),
        throwsA(isA<TTSError>()),
      );
    });

    test('should stop TTS operation', () async {
      // Arrange
      await service.initialize();

      // Act
      await service.stop();

      // Assert
      expect(mockProcessor.stopCalled, isTrue);
    });

    test('should set speech parameters', () async {
      // Arrange
      await service.initialize();

      // Act
      await service.setSpeechRate(1.5);
      await service.setPitch(1.2);
      await service.setVolume(0.8);

      // Assert
      expect(mockProcessor.speechRate, equals(1.5));
      expect(mockProcessor.pitch, equals(1.2));
      expect(mockProcessor.volume, equals(0.8));
    });

    test('should provide comprehensive platform info after initialization', () async {
      // Arrange
      await service.initialize();

      // Act
      final info = await service.getPlatformInfo();

      // Assert
      expect(info['isInitialized'], isTrue);
      expect(info['currentEngine'], isNotNull);
      expect(info['currentEngineName'], isNotNull);
      expect(info.containsKey('strategy'), isTrue);
      expect(info.containsKey('fallbackEngines'), isTrue);
      expect(info.containsKey('supportedEngines'), isTrue);
    });

    test('should get recommended engine for platform', () {
      // Act
      final recommended = service.getRecommendedEngine();

      // Assert
      expect(recommended, isA<TTSEngineType>());
    });

    test('should get fallback engines for platform', () {
      // Act
      final fallbacks = service.getFallbackEngines();

      // Assert
      expect(fallbacks, isA<List<TTSEngineType>>());
      expect(fallbacks.isNotEmpty, isTrue);
    });

    test('should get engine configuration', () {
      // Act
      final config = service.getEngineConfig(TTSEngineType.flutter);

      // Assert
      expect(config, isA<Map<String, dynamic>>());
    });

    test('should reinitialize service', () async {
      // Arrange
      await service.initialize(preferredEngine: TTSEngineType.flutter);
      expect(service.currentEngine, equals(TTSEngineType.flutter));

      // Act
      await service.reinitialize(preferredEngine: TTSEngineType.edge);

      // Assert
      expect(service.currentEngine, equals(TTSEngineType.edge));
    });

    test('should handle auto-fallback on unsupported engine', () async {
      // Arrange
      mockFactory.setUnsupportedEngine(TTSEngineType.edge);

      // Act
      await service.initialize(
        preferredEngine: TTSEngineType.edge,
        autoFallback: true,
      );

      // Assert
      expect(service.isInitialized, isTrue);
      // Should fallback to supported engine
      expect(service.currentEngine, isNot(equals(TTSEngineType.edge)));
    });

    test('should throw error when auto-fallback is disabled', () async {
      // Arrange
      mockFactory.setUnsupportedEngine(TTSEngineType.edge);

      // Act & Assert
      expect(
        () async => await service.initialize(
          preferredEngine: TTSEngineType.edge,
          autoFallback: false,
        ),
        throwsA(isA<TTSError>()),
      );
    });

    test('should dispose resources properly', () {
      // Arrange
      service.initialize();

      // Act
      service.dispose();

      // Assert
      expect(service.isInitialized, isFalse);
      expect(service.currentEngine, isNull);
      expect(mockProcessor.disposeCalled, isTrue);
    });

    test('should handle multiple dispose calls safely', () {
      // Arrange
      service.initialize();
      service.dispose();

      // Act & Assert - Should not throw
      expect(() => service.dispose(), returnsNormally);
    });
  });

  group('TTSEngineFactory Tests', () {
    test('should get recommended engine type', () {
      final platformDetector = PlatformDetector();
      final recommended = platformDetector.getRecommendedEngine();
      expect(recommended, isA<TTSEngineType>());
    });

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
  });
}