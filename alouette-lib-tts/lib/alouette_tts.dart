/// Alouette TTS - Multi-platform TTS library
///
/// This library provides text-to-speech functionality through multiple implementations:
/// - Edge TTS: Microsoft Edge's TTS engine via command line
/// - Flutter TTS: Cross-platform TTS using system engines
///
/// ## New Unified API (Recommended)
///
/// The new unified API provides a consistent interface across all TTS engines:
///
/// ```dart
/// import 'package:alouette_tts/alouette_tts.dart';
///
/// // Create a unified TTS service with automatic platform detection
/// final ttsService = UnifiedTTSService();
/// await ttsService.initialize();
///
/// // Get available voices
/// final voices = await ttsService.getVoices();
///
/// // Synthesize text to audio data
/// final audioData = await ttsService.synthesizeText('Hello world', voices.first.name);
///
/// // Play audio using the built-in player
/// final audioPlayer = AudioPlayer();
/// await audioPlayer.playBytes(audioData);
/// ```
///
/// ## Platform-Specific Engine Selection
///
/// You can also manually select engines or use platform-specific factories:
///
/// ```dart
/// // Automatic platform-based selection
/// final processor = await PlatformTTSFactory.createForPlatform();
///
/// // Manual engine selection
/// final edgeProcessor = await PlatformTTSFactory.create(TTSEngineType.edge);
/// final flutterProcessor = await PlatformTTSFactory.create(TTSEngineType.flutter);
/// ```
///
/// ## Legacy API (Backward Compatible)
///
/// The original API is still available for backward compatibility:
///
/// ```dart
/// // Legacy Edge TTS usage
/// final edgeService = EdgeTTSService();
/// await edgeService.initialize();
///
/// // Legacy Flutter TTS usage  
/// final flutterService = FlutterTTSService();
/// await flutterService.initialize();
/// ```
library alouette_tts;

// Core interfaces (existing - for backward compatibility)
export 'src/core/tts_service.dart';
export 'src/core/tts_player.dart';
export 'src/core/tts_voice_adapter.dart';
export 'src/core/tts_factory.dart';

// New core interfaces (unified design)
export 'src/core/tts_processor.dart';
export 'src/core/audio_player.dart';
export 'src/core/config_manager.dart';
export 'src/core/unified_tts_service.dart';

// Platform-specific factory
export 'src/platform/platform_tts_factory.dart';

// Edge TTS implementation
export 'src/edge/edge_tts_service.dart';
export 'src/edge/edge_tts_player.dart';
export 'src/edge/edge_tts_voice_adapter.dart';
export 'src/edge/edge_tts_processor.dart';

// Flutter TTS implementation
export 'src/flutter/flutter_tts_service.dart';
export 'src/flutter/flutter_tts_player.dart';
export 'src/flutter/flutter_tts_voice_adapter.dart';
export 'src/flutter/flutter_tts_processor.dart';

// Models (updated Voice model + new models)
export 'src/models/voice.dart';
export 'src/models/tts_error.dart';
export 'src/models/tts_config.dart';

// Enums (existing - for backward compatibility)
export 'src/enums/voice_gender.dart';
export 'src/enums/voice_quality.dart';

// Utilities
export 'src/utils/platform_utils.dart';
export 'src/utils/file_utils.dart';
export 'src/utils/command_line_checker.dart';
