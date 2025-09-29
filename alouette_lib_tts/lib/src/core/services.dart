// Core Services Exports
// This module provides consolidated exports for the main TTS services

// Main service interfaces and implementations
export 'tts_service.dart';
export 'voice_service.dart';

// Audio processing
export 'audio_player.dart';

// Configuration services  
export 'config_manager.dart';
export 'tts_config_service.dart';

// Note: The legacy tts_processor.dart and tts_service.dart interfaces
// have been superseded by the new BaseTTSProcessor in the engines module
// and the UnifiedTTSService respectively.