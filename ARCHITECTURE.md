# Alouette 项目架构规范文档

## 📋 目录结构标准

### 1. 应用层结构 (alouette_app, alouette_app_trans, alouette_app_tts)

所有三个应用遵循统一的目录结构：

```
alouette_app*/
├── lib/
│   ├── main.dart                    # 应用入口（统一使用 AppInitializationWrapper）
│   ├── app/                         # 应用级配置
│   │   ├── alouette_app.dart        # 主应用 Widget
│   │   └── app_router.dart          # 路由配置
│   ├── config/                      # 应用特定配置
│   │   └── app_config.dart
│   └── features/                    # 功能模块（按功能组织）
│       ├── home/                    # 首页功能（仅 alouette_app）
│       │   ├── pages/
│       │   │   └── home_page.dart
│       │   └── controllers/
│       │       └── home_controller.dart
│       ├── translation/             # 翻译功能
│       │   ├── pages/
│       │   │   ├── translation_home_page.dart
│       │   │   └── translation_settings_page.dart
│       │   ├── widgets/             # 功能特定组件
│       │   │   └── translation_specific_widgets.dart
│       │   └── controllers/
│       │       └── translation_controller.dart
│       ├── tts/                     # TTS 功能
│       │   ├── pages/
│       │   │   ├── tts_home_page.dart
│       │   │   └── tts_settings_page.dart
│       │   ├── widgets/             # 功能特定组件
│       │   │   ├── tts_input_section.dart
│       │   │   ├── tts_control_section.dart
│       │   │   └── tts_status_section.dart
│       │   └── controllers/
│       │       └── tts_controller.dart
│       └── settings/                # 设置功能
│           ├── pages/
│           │   └── settings_page.dart
│           └── controllers/
│               └── settings_controller.dart
├── android/
├── ios/
├── macos/
├── linux/
├── windows/
├── web/
└── pubspec.yaml
```

### 2. UI 库结构 (alouette_ui)

共享 UI 组件和服务的库：

```
alouette_ui/
├── lib/
│   ├── alouette_ui.dart             # Barrel export 文件
│   └── src/
│       ├── core/                    # 核心功能
│       │   ├── app_initialization.dart  # 统一初始化逻辑 ✨
│       │   └── errors/
│       │       ├── alouette_error.dart
│       │       └── error_handler.dart
│       ├── services/                # 服务层
│       │   ├── core/
│       │   │   ├── service_locator.dart
│       │   │   ├── service_manager.dart
│       │   │   ├── service_configuration.dart
│       │   │   ├── service_health_monitor.dart
│       │   │   ├── configuration_manager.dart
│       │   │   └── logging_service.dart
│       │   ├── interfaces/
│       │   │   ├── tts_service_contract.dart
│       │   │   └── translation_service_contract.dart
│       │   ├── implementations/
│       │   │   ├── tts_service_impl.dart
│       │   │   └── translation_service_impl.dart
│       │   └── theme_service.dart
│       ├── components/              # Atomic Design 组件
│       │   ├── atoms/               # 基础组件
│       │   ├── molecules/           # 组合组件
│       │   └── organisms/           # 复杂组件
│       ├── widgets/                 # 通用 Widgets
│       │   ├── splash_screen.dart
│       │   ├── custom_app_bar.dart
│       │   ├── custom_button.dart
│       │   ├── custom_card.dart
│       │   ├── custom_text_field.dart
│       │   ├── custom_dropdown.dart
│       │   ├── config_status_widget.dart
│       │   ├── tts_status_card.dart
│       │   ├── translation_input_widget.dart
│       │   └── translation_result_widget.dart
│       ├── dialogs/                 # 对话框
│       │   ├── llm_config_dialog.dart
│       │   └── tts_config_dialog.dart
│       ├── tokens/                  # Design Tokens
│       │   ├── color_tokens.dart
│       │   ├── dimension_tokens.dart
│       │   ├── typography_tokens.dart
│       │   ├── motion_tokens.dart
│       │   ├── elevation_tokens.dart
│       │   └── effect_tokens.dart
│       ├── themes/                  # 主题
│       │   └── app_theme.dart
│       ├── constants/               # 常量
│       │   ├── ui_constants.dart
│       │   └── language_constants.dart
│       ├── models/                  # 数据模型
│       │   ├── app_configuration.dart
│       │   └── unified_error.dart
│       ├── state/                   # 状态管理
│       │   └── controllers/
│       └── utils/                   # 工具函数
│           ├── validation_utils.dart
│           ├── error_handler.dart
│           └── ui_utils.dart
└── pubspec.yaml
```

### 3. 业务库结构

#### alouette_lib_trans (翻译库)

```
alouette_lib_trans/
├── lib/
│   ├── alouette_lib_trans.dart      # Barrel export
│   └── src/
│       ├── core/
│       │   ├── translation_service.dart
│       │   └── llm_config_service.dart
│       ├── providers/
│       │   ├── ollama_provider.dart
│       │   └── lm_studio_provider.dart
│       ├── models/
│       │   └── llm_config.dart
│       └── exceptions/
│           └── translation_exceptions.dart
└── pubspec.yaml
```

#### alouette_lib_tts (TTS 库)

```
alouette_lib_tts/
├── lib/
│   ├── alouette_tts.dart            # Barrel export
│   └── src/
│       ├── core/
│       │   ├── tts_service.dart
│       │   └── tts_engine_factory.dart
│       ├── engines/
│       │   ├── edge_tts_processor.dart
│       │   └── flutter_tts_processor.dart
│       ├── models/
│       │   └── voice_model.dart
│       └── exceptions/
│           └── tts_exceptions.dart
└── pubspec.yaml
```

## 🎯 命名规范

### 文件命名

- 所有文件使用 `snake_case.dart`
- 测试文件使用 `*_test.dart`
- 页面文件使用 `*_page.dart`
- 控制器文件使用 `*_controller.dart`
- Widget 文件使用 `*_widget.dart` 或功能描述名称

### 类命名

- 所有类使用 `PascalCase`
- Widget 类以功能命名，如 `CustomButton`, `TranslationPage`
- Service 类以 `*Service` 结尾，如 `TranslationService`, `TTSService`
- Controller 类以 `*Controller` 结尾，如 `HomeController`, `TranslationController`
- Model 类使用描述性名称，如 `LLMConfig`, `VoiceModel`

### 变量命名

- 公共变量使用 `camelCase`
- 私有变量使用 `_camelCase`
- 常量使用 `camelCase` 或 `SCREAMING_SNAKE_CASE`（全局常量）

### 组件前缀

- 共享 UI 组件：`Custom*` 或 `Alouette*`
- 功能特定组件：`Translation*`, `TTS*`, `Home*`
- 原子组件：`Atomic*`

## 🏗️ 架构原则

### 1. Library-First Design

- **所有业务逻辑存放在库中**
- 应用层只做 UI 组装和配置
- 避免在应用层重复实现逻辑

### 2. Service Locator Pattern (依赖注入)

```dart
// 初始化（在 main.dart）
ServiceLocator.initialize();

// 使用服务（推荐方式）
final ttsService = ServiceManager.getTTSService();
final translationService = ServiceManager.getTranslationService();

// 或直接从 ServiceLocator 获取
final logger = ServiceLocator.logger;
```

### 3. 统一的应用初始化

**所有应用使用统一的初始化包装器：**

```dart
// alouette_app/lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ServiceLocator.initialize();

  runApp(
    AppInitializationWrapper(
      title: 'Alouette',
      splashMessage: 'Initializing services...',
      initializer: CombinedAppInitializer(),  // 组合应用
      app: const AlouetteApp(),
    ),
  );
}

// alouette_app_trans/lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ServiceLocator.initialize();

  runApp(
    AppInitializationWrapper(
      title: 'Alouette Translator',
      splashMessage: 'Initializing translation service...',
      initializer: TranslationAppInitializer(),  // 翻译专用
      app: const TranslationApp(),
    ),
  );
}

// alouette_app_tts/lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ServiceLocator.initialize();

  runApp(
    AppInitializationWrapper(
      title: 'Alouette TTS',
      splashMessage: 'Initializing text-to-speech...',
      initializer: TTSAppInitializer(),  // TTS 专用
      app: const TTSApp(),
    ),
  );
}
```

**初始化器类型：**

- `CombinedAppInitializer` - 同时初始化 TTS 和 Translation
- `TranslationAppInitializer` - 只初始化 Translation（允许超时）
- `TTSAppInitializer` - 只初始化 TTS（必须成功）

### 4. Atomic Design 组件系统

```
Atoms (原子) → Molecules (分子) → Organisms (有机体)
     ↓              ↓                    ↓
  基础元素      组合元素            完整功能模块
```

### 5. Design Tokens 优先

```dart
// ✅ 使用 Design Tokens
Container(color: ColorTokens.primary)
Padding(padding: EdgeInsets.all(SpacingTokens.l))
Text('Title', style: TypographyTokens.headlineMediumStyle)

// ❌ 避免硬编码
Container(color: Colors.blue)
Padding(padding: EdgeInsets.all(16.0))
Text('Title', style: TextStyle(fontSize: 24))
```

## 🔧 服务配置

### ServiceConfiguration 类型

```dart
// 组合应用配置
ServiceConfiguration.combined
  - initializeTTS: true
  - initializeTranslation: true
  - TTS 超时: 15秒（必须成功）
  - Translation 超时: 6秒（允许失败）

// 翻译专用配置
ServiceConfiguration.translationOnly
  - initializeTTS: false
  - initializeTranslation: true
  - Translation 超时: 6秒（允许失败，可手动配置）

// TTS 专用配置
ServiceConfiguration.ttsOnly
  - initializeTTS: true
  - initializeTranslation: false
  - TTS 超时: 15秒（必须成功）
```

## 📦 依赖关系

```
alouette_app          ┐
alouette_app_trans    ├─→ alouette_ui ─→ alouette_lib_trans
alouette_app_tts      ┘              └─→ alouette_lib_tts
```

## 🚀 最佳实践

### 1. 创建新功能

```
1. 确定功能属于哪一层：
   - 核心逻辑 → alouette_lib_trans 或 alouette_lib_tts
   - UI 组件 → alouette_ui (atoms/molecules/organisms)
   - 应用特定 → alouette_app*/features/

2. 在对应层创建文件

3. 更新 barrel exports:
   - alouette_lib_trans/lib/alouette_lib_trans.dart
   - alouette_lib_tts/lib/alouette_tts.dart
   - alouette_ui/lib/alouette_ui.dart

4. 测试集成
```

### 2. 添加新页面

```
features/
  └── <feature_name>/
      ├── pages/
      │   └── <feature_name>_page.dart
      ├── widgets/              # 可选
      │   └── <specific_widgets>.dart
      └── controllers/          # 可选
          └── <feature_name>_controller.dart
```

### 3. 错误处理

```dart
// 统一使用 ErrorHandler
try {
  await operation();
} on TranslationError catch (e) {
  ErrorHandler.handle(e, context: context);
} catch (e, stackTrace) {
  ErrorHandler.handle(e, context: context, stackTrace: stackTrace);
}
```

### 4. 日志记录

```dart
final logger = ServiceLocator.logger;
logger.info('Message', tag: 'FeatureName');
logger.debug('Details', tag: 'FeatureName', details: {'key': 'value'});
logger.error('Error', tag: 'FeatureName', error: e, stackTrace: st);
```

## 📝 常见陷阱

1. **不要在应用层重复实现服务逻辑** - 使用 ServiceManager
2. **不要硬编码样式** - 使用 Design Tokens
3. **不要创建自定义基础组件** - 检查 alouette_ui/components
4. **不要忘记初始化服务** - 使用 AppInitializationWrapper
5. **不要阻塞 main()** - 使用异步初始化
6. **不要使用已弃用的接口** - 避免 `ITranslationService`, `ITTSService`

## 🎯 下一步优化建议

1. **自动化测试** - 为每个库和应用添加单元测试和集成测试
2. **CI/CD** - 设置持续集成和部署流程
3. **文档生成** - 使用 dartdoc 生成 API 文档
4. **性能监控** - 添加性能追踪和分析
5. **国际化** - 添加多语言支持
6. **主题系统** - 扩展设计令牌支持多主题

## 📚 参考资源

- [Flutter 架构指南](https://flutter.dev/docs/development/data-and-backend/state-mgmt/intro)
- [Atomic Design](https://bradfrost.com/blog/post/atomic-web-design/)
- [Service Locator Pattern](https://en.wikipedia.org/wiki/Service_locator_pattern)
- [Design Tokens](https://css-tricks.com/what-are-design-tokens/)

---

**最后更新**: 2025 年 10 月 3 日
**版本**: 1.0.0
**维护者**: Alouette Team
