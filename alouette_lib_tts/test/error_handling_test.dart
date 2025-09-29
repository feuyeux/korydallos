import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import 'mocks/mock_tts_processor.dart';
import 'mocks/mock_tts_engine_factory.dart';

void main() {
  group('TTS Error Handling Tests', () {
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

    test('should handle initialization failures', () async {
      // Arrange
      mockFactory.setShouldFail(true);

      // Act & Assert
      expect(
        () async => await service.initialize(),
        throwsA(isA<TTSError>()),
      );
      expect(service.isInitialized, isFalse);
    });

    test('should handle engine-specific initialization failures', () async {
      // Arrange
      mockFactory.setFailForEngine(TTSEngineType.edge);

      // Act & Assert
      expect(
        () async => await service.initialize(
          preferredEngine: TTSEngineType.edge,
          autoFallback: false,
        ),
        throwsA(isA<TTSError>()),
      );
    });

    test('should fallback to supported engine when preferred engine fails', () async {
      // Arrange
      mockFactory.setFailForEngine(TTSEngineType.edge);

      // Act
      await service.initialize(
        preferredEngine: TTSEngineType.edge,
        autoFallback: true,
      );

      // Assert
      expect(service.isInitialized, isTrue);
      expect(service.currentEngine, isNot(equals(TTSEngineType.edge)));
    });

    test('should handle unsupported engine gracefully', () async {
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

    test('should fallback when unsupported engine is requested', () async {
      // Arrange
      mockFactory.setUnsupportedEngine(TTSEngineType.edge);

      // Act
      await service.initialize(
        preferredEngine: TTSEngineType.edge,
        autoFallback: true,
      );

      // Assert
      expect(service.isInitialized, isTrue);
      expect(service.currentEngine, equals(TTSEngineType.flutter));
    });

    test('should handle voice retrieval failures', () async {
      // Arrange
      await service.initialize();
      mockProcessor.setShouldFailVoices(true);

      // Act & Assert
      expect(
        () async => await service.getVoices(),
        throwsA(isA<TTSError>()),
      );
    });

    test('should handle synthesis failures', () async {
      // Arrange
      await service.initialize();
      mockProcessor.setShouldFailSynthesis(true);

      // Act & Assert
      expect(
        () async => await service.synthesizeText('Hello world', 'voice1'),
        throwsA(isA<TTSError>()),
      );
    });

    test('should handle engine switching failures', () async {
      // Arrange
      await service.initialize(preferredEngine: TTSEngineType.flutter);
      mockFactory.setFailForEngine(TTSEngineType.edge);

      // Act & Assert
      expect(
        () async => await service.switchEngine(TTSEngineType.edge),
        throwsA(isA<TTSError>()),
      );
      
      // Should maintain original engine
      expect(service.currentEngine, equals(TTSEngineType.flutter));
    });

    test('should handle engine switching with fallback', () async {
      // Arrange
      await service.initialize(preferredEngine: TTSEngineType.flutter);
      mockFactory.setUnsupportedEngine(TTSEngineType.edge);

      // Act & Assert
      expect(
        () async => await service.switchEngine(
          TTSEngineType.edge,
          autoFallback: true,
        ),
        throwsA(isA<TTSError>()),
      );
    });

    test('should handle operations on uninitialized service', () async {
      // Act & Assert
      expect(
        () async => await service.getVoices(),
        throwsA(isA<TTSError>()),
      );

      expect(
        () async => await service.synthesizeText('Hello', 'voice1'),
        throwsA(isA<TTSError>()),
      );

      expect(
        () async => await service.stop(),
        throwsA(isA<TTSError>()),
      );

      expect(
        () async => await service.setSpeechRate(1.5),
        throwsA(isA<TTSError>()),
      );
    });

    test('should handle processor disposal errors gracefully', () {
      // Arrange
      service.initialize();
      
      // Simulate processor disposal error
      mockProcessor.reset();
      
      // Act & Assert - Should not throw
      expect(() => service.dispose(), returnsNormally);
      expect(service.isInitialized, isFalse);
    });

    test('should handle multiple disposal calls safely', () {
      // Arrange
      service.initialize();
      service.dispose();

      // Act & Assert - Should not throw
      expect(() => service.dispose(), returnsNormally);
    });

    test('should provide detailed error information', () async {
      // Arrange
      mockFactory.setShouldFail(true);

      // Act & Assert
      try {
        await service.initialize();
        fail('Expected exception to be thrown');
      } catch (e) {
        expect(e, isA<TTSError>());
        final ttsError = e as TTSError;
        expect(ttsError.message, contains('TTS service'));
        expect(ttsError.code, isNotNull);
      }
    });

    test('should handle platform-specific errors', () async {
      // Arrange
      mockFactory.setUnsupportedEngine(TTSEngineType.edge);

      // Act & Assert
      try {
        await service.initialize(
          preferredEngine: TTSEngineType.edge,
          autoFallback: false,
        );
        fail('Expected exception to be thrown');
      } catch (e) {
        expect(e, isA<TTSError>());
        final ttsError = e as TTSError;
        expect(ttsError.code, equals(TTSErrorCodes.platformNotSupported));
      }
    });

    test('should handle no fallback available scenario', () async {
      // Arrange - Make all engines unavailable
      mockFactory.setUnsupportedEngine(TTSEngineType.flutter);
      mockFactory.setUnsupportedEngine(TTSEngineType.edge);

      // Act & Assert
      expect(
        () async => await service.initialize(autoFallback: true),
        throwsA(isA<TTSError>()),
      );
    });

    test('should handle reinitialize with errors', () async {
      // Arrange
      await service.initialize(preferredEngine: TTSEngineType.flutter);
      expect(service.isInitialized, isTrue);

      // Make next initialization fail
      mockFactory.setShouldFail(true);

      // Act & Assert
      expect(
        () async => await service.reinitialize(preferredEngine: TTSEngineType.edge),
        throwsA(isA<TTSError>()),
      );
      
      // Service should be in uninitialized state after failed reinitialize
      expect(service.isInitialized, isFalse);
    });

    test('should handle concurrent initialization attempts', () async {
      // Act - Start multiple initialization attempts concurrently
      final futures = List.generate(5, (index) => service.initialize());

      // Assert - All should complete without error
      await Future.wait(futures);
      expect(service.isInitialized, isTrue);
    });

    test('should handle engine availability check errors', () async {
      // Arrange
      mockFactory.setShouldFail(true);

      // Act - Should not throw, just return false
      final isAvailable = await service.isEngineAvailable(TTSEngineType.edge);

      // Assert
      expect(isAvailable, isFalse);
    });

    test('should handle platform info retrieval errors', () async {
      // Arrange
      mockFactory.setShouldFail(true);

      // Act - Should still return some platform info
      final platformInfo = await service.getPlatformInfo();

      // Assert
      expect(platformInfo, isA<Map<String, dynamic>>());
      expect(platformInfo['isInitialized'], isFalse);
    });
  });

  group('TTS Error Recovery Tests', () {
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

    test('should recover from temporary synthesis failures', () async {
      // Arrange
      await service.initialize();
      
      // First synthesis fails
      mockProcessor.setShouldFailSynthesis(true);
      expect(
        () async => await service.synthesizeText('Hello', 'voice1'),
        throwsA(isA<TTSError>()),
      );

      // Recovery - synthesis now works
      mockProcessor.setShouldFailSynthesis(false);
      mockProcessor.setMockAudio([1, 2, 3, 4, 5]);

      // Act
      final audio = await service.synthesizeText('Hello', 'voice1');

      // Assert
      expect(audio, equals([1, 2, 3, 4, 5]));
    });

    test('should recover from engine switching failures', () async {
      // Arrange
      await service.initialize(preferredEngine: TTSEngineType.flutter);
      
      // First switch attempt fails
      mockFactory.setFailForEngine(TTSEngineType.edge);
      expect(
        () async => await service.switchEngine(TTSEngineType.edge),
        throwsA(isA<TTSError>()),
      );

      // Recovery - engine switching now works
      mockFactory.reset();
      mockFactory.setMockProcessor(mockProcessor);

      // Act
      await service.switchEngine(TTSEngineType.edge);

      // Assert
      expect(service.currentEngine, equals(TTSEngineType.edge));
    });

    test('should maintain service state after partial failures', () async {
      // Arrange
      await service.initialize();
      
      // Synthesis fails but service remains initialized
      mockProcessor.setShouldFailSynthesis(true);
      expect(
        () async => await service.synthesizeText('Hello', 'voice1'),
        throwsA(isA<TTSError>()),
      );

      // Assert - Service should still be initialized and functional
      expect(service.isInitialized, isTrue);
      expect(service.currentEngine, isNotNull);
      
      // Other operations should still work
      mockProcessor.setShouldFailSynthesis(false);
      await service.setSpeechRate(1.5);
      expect(mockProcessor.speechRate, equals(1.5));
    });

    test('should handle graceful degradation', () async {
      // Arrange
      await service.initialize(preferredEngine: TTSEngineType.edge);
      
      // Simulate engine becoming unavailable
      mockProcessor.setShouldFailSynthesis(true);
      
      // Act - Try to switch to fallback engine
      await service.switchEngine(TTSEngineType.flutter, autoFallback: true);

      // Assert
      expect(service.isInitialized, isTrue);
      expect(service.currentEngine, equals(TTSEngineType.flutter));
    });
  });
}