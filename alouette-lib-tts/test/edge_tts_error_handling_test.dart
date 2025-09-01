import 'package:test/test.dart';
import '../lib/src/models/tts_error.dart';
import '../lib/src/edge/edge_tts_voice_adapter.dart';

/// 测试 Edge TTS 错误处理的改进
/// 验证统一的 TTSError 错误类和错误代码的使用
void main() {
  group('Edge TTS Error Handling Tests', () {
    test('TTSError should have proper error categorization', () {
      // 测试初始化错误
      final initError = TTSError(
        'Initialization failed',
        code: TTSErrorCodes.initializationFailed,
      );
      expect(initError.isInitializationError, isTrue);
      expect(initError.isVoiceError, isFalse);
      expect(initError.isSynthesisError, isFalse);

      // 测试语音错误
      final voiceError = TTSError(
        'Voice not found',
        code: TTSErrorCodes.voiceNotFound,
      );
      expect(voiceError.isVoiceError, isTrue);
      expect(voiceError.isInitializationError, isFalse);
      expect(voiceError.isSynthesisError, isFalse);

      // 测试合成错误
      final synthesisError = TTSError(
        'Synthesis failed',
        code: TTSErrorCodes.synthesisFailed,
      );
      expect(synthesisError.isSynthesisError, isTrue);
      expect(synthesisError.isVoiceError, isFalse);
      expect(synthesisError.isPlaybackError, isFalse);
    });

    test('TTSError should provide proper error messages', () {
      final error = TTSError(
        'Test error message',
        code: TTSErrorCodes.synthesisError,
        originalError: 'Original error',
      );

      expect(error.message, equals('Test error message'));
      expect(error.code, equals(TTSErrorCodes.synthesisError));
      expect(error.originalError, equals('Original error'));
      expect(error.toString(), contains('TTSError: Test error message'));
      expect(error.toString(), contains('Code: SYNTHESIS_ERROR'));
    });

    test('EdgeTTSVoiceAdapter should throw TTSError for invalid input', () {
      final adapter = EdgeTTSVoiceAdapter();

      // 测试无效格式
      expect(
        () => adapter.parseVoice('invalid_format'),
        throwsA(isA<TTSError>().having(
          (e) => e.code,
          'error code',
          TTSErrorCodes.invalidVoiceFormat,
        )),
      );

      // 测试无效语音名称格式
      expect(
        () => adapter.parseVoice('invalid\tname'),
        throwsA(isA<TTSError>().having(
          (e) => e.code,
          'error code',
          TTSErrorCodes.invalidVoiceNameFormat,
        )),
      );
    });

    test('TTSError should support error type checking', () {
      final error = TTSError(
        'Test error',
        code: TTSErrorCodes.voiceListFailed,
      );

      expect(error.isErrorType(TTSErrorCodes.voiceListFailed), isTrue);
      expect(error.isErrorType(TTSErrorCodes.synthesisError), isFalse);
    });

    test('TTSErrorCodes should have all required constants', () {
      // 验证所有错误代码常量都存在
      expect(TTSErrorCodes.initializationFailed, isNotEmpty);
      expect(TTSErrorCodes.notInitialized, isNotEmpty);
      expect(TTSErrorCodes.voiceNotFound, isNotEmpty);
      expect(TTSErrorCodes.noVoiceSelected, isNotEmpty);
      expect(TTSErrorCodes.voiceListFailed, isNotEmpty);
      expect(TTSErrorCodes.synthesisError, isNotEmpty);
      expect(TTSErrorCodes.synthesisFailed, isNotEmpty);
      expect(TTSErrorCodes.playbackFailed, isNotEmpty);
      expect(TTSErrorCodes.noPlayerFound, isNotEmpty);
      expect(TTSErrorCodes.fileNotFound, isNotEmpty);
      expect(TTSErrorCodes.disposeFailed, isNotEmpty);
    });
  });
}