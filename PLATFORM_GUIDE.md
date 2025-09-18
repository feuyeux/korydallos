# Platform-Specific Configuration Guide

This guide covers platform-specific behavior, configuration options, and optimization strategies for the Alouette ecosystem.

## Table of Contents

- [Desktop Platforms](#desktop-platforms)
- [Mobile Platforms](#mobile-platforms)
- [Web Platform](#web-platform)
- [Cross-Platform Considerations](#cross-platform-considerations)
- [Performance Optimization](#performance-optimization)
- [Troubleshooting](#troubleshooting)

## Desktop Platforms

### Windows

#### TTS Configuration

**Primary Engine:** Edge TTS (Microsoft Edge Text-to-Speech)

**Prerequisites:**
```bash
# Install Python 3.7+
# Download from https://python.org or use Microsoft Store

# Install Edge TTS
pip install edge-tts

# Verify installation
edge-tts --list-voices
```

**Configuration:**
```dart
// Automatic Edge TTS selection on Windows
final ttsService = UnifiedTTSService();
await ttsService.initialize(); // Automatically selects Edge TTS

// Manual configuration
await ttsService.initialize(preferredEngine: TTSEngineType.edge);
```

**Features:**
- High-quality neural voices
- 100+ languages and variants
- Offline synthesis after initial setup
- Audio file export (MP3, WAV, OGG)
- SSML support for advanced speech control

**Optimization:**
```dart
// Windows-specific optimizations
final ttsConfig = TTSConfig(
  engineType: TTSEngineType.edge,
  speechRate: 1.0,
  volume: 0.8,
  engineSpecificSettings: {
    'outputFormat': 'audio-24khz-48kbitrate-mono-mp3',
    'voiceQuality': 'neural',
    'enableSSML': true,
  },
);
```

#### Translation Configuration

**LLM Providers:**
- Ollama (recommended for local AI)
- LM Studio
- Custom OpenAI-compatible APIs

**Ollama Setup:**
```bash
# Download and install Ollama for Windows
# Visit https://ollama.ai/download/windows

# Start Ollama service
ollama serve

# Pull a model
ollama pull llama3.2
ollama pull qwen2.5:7b
```

**LM Studio Setup:**
1. Download LM Studio from https://lmstudio.ai
2. Install and launch the application
3. Download a compatible model (e.g., Llama 3.2, Qwen 2.5)
4. Start the local server from the "Local Server" tab
5. Configure API endpoint: `http://localhost:1234/v1`

#### File System Permissions

**Audio Export Location:**
```dart
// Windows default paths
final documentsPath = await getApplicationDocumentsDirectory();
final audioPath = path.join(documentsPath.path, 'Alouette', 'Audio');

// Ensure directory exists
await Directory(audioPath).create(recursive: true);
```

**Configuration Storage:**
- SharedPreferences: Windows Registry
- File Storage: `%USERPROFILE%\Documents\Alouette\`

### macOS

#### TTS Configuration

**Primary Engine:** Edge TTS

**Prerequisites:**
```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Python
brew install python

# Install Edge TTS
pip3 install edge-tts

# Verify installation
edge-tts --list-voices
```

**System Integration:**
```dart
// macOS-specific TTS settings
final ttsConfig = TTSConfig(
  engineType: TTSEngineType.edge,
  engineSpecificSettings: {
    'outputFormat': 'audio-24khz-48kbitrate-mono-mp3',
    'respectSystemVolume': true,
    'useSystemAudioSession': true,
  },
);
```

#### Translation Configuration

**Ollama Setup:**
```bash
# Install Ollama for macOS
brew install ollama

# Start Ollama service
ollama serve

# Pull models
ollama pull llama3.2
```

**Network Configuration:**
```bash
# For external access (optional)
export OLLAMA_HOST=0.0.0.0:11434
ollama serve
```

#### Security Considerations

**App Sandbox:**
- Enable network access for LLM communication
- Enable file access for audio export
- Configure microphone access if needed for future features

**Entitlements (for App Store distribution):**
```xml
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
<key>com.apple.security.files.downloads.read-write</key>
<true/>
```

### Linux

#### TTS Configuration

**Primary Engine:** Edge TTS

**Prerequisites:**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install python3 python3-pip

# Fedora/RHEL
sudo dnf install python3 python3-pip

# Arch Linux
sudo pacman -S python python-pip

# Install Edge TTS
pip3 install edge-tts

# Verify installation
edge-tts --list-voices
```

**Audio System Integration:**
```dart
// Linux-specific audio configuration
final ttsConfig = TTSConfig(
  engineType: TTSEngineType.edge,
  engineSpecificSettings: {
    'audioBackend': 'pulse', // or 'alsa'
    'outputFormat': 'audio-24khz-48kbitrate-mono-mp3',
  },
);
```

#### Translation Configuration

**Ollama Setup:**
```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Start as service
sudo systemctl enable ollama
sudo systemctl start ollama

# Or run manually
ollama serve
```

**Firewall Configuration:**
```bash
# Allow Ollama port (if needed for external access)
sudo ufw allow 11434/tcp

# For LM Studio
sudo ufw allow 1234/tcp
```

#### System Dependencies

**Required packages:**
```bash
# Ubuntu/Debian
sudo apt install libasound2-dev libpulse-dev

# Fedora/RHEL
sudo dnf install alsa-lib-devel pulseaudio-libs-devel

# Arch Linux
sudo pacman -S alsa-lib libpulse
```

## Mobile Platforms

### Android

#### TTS Configuration

**Primary Engine:** Flutter TTS (System TTS)

**Features:**
- Native Android TTS integration
- System voice selection
- Background playback support
- No additional dependencies required

**Configuration:**
```dart
// Android automatically uses Flutter TTS
final ttsService = UnifiedTTSService();
await ttsService.initialize(); // Automatically selects Flutter TTS

// Android-specific settings
final ttsConfig = TTSConfig(
  engineType: TTSEngineType.flutter,
  speechRate: 1.0,
  volume: 0.8,
  engineSpecificSettings: {
    'androidEngine': 'com.google.android.tts',
    'enableNetworkVoices': true,
    'queueMode': 'flush',
  },
);
```

**System Voice Management:**
```dart
// Check available voices
final voices = await ttsService.getVoices();
final englishVoices = voices.where((v) => v.language.startsWith('en')).toList();

// Filter by quality
final neuralVoices = voices.where((v) => v.isNeural).toList();
```

#### Translation Configuration

**Network Requirements:**
- Internet connection for LLM communication
- Consider mobile data usage
- Implement offline fallback if needed

**Configuration:**
```dart
// Mobile-optimized translation settings
final llmConfig = LLMConfig(
  provider: 'ollama',
  serverUrl: 'http://your-server:11434', // Remote server
  additionalSettings: {
    'timeout': 30000, // 30 second timeout
    'retryAttempts': 3,
    'compressRequests': true,
  },
);
```

#### Permissions

**AndroidManifest.xml:**
```xml
<!-- Network access for LLM communication -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- Audio playback -->
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />

<!-- Background audio (optional) -->
<uses-permission android:name="android.permission.WAKE_LOCK" />

<!-- Storage for audio export (optional) -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

#### Performance Optimization

**Memory Management:**
```dart
// Dispose services when not needed
@override
void dispose() {
  ttsService.dispose();
  super.dispose();
}

// Use efficient audio formats
final audioData = await ttsService.synthesizeText(
  text,
  voiceName,
  format: 'mp3', // Smaller file size
);
```

### iOS

#### TTS Configuration

**Primary Engine:** Flutter TTS (AVSpeechSynthesizer)

**Features:**
- Native iOS speech synthesis
- Siri voice integration
- Background audio support
- AirPlay compatibility

**Configuration:**
```dart
// iOS automatically uses Flutter TTS
final ttsService = UnifiedTTSService();
await ttsService.initialize();

// iOS-specific settings
final ttsConfig = TTSConfig(
  engineType: TTSEngineType.flutter,
  engineSpecificSettings: {
    'iosAudioCategory': 'playback',
    'iosAudioMode': 'spokenAudio',
    'enableAirPlay': true,
    'respectSilentMode': false,
  },
);
```

**Voice Quality:**
```dart
// Prefer enhanced/neural voices on iOS
final voices = await ttsService.getVoices();
final enhancedVoices = voices.where((v) => 
  v.displayName.contains('Enhanced') || 
  v.displayName.contains('Premium')
).toList();
```

#### Translation Configuration

**Network Configuration:**
```dart
// iOS network settings
final llmConfig = LLMConfig(
  provider: 'ollama',
  serverUrl: 'http://your-server:11434',
  additionalSettings: {
    'allowCellularAccess': true,
    'timeoutInterval': 30.0,
    'cachePolicy': 'useProtocolCachePolicy',
  },
);
```

#### App Transport Security

**Info.plist configuration:**
```xml
<!-- For local development servers -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <!-- Or more restrictive: -->
    <key>NSExceptionDomains</key>
    <dict>
        <key>localhost</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

#### Background Audio

**Capabilities:**
```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

**Implementation:**
```dart
// Configure audio session for background playback
final ttsConfig = TTSConfig(
  engineSpecificSettings: {
    'iosAudioCategory': 'playback',
    'iosAudioOptions': ['mixWithOthers', 'duckOthers'],
  },
);
```

## Web Platform

### TTS Configuration

**Primary Engine:** Flutter TTS (Web Speech API)

**Browser Support:**
- Chrome/Chromium: Full support
- Firefox: Limited support
- Safari: Basic support
- Edge: Full support

**Configuration:**
```dart
// Web automatically uses Flutter TTS with Web Speech API
final ttsService = UnifiedTTSService();
await ttsService.initialize();

// Web-specific limitations
final ttsConfig = TTSConfig(
  engineType: TTSEngineType.flutter,
  engineSpecificSettings: {
    'webSpeechAPI': true,
    'fallbackToAudio': false, // No audio file generation on web
    'respectBrowserSettings': true,
  },
);
```

**Limitations:**
- No audio file generation/export
- Limited voice selection (browser-dependent)
- Requires user interaction to start speech
- No background playback

### Translation Configuration

**CORS Considerations:**
```dart
// Web-specific LLM configuration
final llmConfig = LLMConfig(
  provider: 'ollama',
  serverUrl: 'http://localhost:11434',
  additionalSettings: {
    'corsMode': 'cors',
    'credentials': 'omit',
    'headers': {
      'Content-Type': 'application/json',
    },
  },
);
```

**Server Configuration:**
```bash
# Ollama with CORS support
export OLLAMA_ORIGINS="http://localhost:*,https://localhost:*"
ollama serve
```

### Progressive Web App (PWA)

**Manifest Configuration:**
```json
{
  "name": "Alouette Translation & TTS",
  "short_name": "Alouette",
  "description": "AI-powered translation and text-to-speech",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#3b82f6",
  "icons": [
    {
      "src": "icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    }
  ]
}
```

**Service Worker:**
```javascript
// Cache translation results for offline access
self.addEventListener('fetch', (event) => {
  if (event.request.url.includes('/api/translate')) {
    event.respondWith(
      caches.match(event.request).then((response) => {
        return response || fetch(event.request);
      })
    );
  }
});
```

## Cross-Platform Considerations

### Automatic Platform Detection

```dart
// Platform-specific service initialization
class PlatformTTSFactory {
  static Future<TTSProcessor> createForPlatform() async {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // Desktop: Prefer Edge TTS
      if (await EdgeTTSProcessor.isAvailable()) {
        return EdgeTTSProcessor();
      }
    }
    
    // Mobile/Web: Use Flutter TTS
    return FlutterTTSProcessor();
  }
}
```

### Configuration Synchronization

```dart
// Cross-platform configuration sync
class ConfigurationSync {
  static Future<void> syncAcrossDevices() async {
    final config = await ConfigurationManager.instance.getConfiguration();
    
    // Export configuration
    final configJson = await ConfigurationManager.instance.exportConfiguration();
    
    // Store in cloud service (implementation-specific)
    await CloudStorage.store('alouette_config', configJson);
  }
  
  static Future<void> importFromCloud() async {
    final configJson = await CloudStorage.retrieve('alouette_config');
    
    if (configJson != null) {
      await ConfigurationManager.instance.importConfiguration(configJson);
    }
  }
}
```

### Responsive UI Design

```dart
// Platform-adaptive UI components
class AdaptiveTranslationPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth > 1200) {
      // Desktop layout
      return DesktopTranslationPanel();
    } else if (screenWidth > 600) {
      // Tablet layout
      return TabletTranslationPanel();
    } else {
      // Mobile layout
      return MobileTranslationPanel();
    }
  }
}
```

## Performance Optimization

### Memory Management

```dart
// Efficient service lifecycle management
class ServiceLifecycleManager {
  static final Map<Type, Timer> _disposalTimers = {};
  
  static void scheduleDisposal<T>(T service, Duration delay) {
    _disposalTimers[T]?.cancel();
    _disposalTimers[T] = Timer(delay, () {
      if (service is Disposable) {
        service.dispose();
      }
      _disposalTimers.remove(T);
    });
  }
  
  static void cancelDisposal<T>() {
    _disposalTimers[T]?.cancel();
    _disposalTimers.remove(T);
  }
}
```

### Network Optimization

```dart
// Efficient LLM request handling
class OptimizedTranslationService {
  final Map<String, TranslationResult> _cache = {};
  final Queue<TranslationRequest> _requestQueue = Queue();
  
  Future<TranslationResult> translateWithOptimization(
    String text,
    List<String> languages,
    LLMConfig config,
  ) async {
    // Check cache first
    final cacheKey = '$text-${languages.join(',')}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }
    
    // Batch similar requests
    final request = TranslationRequest(text, languages, config);
    _requestQueue.add(request);
    
    // Process queue with debouncing
    return _processBatchedRequests();
  }
}
```

### Audio Optimization

```dart
// Efficient audio handling
class AudioOptimizer {
  static Future<Uint8List> optimizeAudioForPlatform(
    Uint8List audioData,
    String format,
  ) async {
    if (Platform.isAndroid || Platform.isIOS) {
      // Mobile: Compress for bandwidth
      return await compressAudio(audioData, quality: 0.7);
    } else if (kIsWeb) {
      // Web: Convert to supported format
      return await convertToWebAudio(audioData);
    } else {
      // Desktop: Keep high quality
      return audioData;
    }
  }
}
```

## Troubleshooting

### Common Issues by Platform

#### Windows Issues

**Edge TTS not working:**
```bash
# Check Python installation
python --version

# Reinstall Edge TTS
pip uninstall edge-tts
pip install edge-tts

# Test manually
edge-tts --text "Hello World" --write-media hello.mp3
```

**Ollama connection issues:**
```bash
# Check if Ollama is running
netstat -an | findstr :11434

# Restart Ollama service
ollama serve

# Check firewall settings
# Windows Defender Firewall -> Allow an app -> Add ollama.exe
```

#### macOS Issues

**Permission denied errors:**
```bash
# Fix Python/pip permissions
sudo chown -R $(whoami) $(python3 -m site --user-base)

# Reinstall Edge TTS
pip3 install --user edge-tts
```

**Network access issues:**
```bash
# Check system preferences
# System Preferences -> Security & Privacy -> Privacy -> Full Disk Access
# Add your Flutter app to the list
```

#### Linux Issues

**Audio system problems:**
```bash
# Check audio system
pulseaudio --check -v

# Restart audio service
systemctl --user restart pulseaudio

# Install missing dependencies
sudo apt install libasound2-dev libpulse-dev
```

**Permission issues:**
```bash
# Add user to audio group
sudo usermod -a -G audio $USER

# Logout and login again
```

#### Android Issues

**TTS not working:**
- Check system TTS settings
- Install Google Text-to-Speech from Play Store
- Verify language packs are downloaded

**Network connectivity:**
- Check app permissions
- Verify server accessibility from mobile network
- Consider firewall rules on server

#### iOS Issues

**Speech synthesis fails:**
- Check device language settings
- Verify iOS version compatibility (iOS 11+)
- Test with different voices

**Network requests failing:**
- Check App Transport Security settings
- Verify server certificate (for HTTPS)
- Test with cellular and WiFi separately

#### Web Issues

**Speech API not available:**
- Check browser compatibility
- Verify HTTPS (required for Web Speech API)
- Test in different browsers

**CORS errors:**
- Configure server CORS headers
- Use proxy for development
- Check browser console for specific errors

### Debug Mode

Enable comprehensive logging:

```dart
// Enable debug logging
void main() async {
  // Set logging level
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  
  // Initialize with debug configuration
  await ServiceManager.initialize(
    ServiceConfiguration.combined.copyWith(
      verboseLogging: true,
    ),
  );
  
  runApp(MyApp());
}
```

### Performance Monitoring

```dart
// Monitor service performance
class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};
  
  static void startTimer(String operation) {
    _timers[operation] = Stopwatch()..start();
  }
  
  static void endTimer(String operation) {
    final timer = _timers[operation];
    if (timer != null) {
      timer.stop();
      print('$operation took ${timer.elapsedMilliseconds}ms');
      _timers.remove(operation);
    }
  }
}

// Usage
PerformanceMonitor.startTimer('translation');
final result = await translationService.translateText(...);
PerformanceMonitor.endTimer('translation');
```

This platform guide provides comprehensive coverage of platform-specific configurations, optimizations, and troubleshooting strategies for the Alouette ecosystem. Refer to individual library documentation for more detailed technical specifications.