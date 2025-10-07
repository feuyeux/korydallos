# Alouette

A comprehensive Flutter ecosystem for AI-powered translation and text-to-speech functionality, built with a modular architecture that eliminates code duplication and follows Flutter best practices.

## 🏗️ Architecture Overview

Alouette follows a layered architecture with clear separation of concerns:

```
Applications Layer
├── alouette_app (Combined functionality)
├── alouette_app_trans (Translation specialist)
└── alouette_app_tts (TTS specialist)

Library Layer
├── alouette_lib_trans (Translation services)
├── alouette_lib_tts (TTS services)
└── alouette_ui (UI components & services)

Platform Layer
├── Edge TTS (Desktop platforms)
├── Flutter TTS (Mobile/Web platforms)
└── LLM Providers (Ollama, LM Studio)
```

## 🌐 Supported Languages

Alouette supports 12+ languages with high-quality neural voices:

1. 🇨🇳 Chinese (zh-CN): 这是中文语音合成技术的演示。
2. 🇺🇸 English (en-US): This is a demonstration of TTS in English.
3. 🇩🇪 German (de-DE): Dies ist eine Demonstration der deutschen Sprachsynthese-Technologie.
4. 🇫🇷 French (fr-FR): Ceci est une démonstration de la technologie de synthèse vocale française.
5. 🇪🇸 Spanish (es-ES): Esta es una demostración de la tecnología de síntesis de voz en español.
6. 🇮🇹 Italian (it-IT): Questa è una dimostrazione della tecnologia di sintesi vocale italiana.
7. 🇷🇺 Russian (ru-RU): Это демонстрация технологии синтеза речи на русском языке.
8. 🇬🇷 Greek (el-GR): Αυτή είναι μια επίδειξη της τεχνολογίας σύνθεσης ομιλίας στα ελληνικά.
9. 🇸🇦 Arabic (ar-SA): هذا عرض توضيحي لتقنية تحويل النص إلى كلام باللغة العربية.
10. 🇮🇳 Hindi (hi-IN): यह हिंदी भाषा में टेक्स्ट-टू-स्पीच तकनीक का प्रदर्शन है।
11. 🇯🇵 Japanese (ja-JP): これは日本語音声合成技術のデモンストレーションです।
12. 🇰🇷 Korean (ko-KR): 이것은 한국어 음성 합성 기술의 시연입니다。

## 📱 Applications

### alouette_app

**Combined Translation & TTS Application**

- Full-featured application with both translation and TTS capabilities
- Unified interface for seamless workflow between translation and speech synthesis
- Ideal for users who need both functionalities

### alouette_app_trans

**Specialized Translation Application**

- Focused on AI-powered translation using local LLM providers
- Supports Ollama and LM Studio for privacy-focused translation
- Batch translation to multiple languages simultaneously

### alouette_app_tts

**Specialized Text-to-Speech Application**

- High-quality speech synthesis with platform-specific optimization
- Edge TTS for desktop platforms, Flutter TTS for mobile/web
- Advanced voice controls and audio export capabilities

## 📚 Libraries

### alouette_lib_trans

**Translation Services Library**

- Centralized AI translation functionality
- Support for multiple LLM providers (Ollama, LM Studio)
- Comprehensive error handling and connection management

### alouette_lib_tts

**Text-to-Speech Services Library**

- Multi-platform TTS with automatic engine selection
- Edge TTS integration for high-quality desktop synthesis
- Flutter TTS for native mobile and web support

### alouette_ui

**Shared UI Components & Services Library**

- Atomic design component system (atoms, molecules, organisms)
- Centralized service locator and dependency injection
- Design token system for consistent theming
- Configuration management and service orchestration

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.8.1+
- Dart SDK 3.0.0+
- For AI translation: Ollama or LM Studio
- For desktop TTS: Python 3.7+ with `edge-tts` package

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/feuyeux/alouette.git
   cd alouette
   ```

2. **Install dependencies for all modules**

   ```bash
   # Install dependencies for all applications and libraries
   find . -name "pubspec.yaml" -not -path "./.*" -exec dirname {} \; | xargs -I {} sh -c 'cd "{}" && flutter pub get'
   ```

3. **Set up AI translation (optional)**

   ```bash
   # Install and start Ollama
   # Visit https://ollama.ai for installation instructions
   ollama serve
   ollama pull llama3.2

   # Or install LM Studio from https://lmstudio.ai
   ```

4. **Set up Edge TTS for desktop (optional)**
   ```bash
   pip install edge-tts
   ```

### Running Applications

Each application includes platform-specific run scripts for convenience:

#### **macOS/Linux**

```bash
# Run the main combined application
cd alouette_app && ./run_app.sh

# Run the translation-focused application
cd alouette_app_trans && ./run_app.sh

# Run the TTS-focused application
cd alouette_app_tts && ./run_app.sh
```

#### **Windows (PowerShell)**

```powershell
# Run any application
cd alouette_app
.\run_app.ps1

cd alouette_app_trans
.\run_app.ps1

cd alouette_app_tts
.\run_app.ps1
```

**Platform-Specific Notes:**

- **macOS**: Ensure Xcode is installed for iOS development
- **Windows**: Ensure Visual Studio with C++ tools is installed
- **Linux**: Install development packages: `sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev`
- **Android**: Use the automated setup script - see [Android Emulator Setup Guide](docs/ANDROID_EMULATOR_SETUP.md)
- **All Platforms**: Use `flutter doctor` to verify your development environment

### 🤖 Android Development

For Android development, we provide an automated setup script that configures an ARM64 emulator optimized for Apple Silicon Macs:

```bash
# Quick setup (one-time installation)
./setup_android_emulator.sh install

# Start the emulator
./setup_android_emulator.sh start

# Run your app
cd alouette_app
flutter run -d emulator-5554
```

📖 **Full documentation**: [Android Emulator Setup Guide](docs/ANDROID_EMULATOR_SETUP.md)

**Features:**
- ✅ Automatic ARM64/x86_64 architecture detection
- ✅ Optimized for Apple Silicon (M1/M2/M3) Macs
- ✅ Pre-configured with Aliyun mirrors for faster downloads in China
- ✅ Pixel 7 device profile with Google Play support
- ✅ One-command installation and startup

## 🏛️ Architecture Principles

### 1. **Separation of Concerns**

- Applications focus on user experience and workflows
- Libraries provide specialized functionality
- Clear boundaries between translation, TTS, and UI concerns

### 2. **Code Deduplication**

- Single implementation of each feature in appropriate library
- Applications consume functionality rather than reimplementing
- Shared UI components eliminate duplicate interface code

### 3. **Platform Optimization**

- Automatic selection of best TTS engine per platform
- Desktop: Edge TTS for high-quality neural voices
- Mobile/Web: Flutter TTS for native integration

### 4. **Dependency Injection**

- Service locator pattern for loose coupling
- Easy testing with mock services
- Centralized service lifecycle management

### 5. **Design Consistency**

- Design token system for unified styling
- Atomic design component hierarchy
- Consistent user experience across all applications


## Acknowledgments

- [Flutter](https://flutter.dev) - Cross-platform UI framework
- [Edge TTS](https://github.com/rany2/edge-tts) - High-quality text-to-speech
- [Ollama](https://ollama.ai) - Local LLM runtime
- [LM Studio](https://lmstudio.ai) - Local LLM interface
- [Material Design 3](https://m3.material.io/) - Design system
