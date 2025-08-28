#!/bin/bash

# Alouette Translator - 快速测试脚本
# Quick test script for Alouette Translator

echo "🚀 Alouette Translator - 开始测试 / Starting Test"
echo "================================================"

# 检查 Flutter 是否安装
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter 未安装。请先安装 Flutter SDK。"
    echo "❌ Flutter is not installed. Please install Flutter SDK first."
    exit 1
fi

echo "✅ Flutter 已安装"
echo "✅ Flutter is installed"

# 显示 Flutter 版本
echo ""
echo "📋 Flutter 版本信息 / Flutter Version Info:"
flutter --version

# 检查项目依赖
echo ""
echo "📦 安装项目依赖 / Installing Dependencies..."
flutter pub get

if [ $? -eq 0 ]; then
    echo "✅ 依赖安装成功"
    echo "✅ Dependencies installed successfully"
else
    echo "❌ 依赖安装失败"
    echo "❌ Failed to install dependencies"
    exit 1
fi

# 代码分析
echo ""
echo "🔍 代码分析 / Code Analysis..."
flutter analyze

if [ $? -eq 0 ]; then
    echo "✅ 代码分析通过"
    echo "✅ Code analysis passed"
else
    echo "⚠️ 代码分析发现问题，但继续运行测试"
    echo "⚠️ Code analysis found issues, but continuing with test"
fi

# 运行测试
echo ""
echo "🧪 运行测试 / Running Tests..."
flutter test

if [ $? -eq 0 ]; then
    echo "✅ 测试通过"
    echo "✅ Tests passed"
else
    echo "⚠️ 测试失败或无测试文件"
    echo "⚠️ Tests failed or no test files found"
fi

# 尝试构建
echo ""
echo "🔨 尝试构建应用 / Attempting to Build App..."

# 检查平台并构建
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 检测到 macOS，尝试构建 macOS 版本..."
    echo "🍎 macOS detected, attempting to build macOS version..."
    flutter build macos --debug
    
    if [ $? -eq 0 ]; then
        echo "✅ macOS 构建成功"
        echo "✅ macOS build successful"
        echo ""
        echo "🚀 启动应用 / Launching App..."
        flutter run -d macos --debug &
        
        # 等待几秒让应用启动
        sleep 3
        echo "📱 应用已启动，你可以在模拟器中看到它"
        echo "📱 App launched, you can see it in the simulator"
    else
        echo "❌ macOS 构建失败"
        echo "❌ macOS build failed"
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "🐧 检测到 Linux，尝试构建 Linux 版本..."
    echo "🐧 Linux detected, attempting to build Linux version..."
    flutter build linux --debug
    
    if [ $? -eq 0 ]; then
        echo "✅ Linux 构建成功"
        echo "✅ Linux build successful"
    else
        echo "❌ Linux 构建失败"
        echo "❌ Linux build failed"
    fi
else
    echo "🌐 尝试构建 Web 版本..."
    echo "🌐 Attempting to build Web version..."
    flutter build web --debug
    
    if [ $? -eq 0 ]; then
        echo "✅ Web 构建成功"
        echo "✅ Web build successful"
    else
        echo "❌ Web 构建失败"
        echo "❌ Web build failed"
    fi
fi

echo ""
echo "================================================"
echo "🎉 测试完成 / Test Complete!"
echo ""
echo "📝 下一步 / Next Steps:"
echo "1. 确保你已经安装并运行了 Ollama 或 LM Studio"
echo "   Make sure you have Ollama or LM Studio installed and running"
echo ""
echo "2. Ollama 设置 / Ollama Setup:"
echo "   - 安装: curl -fsSL https://ollama.ai/install.sh | sh"
echo "   - 启动: ollama serve"
echo "   - 下载模型: ollama pull llama3.2"
echo ""
echo "3. LM Studio 设置 / LM Studio Setup:"
echo "   - 从 https://lmstudio.ai 下载并安装"
echo "   - 加载一个模型并启动本地服务器"
echo ""
echo "4. 在应用中点击设置按钮配置 LLM 连接"
echo "   Click the settings button in the app to configure LLM connection"
echo ""
echo "🔧 如果遇到问题，请检查："
echo "🔧 If you encounter issues, please check:"
echo "- Flutter doctor: flutter doctor"
echo "- 网络连接 / Network connection"
echo "- LLM 服务器状态 / LLM server status"
