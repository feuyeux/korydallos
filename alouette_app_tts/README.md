# Alouette TTS App

A Flutter application for high-quality text-to-speech functionality using Microsoft Edge TTS.

## ✨ Features

- 🌍 **Multilingual Support**: 12 languages with neural voices
- 🎯 **Edge TTS Integration**: High-quality Microsoft Edge TTS engine
- 🎨 **Modern UI**: Clean and intuitive user interface
- 🔄 **Real-time Synthesis**: Fast text-to-speech conversion
- 📱 **Cross-platform**: Supports Windows, macOS, and Linux

## 🌐 Supported Languages

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
11. 🇯🇵 Japanese (ja-JP): これは日本語音声合成技術のデモンストレーションです。
12. 🇰🇷 Korean (ko-KR): 이것은 한국어 음성 합성 기술의 시연입니다。

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.0+
- Dart SDK 3.0+
- Python 3.7+ (for Edge TTS)
- Edge TTS package: `pip install edge-tts`

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/feuyeux/alouette.git
   cd alouette/alouette-app-tts
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Install Edge TTS**
   ```bash
   pip install edge-tts
   ```

4. **Run the application**
   ```bash
   # For Windows
   flutter run -d windows
   
   # For macOS
   flutter run -d macos
   
   # For Linux
   flutter run -d linux
   ```

## 🏗️ Architecture

The application is built with a modular architecture:

- **alouette-app-tts**: Main Flutter application
- **alouette-lib-tts**: Core TTS library with unified API
- **Edge TTS Processor**: Microsoft Edge TTS integration
- **Flutter TTS Processor**: System TTS fallback (mobile platforms)

## 📱 Usage

1. **Launch the app**: The application will automatically initialize the TTS service
2. **Enter text**: Type or paste the text you want to convert to speech
3. **Select voice**: Choose from available voices in the dropdown
4. **Play**: Click the play button to hear the synthesized speech
5. **Switch engines**: Use the dropdown in the header to switch between TTS engines

## 🛠️ Development

### Project Structure

```
alouette-app-tts/
├── lib/
│   ├── main.dart              # Application entry point
│   └── pages/
│       └── home_page.dart     # Main TTS interface
├── windows/                   # Windows platform files
├── macos/                     # macOS platform files
├── linux/                     # Linux platform files
└── pubspec.yaml              # Dependencies and configuration
```

### Dependencies

- **alouette_lib_tts**: Core TTS functionality
- **flutter_tts**: System TTS integration
- **cupertino_icons**: iOS-style icons

## 🔧 Configuration

The app automatically configures itself based on the platform:

- **Desktop platforms**: Uses Edge TTS as the primary engine
- **Mobile platforms**: Uses Flutter TTS with system voices
- **Web platforms**: Uses Web Speech API through Flutter TTS

## 🐛 Troubleshooting

### Common Issues

1. **"Edge TTS not available"**
   - Ensure Python is installed and in PATH
   - Install edge-tts: `pip install edge-tts`
   - Verify installation: `edge-tts --list-voices`

2. **"No voices available"**
   - Check internet connection (Edge TTS requires online access)
   - Verify Edge TTS installation
   - Try switching to Flutter TTS engine

3. **Audio playback issues**
   - Ensure system audio is working
   - Check volume settings
   - Try different audio formats

### Debug Mode

Run with verbose logging:
```bash
flutter run -d windows --verbose
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📞 Support

For issues and questions:
- Create an issue on GitHub
- Check the troubleshooting section above
- Review the Edge TTS documentation