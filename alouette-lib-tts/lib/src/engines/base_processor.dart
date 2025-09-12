import 'dart:typed_data';
import '../models/voice.dart';
import '../models/tts_error.dart';
import '../utils/cache_manager.dart';
import '../utils/error_handler.dart';
import '../utils/tts_logger.dart';

/// 统一的 TTS 处理器接口
/// 参照 hello-tts-dart 的 TTSProcessor 设计模式
abstract class BaseTTSProcessor {
  /// 获取后端名称
  String get backend;

  /// 获取所有可用的语音列表
  Future<List<Voice>> getVoices();

  /// 文本转语音合成
  /// 
  /// [text] 要合成的文本
  /// [voiceName] 语音名称
  /// [format] 音频格式，默认为 'mp3'
  /// 
  /// 返回音频数据的字节数组
  Future<Uint8List> synthesizeText(
    String text, 
    String voiceName, {
    String format = 'mp3'
  });

  /// 停止当前的TTS播放
  /// 
  /// 尝试停止当前正在进行的语音合成或播放
  /// 不是所有的TTS引擎都支持停止功能
  Future<void> stop();
  
  /// 设置语速
  /// 
  /// [rate] 语速值，通常在0.1到3.0之间
  Future<void> setSpeechRate(double rate);
  
  /// 设置音调
  /// 
  /// [pitch] 音调值，通常在0.5到2.0之间
  Future<void> setPitch(double pitch);
  
  /// 设置音量
  /// 
  /// [volume] 音量值，通常在0.0到1.0之间
  Future<void> setVolume(double volume);

  /// 释放资源
  void dispose();
}

/// TTS 处理器的通用基础实现
/// 提供缓存、错误处理等通用功能
abstract class BaseTTSProcessorImpl implements BaseTTSProcessor {
  bool _disposed = false;
  late final CacheManager _cacheManager;
  
  BaseTTSProcessorImpl() {
    _cacheManager = CacheManager.instance;
  }
  
  /// 缓存管理器
  CacheManager get cacheManager => _cacheManager;
  
  /// 检查是否已释放
  bool get isDisposed => _disposed;
  
  /// 确保未释放
  void ensureNotDisposed() {
    if (_disposed) {
      throw StateError('Processor has been disposed');
    }
  }
  
  /// 处理语音列表获取的通用逻辑
  Future<List<Voice>> getVoicesWithCache(Future<List<Voice>> Function() fetcher) async {
    ensureNotDisposed();
    
    // 检查缓存
    final cachedVoices = _cacheManager.getCachedVoices(backend);
    if (cachedVoices != null) {
      return cachedVoices;
    }

    return await ErrorHandler.wrapAsync(
      () async {
        TTSLogger.voice('Loading voices', 0, backend);
        final voices = await fetcher();
        
        // 缓存结果
        _cacheManager.cacheVoices(backend, voices);
        
        TTSLogger.voice('Loaded voices', voices.length, backend);
        return voices;
      },
      '$backend voice list retrieval',
      TTSErrorCodes.voiceListError,
    );
  }
  
  /// 处理文本合成的通用逻辑
  Future<Uint8List> synthesizeTextWithCache(
    String text,
    String voiceName,
    String format,
    Future<Uint8List> Function() synthesizer,
  ) async {
    ensureNotDisposed();
    
    // 验证参数
    _validateSynthesisParams(text, voiceName);

    // 检查缓存
    final cachedAudio = _cacheManager.getCachedAudio(text, voiceName, format);
    if (cachedAudio != null) {
      TTSLogger.debug('Using cached audio data for synthesis');
      return cachedAudio;
    }

    return await ErrorHandler.wrapAsync(
      () async {
        TTSLogger.debug('Starting text synthesis with $backend for text: ${text.length} chars, voice: $voiceName, format: $format');
        
        final audioData = await synthesizer();
        
        // 缓存结果
        _cacheManager.cacheAudio(text, voiceName, format, audioData);
        
        TTSLogger.debug('Text synthesis completed successfully - ${audioData.length} bytes generated');
        
        return audioData;
      },
      '$backend text synthesis',
      TTSErrorCodes.synthesisError,
    );
  }
  
  /// 验证合成参数
  void _validateSynthesisParams(String text, String voiceName) {
    if (text.trim().isEmpty) {
      throw TTSError(
        'Text cannot be empty. Please provide valid text content for synthesis.',
        code: TTSErrorCodes.emptyText,
      );
    }

    if (voiceName.trim().isEmpty) {
      throw TTSError(
        'Voice name cannot be empty. Please specify a valid voice name. '
        'Use getVoices() to see available voices.',
        code: TTSErrorCodes.emptyVoiceName,
      );
    }
  }
  
  @override
  void dispose() {
    TTSLogger.debug('Disposing $backend processor');
    _disposed = true;
  }
}