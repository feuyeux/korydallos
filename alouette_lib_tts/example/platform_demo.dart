import 'package:alouette_lib_tts/alouette_tts.dart';

/// Demonstration of platform-specific TTS engine selection
/// This example shows how the library automatically selects the best engine
/// for the current platform and provides fallback options.
void main() async {
  print('=== Platform-Specific TTS Engine Selection Demo ===\n');

  // Create platform detector to examine current platform
  final platformDetector = PlatformDetector();
  
  print('Platform Information:');
  final platformInfo = platformDetector.getPlatformInfo();
  platformInfo.forEach((key, value) {
    print('  $key: $value');
  });
  
  print('\nPlatform Strategy:');
  final strategy = platformDetector.getTTSStrategy();
  print('  Strategy Type: ${strategy.runtimeType}');
  print('  Preferred Engine: ${strategy.preferredEngine.name}');
  print('  Fallback Engines: ${strategy.getFallbackEngines().map((e) => e.name).join(', ')}');
  
  print('\nEngine Support Matrix:');
  for (final engine in TTSEngineType.values) {
    final supported = strategy.isEngineSupported(engine);
    final config = strategy.getEngineConfig(engine);
    print('  ${engine.name}: ${supported ? 'Supported' : 'Not Supported'}');
    if (supported && config.isNotEmpty) {
      config.forEach((key, value) {
        print('    $key: $value');
      });
    }
  }
  
  // Create TTS service and demonstrate automatic engine selection
  print('\n=== TTS Service Initialization ===');
  final ttsService = TTSService();
  
  try {
    print('Initializing TTS service with automatic platform detection...');
    await ttsService.initialize();
    
    print('✓ TTS service initialized successfully');
    print('  Selected Engine: ${ttsService.currentEngine?.name}');
    print('  Engine Name: ${ttsService.currentEngineName}');
    
    // Get platform info from service
    final serviceInfo = await ttsService.getPlatformInfo();
    print('\nService Platform Information:');
    print('  Current Engine: ${serviceInfo['currentEngine']}');
    print('  Strategy: ${serviceInfo['strategy']}');
    print('  Fallback Engines: ${serviceInfo['fallbackEngines']}');
    print('  Supported Engines: ${serviceInfo['supportedEngines']}');
    
    // Demonstrate engine availability checking
    print('\n=== Engine Availability ===');
    for (final engine in TTSEngineType.values) {
      final available = await ttsService.isEngineAvailable(engine);
      print('  ${engine.name}: ${available ? 'Available' : 'Not Available'}');
    }
    
    // Demonstrate fallback behavior
    print('\n=== Fallback Demonstration ===');
    final fallbackEngines = ttsService.getFallbackEngines();
    print('Fallback order for current platform: ${fallbackEngines.map((e) => e.name).join(' → ')}');
    
    // Try switching engines to demonstrate fallback logic
    for (final engine in TTSEngineType.values) {
      if (engine != ttsService.currentEngine) {
        try {
          print('\nTrying to switch to ${engine.name}...');
          await ttsService.switchEngine(engine, autoFallback: true);
          print('✓ Successfully switched to ${engine.name}');
        } catch (e) {
          print('✗ Failed to switch to ${engine.name}: $e');
        }
      }
    }
    
    print('\nFinal engine: ${ttsService.currentEngine?.name}');
    
  } catch (e) {
    print('✗ Failed to initialize TTS service: $e');
  } finally {
    ttsService.dispose();
    print('\n✓ TTS service disposed');
  }
  
  print('\n=== Demo Complete ===');
}