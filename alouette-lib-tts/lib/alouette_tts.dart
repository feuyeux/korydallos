/// Alouette TTS - Multi-platform TTS library
///
/// This library provides text-to-speech functionality through multiple implementations:
/// - Edge TTS: Microsoft Edge's TTS engine via command line
/// - Flutter TTS: Cross-platform TTS using system engines
library alouette_tts;

// Core interfaces
export 'src/core/tts_service.dart';
export 'src/core/tts_player.dart';
export 'src/core/tts_voice_adapter.dart';
export 'src/core/tts_factory.dart';

// Platform-specific factory
export 'src/platform/platform_tts_factory.dart';

// Edge TTS implementation
export 'src/edge/edge_tts_service.dart';
export 'src/edge/edge_tts_player.dart';
export 'src/edge/edge_tts_voice_adapter.dart';

// Flutter TTS implementation
export 'src/flutter/flutter_tts_service.dart';
export 'src/flutter/flutter_tts_player.dart';
export 'src/flutter/flutter_tts_voice_adapter.dart';

// Models
export 'src/models/voice.dart';

// Enums
export 'src/enums/voice_gender.dart';
export 'src/enums/voice_quality.dart';
