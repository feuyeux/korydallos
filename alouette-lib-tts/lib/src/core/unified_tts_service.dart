import 'dart:typed_data';

import 'tts_processor.dart';
import '../platform/platform_tts_factory.dart';
import '../utils/platform_utils.dart';
import '../models/voice.dart';
import '../models/tts_error.dart';

/// Unified TTS Service - Main entry point for text-to-speech functionality
/// 
/// This service provides a unified interface to multiple TTS engines, automatically
/// selecting the best engine for each platform and allowing runtime engine switching.
/// 
/// ## Platform Selection Strategy
/// 
/// - **Desktop** (Windows, macOS, Linux): Prefers Edge TTS for high-quality neural voices
/// - **Mobile** (Android, iOS): Uses Flutter TTS for native system integration  
/// - **Web**: Uses Flutter TTS with Web Speech API
/// 
/// ## Basic Usage
/// 
/// ```dart
/// final ttsService = UnifiedTTSService();
/// await ttsService.initialize();
/// 
/// final voices = await ttsService.getVoices();
/// final audioData = await ttsService.synthesizeText('Hello world', voices.first.name);
/// 
/// final player = AudioPlayer();
/// await player.playBytes(audioData);
/// 
/// ttsService.dispose();
/// ```
/// 
/// ## Engine Selection
/// 
/// ```dart
/// // Automatic platform-based selection
/// await ttsService.initialize();
/// 
/// // Manual engine preference
/// await ttsService.initialize(preferredEngine: TTSEngineType.edge);
/// 
/// // Runtime engine switching
/// await ttsService.switchEngine(TTSEngineType.flutter);
/// ```
/// 
/// ## Error Handling
/// 
/// All methods throw [TTSError] with specific error codes for programmatic handling:
/// 
/// ```dart
/// try {
///   await ttsService.synthesizeText('Hello', 'invalid-voice');
/// } on TTSError catch (e) {
///   switch (e.code) {
///     case TTSErrorCodes.voiceNotFound:
///       // Handle voice not found
///       break;
///     case TTSErrorCodes.synthesisFailed:
///       // Handle synthesis failure
///       break;
///   }
/// }
/// ```
class UnifiedTTSService {
  TTSProcessor? _processor;
  TTSEngineType? _currentEngine;
  bool _initialized = false;

  /// Returns the currently active TTS engine type
  /// 
  /// Returns `null` if the service is not initialized.
  /// 
  /// Example:
  /// ```dart
  /// await ttsService.initialize();
  /// print('Current engine: ${ttsService.currentEngine}'); // TTSEngineType.edge
  /// ```
  TTSEngineType? get currentEngine => _currentEngine;

  /// Returns the backend identifier of the current processor
  /// 
  /// Returns `null` if no processor is active.
  /// Backend identifiers: 'edge', 'flutter'
  String? get currentBackend => _processor?.backend;

  /// Checks if the service has been properly initialized
  /// 
  /// Returns `true` if [initialize] has been called successfully and a processor is active.
  bool get isInitialized => _initialized && _processor != null;

  /// Initializes the TTS service with automatic or manual engine selection
  /// 
  /// This method must be called before using any other TTS functionality.
  /// 
  /// **Parameters:**
  /// - [preferredEngine]: Optional engine preference. If `null`, automatically selects
  ///   the best engine for the current platform.
  /// - [autoFallback]: Whether to automatically fallback to other engines if the
  ///   preferred engine is not available. Default: `true`.
  /// 
  /// **Platform Selection Logic:**
  /// - Desktop: Prefers Edge TTS, falls back to Flutter TTS
  /// - Mobile: Uses Flutter TTS
  /// - Web: Uses Flutter TTS
  /// 
  /// **Examples:**
  /// ```dart
  /// // Automatic selection
  /// await ttsService.initialize();
  /// 
  /// // Prefer Edge TTS with fallback
  /// await ttsService.initialize(preferredEngine: TTSEngineType.edge);
  /// 
  /// // Require specific engine (no fallback)
  /// await ttsService.initialize(
  ///   preferredEngine: TTSEngineType.edge,
  ///   autoFallback: false,
  /// );
  /// ```
  /// 
  /// **Throws:**
  /// - [TTSError] with code [TTSErrorCodes.initializationFailed] if no suitable
  ///   engine can be initialized.
  Future<void> initialize({
    TTSEngineType? preferredEngine,
    bool autoFallback = true,
  }) async {
    if (_initialized) {
      return; // 已经初始化，直接返回
    }

    try {
      if (preferredEngine != null) {
        // 尝试使用指定的引擎
        try {
          _processor = await PlatformTTSFactory.create(preferredEngine);
          _currentEngine = preferredEngine;
        } catch (e) {
          if (!autoFallback) {
            rethrow; // 不允许回退时直接抛出错误
          }
          
          // 回退到平台推荐的引擎
          _processor = await PlatformTTSFactory.createForPlatform();
          _currentEngine = PlatformTTSFactory.recommendedEngineType;
        }
      } else {
        // 自动选择最适合的引擎
        _processor = await PlatformTTSFactory.createForPlatform();
        _currentEngine = PlatformTTSFactory.recommendedEngineType;
      }

      _initialized = true;
    } catch (e) {
      throw TTSError(
        'Failed to initialize TTS service: $e. '
        'Please ensure at least one TTS engine is available on your platform.',
        code: TTSErrorCodes.initializationFailed,
        originalError: e,
      );
    }
  }

  /// Switches to a different TTS engine at runtime
  /// 
  /// This allows changing TTS engines without recreating the service instance.
  /// Useful for adapting to different quality requirements or platform capabilities.
  /// 
  /// **Parameters:**
  /// - [engineType]: The target engine type to switch to
  /// - [disposeOld]: Whether to dispose the old processor resources. Default: `true`
  /// 
  /// **Examples:**
  /// ```dart
  /// // Switch to Edge TTS for higher quality
  /// await ttsService.switchEngine(TTSEngineType.edge);
  /// 
  /// // Switch to Flutter TTS for better compatibility
  /// await ttsService.switchEngine(TTSEngineType.flutter);
  /// 
  /// // Keep old processor resources (advanced usage)
  /// await ttsService.switchEngine(TTSEngineType.edge, disposeOld: false);
  /// ```
  /// 
  /// **Behavior:**
  /// - If already using the target engine, this method returns immediately
  /// - On failure, the previous engine is restored
  /// - Voice caches are cleared when switching engines
  /// 
  /// **Throws:**
  /// - [TTSError] with code [TTSErrorCodes.initializationFailed] if the target
  ///   engine cannot be initialized
  Future<void> switchEngine(
    TTSEngineType engineType, {
    bool disposeOld = true,
  }) async {
    if (_currentEngine == engineType && _processor != null) {
      return; // 已经是目标引擎，无需切换
    }

    TTSProcessor? oldProcessor = _processor;

    try {
      // 创建新的处理器
      _processor = await PlatformTTSFactory.create(engineType);
      _currentEngine = engineType;

      // 释放旧的处理器
      if (disposeOld && oldProcessor != null) {
        try {
          oldProcessor.dispose();
        } catch (e) {
          // 记录释放错误但不影响切换操作
        }
      }
    } catch (e) {
      // 切换失败时恢复旧的处理器
      _processor = oldProcessor;
      
      throw TTSError(
        'Failed to switch to ${engineType.name} engine: $e. '
        'The previous engine has been restored.',
        code: TTSErrorCodes.initializationFailed,
        originalError: e,
      );
    }
  }

  /// Retrieves all available voices from the current TTS engine
  /// 
  /// Returns a list of [Voice] objects containing metadata about each available voice.
  /// Results are cached by the underlying processor for performance.
  /// 
  /// **Voice Properties:**
  /// - `name`: Unique identifier for synthesis calls
  /// - `displayName`: Human-readable name for UI display
  /// - `language`: ISO language code (e.g., 'en', 'zh')
  /// - `locale`: Full locale identifier (e.g., 'en-US', 'zh-CN')
  /// - `gender`: 'Male', 'Female', or 'Unknown'
  /// - `isNeural`: Whether it's a high-quality neural voice
  /// - `isStandard`: Whether it's a traditional/standard voice
  /// 
  /// **Examples:**
  /// ```dart
  /// final voices = await ttsService.getVoices();
  /// 
  /// // Filter by language
  /// final englishVoices = voices.where((v) => v.language == 'en').toList();
  /// 
  /// // Find neural voices
  /// final neuralVoices = voices.where((v) => v.isNeural).toList();
  /// 
  /// // Display voice information
  /// for (final voice in voices) {
  ///   print('${voice.displayName} (${voice.locale}, ${voice.gender})');
  /// }
  /// ```
  /// 
  /// **Throws:**
  /// - [TTSError] with code [TTSErrorCodes.notInitialized] if service not initialized
  /// - [TTSError] with code [TTSErrorCodes.voiceListError] if voice retrieval fails
  Future<List<Voice>> getVoices() async {
    _ensureInitialized();
    
    try {
      return await _processor!.getVoices();
    } catch (e) {
      throw TTSError(
        'Failed to get voices from ${_currentEngine?.name} engine: $e',
        code: TTSErrorCodes.voiceListError,
        originalError: e,
      );
    }
  }

  /// Synthesizes text to speech and returns audio data
  /// 
  /// Converts the provided text to audio using the specified voice and returns
  /// the audio data as bytes, ready for playback or file writing.
  /// 
  /// **Parameters:**
  /// - [text]: The text to synthesize. Must not be empty or whitespace-only.
  /// - [voiceName]: The voice identifier. Must match a voice from [getVoices].
  /// - [format]: Audio format ('mp3', 'wav', etc.). Default: 'mp3'.
  /// 
  /// **Platform Support:**
  /// - **Edge TTS**: Supports MP3, WAV, OGG formats on all platforms
  /// - **Flutter TTS**: Format support varies by platform
  /// - **Web**: Limited format support, may not support file generation
  /// 
  /// **Examples:**
  /// ```dart
  /// final voices = await ttsService.getVoices();
  /// 
  /// // Basic synthesis
  /// final audioData = await ttsService.synthesizeText(
  ///   'Hello, world!',
  ///   voices.first.name,
  /// );
  /// 
  /// // Specify format
  /// final wavData = await ttsService.synthesizeText(
  ///   'Hello, world!',
  ///   voices.first.name,
  ///   format: 'wav',
  /// );
  /// 
  /// // Save to file
  /// await File('output.mp3').writeAsBytes(audioData);
  /// 
  /// // Play directly
  /// final player = AudioPlayer();
  /// await player.playBytes(audioData);
  /// ```
  /// 
  /// **Returns:**
  /// A [Uint8List] containing the audio data in the specified format.
  /// 
  /// **Throws:**
  /// - [TTSError] with code [TTSErrorCodes.notInitialized] if service not initialized
  /// - [TTSError] with code [TTSErrorCodes.emptyText] if text is empty
  /// - [TTSError] with code [TTSErrorCodes.emptyVoiceName] if voice name is empty
  /// - [TTSError] with code [TTSErrorCodes.voiceNotFound] if voice doesn't exist
  /// - [TTSError] with code [TTSErrorCodes.synthesisFailed] if synthesis fails
  /// - [TTSError] with code [TTSErrorCodes.platformNotSupported] if format/feature not supported
  Future<Uint8List> synthesizeText(
    String text,
    String voiceName, {
    String format = 'mp3',
  }) async {
    _ensureInitialized();

    try {
      return await _processor!.synthesizeText(
        text,
        voiceName,
        format: format,
      );
    } catch (e) {
      throw TTSError(
        'Failed to synthesize text using ${_currentEngine?.name} engine: $e',
        code: TTSErrorCodes.synthesisError,
        originalError: e,
      );
    }
  }

  /// 停止当前的TTS播放
  /// 
  /// 尝试停止当前正在进行的语音合成或播放。
  /// 不是所有的TTS引擎都支持停止功能。
  /// 
  /// **Throws:**
  /// - [TTSError] with code [TTSErrorCodes.notInitialized] if service not initialized
  /// - [TTSError] with code [TTSErrorCodes.stopFailed] if stop operation fails
  Future<void> stop() async {
    _ensureInitialized();

    try {
      await _processor!.stop();
    } catch (e) {
      throw TTSError(
        'Failed to stop TTS using ${_currentEngine?.name} engine: $e',
        code: TTSErrorCodes.stopFailed,
        originalError: e,
      );
    }
  }

  /// 获取当前平台和引擎信息
  Future<Map<String, dynamic>> getPlatformInfo() async {
    final platformInfo = await PlatformTTSFactory.getPlatformInfo();
    
    return {
      ...platformInfo,
      'currentEngine': _currentEngine?.name,
      'currentBackend': currentBackend,
      'isInitialized': isInitialized,
    };
  }

  /// 检查指定引擎是否可用
  Future<bool> isEngineAvailable(TTSEngineType engineType) async {
    return await PlatformTTSFactory.isEngineAvailable(engineType);
  }

  /// 获取所有可用的引擎类型
  Future<List<TTSEngineType>> getAvailableEngines() async {
    return await PlatformTTSFactory.getAvailableEngines();
  }

  /// 重新初始化服务
  /// 
  /// [preferredEngine] 首选引擎类型
  /// [autoFallback] 是否在首选引擎不可用时自动回退
  Future<void> reinitialize({
    TTSEngineType? preferredEngine,
    bool autoFallback = true,
  }) async {
    dispose();
    await initialize(
      preferredEngine: preferredEngine,
      autoFallback: autoFallback,
    );
  }

  /// 释放资源
  void dispose() {
    try {
      _processor?.dispose();
    } catch (e) {
      // 记录释放错误但不抛出异常
    } finally {
      _processor = null;
      _currentEngine = null;
      _initialized = false;
    }
  }

  /// 确保服务已初始化
  void _ensureInitialized() {
    if (!isInitialized) {
      throw TTSError(
        'TTS service is not initialized. Please call initialize() first.',
        code: TTSErrorCodes.notInitialized,
      );
    }
  }
}