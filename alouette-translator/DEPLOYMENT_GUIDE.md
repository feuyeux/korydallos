# Alouette Translator - 部署和使用指南

## 🎯 项目状态

✅ **核心功能完成**: 所有翻译功能已成功复刻
✅ **代码质量**: 通过静态分析，仅有调试输出警告
✅ **测试通过**: 所有单元测试和 Widget 测试通过
⚠️ **构建状态**: Web 和移动端正常，桌面端可能需要清理缓存

## 🚀 快速部署

### 1. 环境验证

```bash
# 检查Flutter环境
flutter doctor

# 确保输出显示：
# ✓ Flutter (Channel stable, 3.8.1+)
# ✓ Connected device (1 available)
```

### 2. 项目部署

```bash
# 克隆并进入项目
cd /Users/han/coding/alouette-ai/alouette-translator

# 清理并重新获取依赖
flutter clean
flutter pub get

# 运行项目（推荐先用Web测试）
flutter run -d chrome
```

### 3. AI 服务设置

#### 选项 A: Ollama（推荐）

```bash
# 安装Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# 启动服务
ollama serve

# 下载推荐模型
ollama pull llama3.2:latest
# 或者更小的模型
ollama pull llama3.2:1b
```

#### 选项 B: LM Studio

1. 访问 https://lmstudio.ai 下载安装
2. 启动 LM Studio 并下载一个模型
3. 在 Server 选项卡中启动本地服务器

## 🔧 应用配置

### 1. 启动应用

```bash
flutter run -d chrome  # Web版本（推荐测试）
flutter run -d macos   # macOS版本
flutter run -d android # Android版本
```

### 2. 配置 LLM 连接

1. 应用启动后，点击右上角的**设置按钮**（⚙️）
2. 选择 LLM 提供商：
   - **Ollama**: 选择"Ollama"
   - **LM Studio**: 选择"LM Studio"
3. 输入服务器 URL：
   - Ollama: `http://localhost:11434`
   - LM Studio: `http://localhost:1234`
   - 远程服务器: `http://your-server-ip:port`
4. 点击**"测试连接"**
5. 成功后选择一个可用模型
6. 点击**"保存"**

### 3. 开始翻译

1. 在文本框中输入要翻译的内容
2. 选择目标语言（支持多选）
3. 点击**"翻译"**按钮
4. 查看结果并使用复制功能

## 📱 平台特定说明

### Web 版本（推荐开始）

```bash
flutter run -d chrome
```

- ✅ 最稳定，无需额外配置
- ✅ 快速测试功能
- ⚠️ 需要 CORS 配置才能访问本地 LLM 服务

### macOS 版本

```bash
# 如果遇到构建问题，先清理
flutter clean
flutter pub get
flutter run -d macos
```

### Android 版本

```bash
# 确保Android设备连接或模拟器运行
flutter devices
flutter run -d android
```

### iOS 版本

```bash
# 需要macOS环境和Xcode
flutter run -d ios
```

## 🌐 网络配置

### 本地 LLM 服务访问

如果使用 Web 版本访问本地 LLM 服务，可能需要配置 CORS：

#### Ollama CORS 配置

```bash
# 设置环境变量允许Web访问
export OLLAMA_ORIGINS="*"
ollama serve
```

#### LM Studio CORS 配置

在 LM Studio 的服务器设置中启用 CORS 支持。

### 远程 LLM 服务

如果 LLM 服务部署在远程服务器：

1. 确保防火墙开放对应端口
2. 在应用中使用服务器的 IP 地址
3. 建议使用 HTTPS 连接

## 🛠️ 故障排除

### 常见问题和解决方案

#### 1. Flutter 构建失败

```bash
# 清理项目
flutter clean
flutter pub get

# 检查Flutter环境
flutter doctor

# 如果是macOS构建问题，删除构建缓存
rm -rf build/
rm -rf .dart_tool/
flutter pub get
```

#### 2. LLM 连接失败

- 检查服务是否运行：`curl http://localhost:11434/api/tags`（Ollama）
- 检查防火墙设置
- 确认端口号正确
- 查看应用日志获取详细错误信息

#### 3. 翻译结果异常

- 尝试不同的模型
- 检查模型是否支持目标语言
- 确认网络连接稳定

#### 4. Web 版本 CORS 错误

```bash
# 启动Chrome时禁用安全检查（仅用于测试）
google-chrome --disable-web-security --user-data-dir="/tmp/chrome_dev"

# 或配置LLM服务允许CORS
```

## 📊 性能优化建议

### 1. 模型选择

- **轻量级模型**: llama3.2:1b（更快，资源占用少）
- **平衡模型**: llama3.2:3b（质量和速度平衡）
- **高质量模型**: llama3.2:8b（翻译质量最佳）

### 2. 网络优化

- 使用本地 LLM 服务减少网络延迟
- 考虑使用 SSD 存储模型文件
- 确保充足的内存和 CPU 资源

### 3. 应用优化

- 避免同时翻译过多语言
- 控制输入文本长度（建议 500 字符以内）
- 定期清理应用缓存

## 🔄 更新和维护

### 依赖更新

```bash
# 检查过时依赖
flutter pub outdated

# 更新依赖
flutter pub upgrade

# 重新分析代码
flutter analyze
```

### 功能扩展

项目结构良好，可以轻松扩展：

- 添加新的 LLM 提供商
- 支持更多语言
- 添加翻译历史功能
- 集成更多 AI 服务

## 📞 技术支持

### 日志收集

如果遇到问题，查看应用日志：

```bash
# Flutter应用日志
flutter logs

# 详细调试信息
flutter run --debug
```

### 报告问题

提供以下信息有助于问题诊断：

1. 操作系统和版本
2. Flutter 版本（`flutter --version`）
3. 使用的 LLM 服务和模型
4. 错误日志和截图
5. 重现步骤

## 🎉 成功标志

应用正常工作的标志：

1. ✅ 设置页面可以成功连接到 LLM 服务
2. ✅ 可以看到可用模型列表
3. ✅ 翻译功能正常工作
4. ✅ 可以复制翻译结果
5. ✅ 支持多语言批量翻译

当看到这些功能都正常工作时，说明复刻项目部署成功！
