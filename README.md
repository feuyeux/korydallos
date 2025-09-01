# Alouette

A collection of Flutter applications for translation and text-to-speech functionality.

## 🌐 Supported Languages

Alouette TTS supports the following 12 languages with high-quality neural voices:

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

## Sub-projects

This repository contains three sub-projects:

### 1. [alouette-app](https://github.com/feuyeux/alouette-app)
The main Flutter application that combines translation and TTS functionality.

### 2. [alouette-translator](https://github.com/feuyeux/alouette-translator)
A Flutter application focused on translation services.

### 3. [alouette-tts](https://github.com/feuyeux/alouette-tts)
A Flutter application for text-to-speech functionality.

## Getting Started

Each sub-project has its own README with specific setup instructions. To work with all projects:

```bash
# Clone the main repository with submodules
git clone --recursive https://github.com/feuyeux/alouette.git

# Or if you've already cloned, initialize submodules
git submodule update --init --recursive
```

## Development

Each sub-project is a separate Flutter application that can be developed independently:

- Navigate to the specific project directory
- Follow the setup instructions in that project's README
- Use Flutter commands as normal (`flutter run`, `flutter build`, etc.)

## Architecture

- **alouette-app**: Main application combining features from both translator and TTS
- **alouette-translator**: Specialized translation service application
- **alouette-tts**: Specialized text-to-speech application

## License

This project is licensed under the MIT License - see the individual project LICENSE files for details.
