# Alouette TTS

<div align="center">
  <img src="alouette_big.png" alt="Alouette TTS Logo" width="200"/>
  
  **Alouette TTS - Cross-platform Text-to-Speech Application**
  
  *A beautiful, powerful Flutter-based TTS application that supports multiple platforms*
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.8.1-blue)](https://flutter.dev)
  [![Platforms](https://img.shields.io/badge/Platforms-Android%20|%20iOS%20|%20Web%20|%20Windows%20|%20macOS%20|%20Linux-green)](#supported-platforms)
  [![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)
</div>

## 📖 简介 / Introduction

Alouette TTS 是一个跨平台的文本转语音应用程序，基于 Flutter 开发，支持多种语言和语音效果调节。应用提供直观的用户界面，让用户能够轻松地将文本转换为语音。

Alouette TTS is a cross-platform text-to-speech application built with Flutter, supporting multiple languages and voice effect adjustments. It provides an intuitive user interface for users to easily convert text to speech.

## ✨ 特性 / Features

- 🌍 **多语言支持** - 支持中文、英文、日文、韩文等多种语言
- 🎛️ **语音控制** - 调节语速、音量、音调等参数
- 📱 **跨平台** - 支持 Android、iOS、Web、Windows、macOS、Linux
- 🎨 **现代化UI** - Material 3 设计，响应式布局
- 🔊 **实时控制** - 播放、暂停、停止语音合成
- ♿ **无障碍支持** - 支持屏幕阅读器和键盘导航
- 📂 **文件读取** - 支持从文件读取文本内容

### Multi-language Support
- 🇨🇳 Chinese (Simplified & Traditional)
- 🇺🇸 English (US & UK)
- 🇯🇵 Japanese
- 🇰🇷 Korean
- 🇪🇸 Spanish
- 🇫🇷 French
- 🇩🇪 German
- 🇮🇹 Italian

## 🚀 快速开始 / Quick Start

### 环境要求 / Prerequisites

- Flutter SDK 3.8.1 或更高版本
- Dart SDK 3.0.0 或更高版本
- 对应平台的开发环境

### 安装 / Installation

1. **克隆仓库 / Clone the repository**
   ```bash
   git clone https://github.com/feuyeux/alouette-tts.git
   cd alouette-tts
   ```

2. **安装依赖 / Install dependencies**
   ```bash
   flutter pub get
   ```

3. **运行应用 / Run the application**
   ```bash
   # Android
   flutter run -d android
   
   # iOS (需要 macOS)
   flutter run -d ios
   
   # Web
   flutter run -d chrome
   
   # Windows
   flutter run -d windows
   
   # macOS
   flutter run -d macos
   
   # Linux
   flutter run -d linux
   ```

## 📦 构建发布版本 / Build Release

本项目提供了自动化构建脚本，支持一键构建所有平台的发布版本。

### 使用构建脚本 / Using Build Scripts

#### macOS/Linux 用户
```bash
# 构建所有平台
./scripts/build_release.sh --all

# 构建特定平台
./scripts/build_release.sh --android-apk --ios
./scripts/build_release.sh --web --macos

# 清理后构建
./scripts/build_release.sh -c --android-apk
```

#### Windows 用户
```batch
# 构建所有平台
scripts\build_release.bat --all

# 构建特定平台
scripts\build_release.bat --android-apk --windows
```

### iOS 构建配置 / iOS Build Configuration

iOS 构建需要设置开发团队信息：

```bash
export IOS_DEVELOPMENT_TEAM=YOUR_TEAM_ID
export IOS_BUNDLE_IDENTIFIER=com.yourcompany.app
```

获取 Team ID：https://developer.apple.com/account#MembershipDetailsCard

## 🏗️ 支持的平台 / Supported Platforms

| Platform | Status | Notes |
|----------|--------|-------|
| 🤖 Android | ✅ | API 21+ (Android 5.0+) |
| 🍎 iOS | ✅ | iOS 11.0+ |
| 🌐 Web | ✅ | Chrome, Firefox, Safari |
| 🪟 Windows | ✅ | Windows 7+ |
| 🖥️ macOS | ✅ | macOS 10.14+ |
| 🐧 Linux | ✅ | 64-bit systems |

## 📁 项目结构 / Project Structure

```
lib/
├── main.dart                    # 应用入口
├── constants/                   # 常量定义
│   └── language_constants.dart  # 语言常量
├── models/                      # 数据模型
│   └── language_option.dart     # 语言选项模型
├── pages/                       # 页面
│   └── tts_home_page.dart       # 主页面
├── services/                    # 服务层
│   └── tts_service.dart         # TTS服务
├── utils/                       # 工具类
│   └── platform_utils.dart      # 平台工具
└── widgets/                     # 自定义组件
    ├── custom_app_bar.dart      # 自定义应用栏
    ├── language_selector.dart   # 语言选择器
    ├── compact_slider.dart      # 紧凑滑块
    ├── enhanced_volume_slider.dart # 增强音量滑块
    ├── tts_control_buttons.dart # TTS控制按钮
    └── tts_status_indicator.dart # TTS状态指示器
```

## 🔧 开发 / Development

### 快速运行脚本 / Quick Run Scripts

项目提供了便捷的运行脚本：

```bash
# 运行 Android
./scripts/run_android.sh

# 运行 iOS (需要 macOS)
./scripts/run_ios.sh

# 运行 Web
./scripts/run_web.sh

# 运行 macOS
./scripts/run_macos.sh

# 运行 Linux
./scripts/run_linux.sh
```

### 代码规范 / Code Style

项目使用 Flutter 官方推荐的代码规范，通过 `flutter_lints` 包进行静态分析。

运行代码检查：
```bash
flutter analyze
```

运行测试：
```bash
flutter test
```

## 🤝 贡献 / Contributing

欢迎贡献代码！请遵循以下步骤：

1. Fork 这个仓库
2. 创建你的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交你的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开一个 Pull Request

## 📄 许可证 / License

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢 / Acknowledgments

- [Flutter TTS](https://pub.dev/packages/flutter_tts) - 提供 TTS 功能支持
- [Flutter](https://flutter.dev) - 跨平台 UI 框架
- [Material Design](https://material.io/) - UI 设计规范

## 📞 联系 / Contact

如果你有任何问题或建议，请通过以下方式联系：

- 创建 [Issue](https://github.com/feuyeux/alouette-tts/issues)
- 发送邮件到项目维护者

---

<div align="center">
  Made with ❤️ using Flutter
</div>
