/// TTS 错误处理类
/// 参照 hello-tts-dart 的 TTSError 设计
/// 提供统一的错误处理机制，包含错误代码和恢复建议
class TTSError extends Error {
  /// 错误消息
  final String message;

  /// 错误代码 (可选)
  final String? code;

  /// 原始错误对象 (可选)
  final dynamic originalError;

  TTSError(this.message, {this.code, this.originalError});

  /// 检查是否为特定类型的错误
  bool isErrorType(String errorCode) {
    return code == errorCode;
  }

  /// 检查是否为初始化相关错误
  bool get isInitializationError => 
      code == TTSErrorCodes.initializationFailed ||
      code == TTSErrorCodes.notInitialized;

  /// 检查是否为语音相关错误
  bool get isVoiceError => 
      code == TTSErrorCodes.voiceNotFound ||
      code == TTSErrorCodes.noVoiceSelected ||
      code == TTSErrorCodes.voiceListFailed ||
      code == TTSErrorCodes.invalidVoiceFormat;

  /// 检查是否为合成相关错误
  bool get isSynthesisError => 
      code == TTSErrorCodes.synthesisError ||
      code == TTSErrorCodes.synthesisFailed ||
      code == TTSErrorCodes.emptyText ||
      code == TTSErrorCodes.emptyVoiceName;

  /// 检查是否为播放相关错误
  bool get isPlaybackError => 
      code == TTSErrorCodes.playbackFailed ||
      code == TTSErrorCodes.noPlayerFound ||
      code == TTSErrorCodes.stopFailed;

  /// 检查是否为资源相关错误
  bool get isResourceError => 
      code == TTSErrorCodes.fileNotFound ||
      code == TTSErrorCodes.outputFileNotCreated ||
      code == TTSErrorCodes.tempFileCreationFailed ||
      code == TTSErrorCodes.disposeFailed;

  @override
  String toString() {
    return 'TTSError: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

/// TTS 错误代码常量
/// 提供标准化的错误代码，便于错误处理和恢复
class TTSErrorCodes {
  // 初始化相关错误
  static const String initializationFailed = 'INITIALIZATION_FAILED';
  static const String notInitialized = 'NOT_INITIALIZED';
  
  // 配置相关错误
  static const String configurationError = 'CONFIGURATION_ERROR';
  
  // 语音相关错误
  static const String voiceNotFound = 'VOICE_NOT_FOUND';
  static const String noVoiceSelected = 'NO_VOICE_SELECTED';
  static const String voiceListFailed = 'VOICE_LIST_FAILED';
  static const String voiceListError = 'VOICE_LIST_ERROR';
  static const String invalidVoiceFormat = 'INVALID_VOICE_FORMAT';
  static const String invalidVoiceNameFormat = 'INVALID_VOICE_NAME_FORMAT';
  static const String voiceParseError = 'VOICE_PARSE_ERROR';
  
  // 合成相关错误
  static const String synthesisError = 'SYNTHESIS_ERROR';
  static const String synthesisFailed = 'SYNTHESIS_FAILED';
  static const String emptyText = 'EMPTY_TEXT';
  static const String emptyVoiceName = 'EMPTY_VOICE_NAME';
  static const String outputFileNotCreated = 'OUTPUT_FILE_NOT_CREATED';
  
  // 播放相关错误
  static const String playbackFailed = 'PLAYBACK_FAILED';
  static const String playbackError = 'PLAYBACK_ERROR';
  static const String noPlayerFound = 'NO_PLAYER_FOUND';
  static const String stopFailed = 'STOP_FAILED';
  static const String speakFailed = 'SPEAK_FAILED';
  
  // 文件和资源相关错误
  static const String fileNotFound = 'FILE_NOT_FOUND';
  static const String tempFileCreationFailed = 'TEMP_FILE_CREATION_FAILED';
  static const String tempFileCleanupFailed = 'TEMP_FILE_CLEANUP_FAILED';
  static const String disposeFailed = 'DISPOSE_FAILED';
  static const String disposePartialFailure = 'DISPOSE_PARTIAL_FAILURE';
  
  // 平台相关错误
  static const String platformNotSupported = 'PLATFORM_NOT_SUPPORTED';
  
  // 配置相关错误
  static const String configError = 'CONFIG_ERROR';
}