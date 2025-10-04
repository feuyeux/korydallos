# Alouette Project - AI Coding Agent Instructions

每次执行命令前，不要直接执行命令，一定要确认是否处在正确的目录下。

## Project Overview

Alouette is a Flutter-based multilingual translation and text-to-speech (TTS) ecosystem with a modular, library-first architecture. The project consists of **3 Flutter apps** that share functionality from **3 specialized libraries**, eliminating code duplication while enabling both combined and specialized use cases.

**Key Applications:**
- `alouette_app` - Combined translation + TTS functionality
- `alouette_app_trans` - Translation-only specialist app
- `alouette_app_tts` - TTS-only specialist app

**Core Libraries:**
- `alouette_lib_trans` - AI translation via local LLMs (Ollama, LM Studio)
- `alouette_lib_tts` - Multi-platform TTS (Edge TTS for desktop, Flutter TTS for mobile/web)
- `alouette_ui` - Shared UI components, design tokens, and service orchestration

## Architecture Principles

### 1. Library-First Design
**All business logic lives in libraries.** Applications are thin consumers that initialize services and compose UI from shared components. Never duplicate logic across apps.

### 2. Service Locator Pattern (Dependency Injection)
All services use centralized DI via `ServiceLocator` (from `alouette_ui`):

```dart
// In main.dart - ALWAYS initialize this way:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  ServiceLocator.initialize();  // Register core services
  await ServiceManager.initialize(ServiceConfiguration.combined); // Initialize app services
  
  runApp(const MyApp());
}

// Access services anywhere (two ways):
// Method 1: Via ServiceManager (recommended)
final ttsService = ServiceManager.getTTSService();
final translationService = ServiceManager.getTranslationService();

// Method 2: Direct from ServiceLocator (advanced)
final ttsService = ServiceLocator.get<TTSService>();
final translationService = ServiceLocator.get<TranslationService>();
```

**Critical:** Services MUST be initialized through `ServiceManager` before use. Each app type uses different `ServiceConfiguration`:
- `ServiceConfiguration.combined` - Both TTS and translation
- `ServiceConfiguration.ttsOnly` - TTS apps
- `ServiceConfiguration.translationOnly` - Translation apps

### 3. Atomic Design Component System
UI components in `alouette_ui` follow strict hierarchy:
- **Atoms** (`src/components/atoms/`) - Basic elements: `AlouetteButton`, `AlouetteTextField`, `AlouetteSlider`
- **Molecules** (`src/components/molecules/`) - Composite: `LanguageSelector`, `VoiceSelector`, `StatusIndicator`
- **Organisms** (`src/components/organisms/`) - Complete features: `TranslationPanel`, `TTSControlPanel`, `ConfigDialog`

**Rule:** Build UIs by composing these components. Never create custom buttons/inputs when atomic equivalents exist.

### 4. Design Tokens Over Hardcoded Values
All styling uses the token system from `alouette_ui/src/tokens/`:

```dart
// Colors
Container(color: ColorTokens.primary)
Text('Message', style: TextStyle(color: ColorTokens.success))

// Spacing
Padding(padding: EdgeInsets.all(SpacingTokens.l))
SizedBox(height: SpacingTokens.m)

// Typography
Text('Title', style: TypographyTokens.headlineMediumStyle)

// Motion
AnimatedContainer(duration: MotionTokens.normal, curve: MotionTokens.standard)
```

Never use hardcoded colors (`Colors.blue`), sizes (`16.0`), or Material widgets without checking tokens first.

## Critical File Locations

### Service Initialization
- **App entry points:** `alouette_app*/lib/main.dart` - Contains `_setupServices()` pattern for each app type
- **Service orchestration:** `alouette_ui/lib/src/services/core/service_manager.dart` - Manages service lifecycle
- **Service locator:** `alouette_ui/lib/src/services/core/service_locator.dart` - DI container

### Core Service Implementations
- **TTS service:** `alouette_ui/lib/src/services/tts_service.dart` - Unified TTS service
- **Translation service:** `alouette_ui/lib/src/services/translation_service.dart` - Unified translation service
- **Underlying libraries:** 
  - `alouette_lib_tts/lib/src/core/tts_service.dart` - Core TTS engine
  - `alouette_lib_trans/lib/src/core/translation_service.dart` - Core translation engine

### Component Exports
- **Main export:** `alouette_ui/lib/alouette_ui.dart` - Barrel file for all shared resources
- **Atomic components:** `alouette_ui/lib/src/components/{atoms,molecules,organisms}/`

## Developer Workflows

### Running Apps

Each app has convenience scripts:

```bash
# macOS/Linux
cd alouette_app && ./run_app.sh          # Main app (default: macOS)
cd alouette_app_trans && ./run_app.sh    # Translation app
cd alouette_app_tts && ./run_app.sh      # TTS app

# Or manually specify platform:
flutter run -d macos    # Desktop
flutter run -d chrome   # Web
flutter run -d android  # Mobile
```

### App Initialization Pattern

All apps use async initialization with splash screen:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize only core services (non-blocking)
  ServiceLocator.initialize();
  
  // Run app immediately - services initialize asynchronously
  runApp(const MyAppWrapper());
}

class MyAppWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder<bool>(
        future: _initializeServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen(message: 'Initializing...');
          }
          if (snapshot.hasError || snapshot.data == false) {
            return InitializationErrorScreen(
              error: snapshot.error,
              onRetry: () => (context as Element).markNeedsBuild(),
            );
          }
          return const MyApp();
        },
      ),
    );
  }
}
```

### Installing Dependencies

**After any pubspec.yaml change:**
```bash
# Install for all packages (from repo root):
find . -name "pubspec.yaml" -not -path "./.*" -exec dirname {} \; | xargs -I {} sh -c 'cd "{}" && flutter pub get'

# Or per-package:
cd alouette_lib_trans && flutter pub get
```

### Testing (Note: Test files currently minimal/removed)

The project historically had mock-based tests that were removed. Real integration tests require:

```bash
# For translation tests - MUST have Ollama running:
ollama serve                 # Start server (port 11434)
ollama pull llama3.2        # Download model
cd alouette_lib_trans && flutter test

# For TTS tests - MUST have edge-tts installed:
pip install edge-tts
cd alouette_lib_tts && flutter test
```

## Integration Points & External Dependencies

### LLM Providers (Translation)
**Ollama** (default) and **LM Studio** provide local AI translation. Configuration via `LLMConfig`:

```dart
final config = LLMConfig(
  provider: 'ollama',          // or 'lmstudio'
  serverUrl: 'http://localhost:11434',  // Ollama default
  selectedModel: 'llama3.2',
);
```

**Ollama Setup:**
```bash
ollama serve
ollama pull llama3.2  # or llama3.1, qwen, mistral, etc.

# For external access (Linux):
sudo systemctl edit ollama --full  # Set OLLAMA_HOST=0.0.0.0:11434
```

**Key Files:**
- Provider implementations: `alouette_lib_trans/lib/src/providers/{ollama_provider.dart,lm_studio_provider.dart}`
- Connection testing: `alouette_lib_trans/lib/src/core/llm_config_service.dart`

### TTS Engines (Platform-Specific)

**Desktop (Windows/macOS/Linux):** Edge TTS (Microsoft neural voices)
```bash
pip install edge-tts  # Required for desktop
```

**Mobile/Web:** Flutter TTS (system voices)

**Engine selection is automatic** via `PlatformTTSFactory` in `alouette_lib_tts`. The `TTSService` abstracts this:

```dart
final ttsService = TTSService();
await ttsService.initialize();  // Auto-selects best engine for platform
```

**Key Files:**
- Factory: `alouette_lib_tts/lib/src/core/tts_engine_factory.dart`
- Edge TTS processor: `alouette_lib_tts/lib/src/engines/edge_tts_processor.dart`
- Flutter TTS processor: `alouette_lib_tts/lib/src/engines/flutter_tts_processor.dart`

## Project-Specific Conventions

### Naming Conventions
- **Files:** `snake_case` (Flutter standard): `translation_service.dart`, `llm_config_dialog.dart`
- **Classes:** `PascalCase`: `TranslationService`, `TTSControlPanel`
- **Private members:** Leading underscore: `_serviceStatus`, `_initializeServices()`

### Error Handling Pattern
All libraries define custom exceptions with recovery suggestions:

```dart
// Translation exceptions
try {
  await translationService.translateText(...);
} on LLMConnectionException catch (e) {
  // Network issues - suggest checking server URL
} on LLMModelNotFoundException catch (e) {
  // Model not found - suggest downloading model
}

// TTS exceptions
try {
  await ttsService.synthesizeText(...);
} on TTSError catch (e) {
  print('Code: ${e.code}, Message: ${e.message}');
}
```

**Key:** Exceptions are defined in `lib/src/exceptions/` directories. Check these for specific error types.

### State Management
Services extend `ChangeNotifier` for reactive updates:

```dart
class TranslationService extends ChangeNotifier {
  // Updates notify listeners automatically
  void updateStatus() {
    notifyListeners();
  }
}

// In widgets:
widget.translationService.addListener(_onTranslationChanged);
```

### Logging (via ServiceLocator)
```dart
final logger = ServiceLocator.logger;
logger.info('Message', tag: 'FeatureName');
logger.debug('Details', tag: 'FeatureName', details: {'key': 'value'});
logger.error('Error', tag: 'FeatureName', error: e, stackTrace: st);
```

## Common Pitfalls

1. **Forgetting Service Initialization:** Apps crash if services aren't initialized. Always check initialization in `main()`.

2. **Using Wrong ServiceConfiguration:** TTS-only apps must use `ServiceConfiguration.ttsOnly`, not `.combined`. Match config to app type.

3. **Bypassing Atomic Components:** Don't create custom `ElevatedButton` when `AlouetteButton` exists. Check `alouette_ui/lib/src/components/` first.

4. **Hardcoding Styles:** Using `Colors.blue` or `16.0` breaks theming. Always use design tokens: `ColorTokens.primary`, `SpacingTokens.m`.

5. **Missing External Dependencies:** Desktop TTS requires `pip install edge-tts`. Translation requires Ollama/LM Studio running. Document setup in errors.

6. **Path Issues (Desktop):** macOS Edge TTS needs Homebrew in PATH. Check `run_app.sh` for `export PATH="/opt/homebrew/bin:$PATH"` pattern.

7. **Synchronous Initialization:** Never block `main()` with long-running initialization. Use `FutureBuilder` for async service loading.

8. **Error Handling:** Always use the unified `ErrorHandler` class for consistent error messages and logging:
   ```dart
   try {
     await operation();
   } on TranslationError catch (e) {
     ErrorHandler.handle(e, context: context);
   } catch (e, stackTrace) {
     ErrorHandler.handle(e, context: context, stackTrace: stackTrace);
   }
   ```

## When Adding New Features

1. **Determine Layer:**
   - Core logic → Add to `alouette_lib_trans` or `alouette_lib_tts`
   - UI component → Add to `alouette_ui` atomic hierarchy (atom/molecule/organism)
   - App-specific → Only if truly unique to one app (rare)

2. **Update Exports:** Add to barrel files:
   - `alouette_lib_trans/lib/alouette_lib_trans.dart`
   - `alouette_lib_tts/lib/alouette_tts.dart`
   - `alouette_ui/lib/alouette_ui.dart`

3. **Follow Patterns:** Find similar existing code and match its structure (e.g., new TTS engine → copy `edge_tts_processor.dart` structure).

4. **Test Integration:** Ensure all 3 apps still build (`cd alouette_app* && flutter build macos --debug`).

## Key Design Decisions

- **Why Service Locator?** Enables testing with mock services, loose coupling, and centralized lifecycle management vs. direct instantiation.
- **Why Atomic Design?** Prevents UI fragmentation across 3 apps. Single source of truth for components.
- **Why Library-First?** Eliminates code duplication. Apps are composition layers, not implementation layers.
- **Why Local LLMs?** Privacy-focused translation without cloud dependencies. Users control their data.
- **Why Platform-Specific TTS?** Desktop neural voices (Edge TTS) are higher quality than system TTS. Mobile/web use system for native integration.

## Recent Updates

- **2025-10-04**: Project cleanup - removed deprecated code, build artifacts, and IDE configurations
- **2025-10-03**: Simplified service architecture - direct use of library services instead of interface pattern
