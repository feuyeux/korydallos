# Alouette

A comprehensive Flutter ecosystem for AI-powered translation and text-to-speech functionality, built with a modular architecture that eliminates code duplication and follows Flutter best practices.

## 🏗️ Architecture Overview

Alouette follows a layered architecture with clear separation of concerns:

```
Applications Layer
├── alouette-app (Combined functionality)
├── alouette-app-trans (Translation specialist)
└── alouette-app-tts (TTS specialist)

Library Layer
├── alouette-lib-trans (Translation services)
├── alouette-lib-tts (TTS services)
└── alouette-ui-shared (UI components & services)

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

### alouette-app
**Combined Translation & TTS Application**
- Full-featured application with both translation and TTS capabilities
- Unified interface for seamless workflow between translation and speech synthesis
- Ideal for users who need both functionalities

### alouette-app-trans  
**Specialized Translation Application**
- Focused on AI-powered translation using local LLM providers
- Supports Ollama and LM Studio for privacy-focused translation
- Batch translation to multiple languages simultaneously

### alouette-app-tts
**Specialized Text-to-Speech Application**
- High-quality speech synthesis with platform-specific optimization
- Edge TTS for desktop platforms, Flutter TTS for mobile/web
- Advanced voice controls and audio export capabilities

## 📚 Libraries

### alouette-lib-trans
**Translation Services Library**
- Centralized AI translation functionality
- Support for multiple LLM providers (Ollama, LM Studio)
- Comprehensive error handling and connection management
- Unified API for all translation operations

### alouette-lib-tts
**Text-to-Speech Services Library**
- Multi-platform TTS with automatic engine selection
- Edge TTS integration for high-quality desktop synthesis
- Flutter TTS for native mobile and web support
- Cross-platform audio playback and file generation

### alouette-ui-shared
**Shared UI Components & Services Library**
- Atomic design component system (atoms, molecules, organisms)
- Centralized service locator and dependency injection
- Design token system for consistent theming
- Configuration management and theme switching

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

```bash
# Run the main combined application
cd alouette-app && flutter run

# Run the translation-focused application  
cd alouette-app-trans && flutter run

# Run the TTS-focused application
cd alouette-app-tts && flutter run
```

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

## 🔧 Development

### Project Structure

```
alouette/
├── alouette-app/              # Main combined application
├── alouette-app-trans/        # Translation specialist app
├── alouette-app-tts/          # TTS specialist app
├── alouette-lib-trans/        # Translation services library
├── alouette-lib-tts/          # TTS services library
├── alouette-ui-shared/        # Shared UI components library
├── .kiro/                     # Kiro IDE configuration
│   └── specs/                 # Architecture specifications
└── docs/                      # Additional documentation
```

### Development Workflow

1. **Library Development**: Implement core functionality in libraries first
2. **Application Integration**: Applications consume library services
3. **UI Components**: Use shared components from alouette-ui-shared
4. **Testing**: Test libraries independently, then integration testing
5. **Documentation**: Update documentation for any API changes

### Key Design Patterns

- **Service Locator**: Centralized dependency management
- **Strategy Pattern**: Platform-specific TTS engine selection
- **Observer Pattern**: Reactive configuration updates
- **Factory Pattern**: Service and component creation
- **Atomic Design**: Hierarchical UI component organization

## 🧪 Testing

### Running Tests

```bash
# Test all libraries
find . -name "test" -type d -not -path "./.*" -exec dirname {} \; | xargs -I {} sh -c 'cd "{}" && flutter test'

# Test specific library
cd alouette-lib-trans && flutter test
cd alouette-lib-tts && flutter test
cd alouette-ui-shared && flutter test
```

### Test Coverage

- **Unit Tests**: Core library functionality
- **Widget Tests**: UI component behavior
- **Integration Tests**: Cross-library interactions
- **Platform Tests**: Platform-specific functionality

## 📖 Documentation

### Library Documentation
- [Translation Library](alouette-lib-trans/README.md) - AI translation services
- [TTS Library](alouette-lib-tts/README.md) - Text-to-speech services  
- [UI Shared Library](alouette-ui-shared/README.md) - UI components and services

### Application Documentation
- [Main App](alouette-app/README.md) - Combined functionality
- [Translation App](alouette-app-trans/README.md) - Translation specialist
- [TTS App](alouette-app-tts/README.md) - TTS specialist

### Architecture Documentation
- [Migration Guide](MIGRATION_GUIDE.md) - Upgrading from legacy architecture
- [API Documentation](API_DOCUMENTATION.md) - Complete API reference
- [Platform Guide](PLATFORM_GUIDE.md) - Platform-specific behavior

## 🔄 Migration from Legacy Architecture

If you're upgrading from the previous architecture, see the [Migration Guide](MIGRATION_GUIDE.md) for detailed instructions on:

- Updating import statements
- Migrating to new service APIs
- Using the service locator pattern
- Adopting shared UI components
- Configuration management changes

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow the architecture principles and naming conventions
4. Add tests for new functionality
5. Update documentation as needed
6. Commit changes (`git commit -m 'Add amazing feature'`)
7. Push to branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

### Development Guidelines

- Follow Flutter naming conventions (snake_case files, PascalCase classes)
- Implement features in libraries first, then consume in applications
- Use the service locator for dependency management
- Follow atomic design principles for UI components
- Add comprehensive tests and documentation

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev) - Cross-platform UI framework
- [Edge TTS](https://github.com/rany2/edge-tts) - High-quality text-to-speech
- [Ollama](https://ollama.ai) - Local LLM runtime
- [LM Studio](https://lmstudio.ai) - Local LLM interface
- [Material Design 3](https://m3.material.io/) - Design system