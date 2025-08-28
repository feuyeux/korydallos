#!/bin/bash
set -e

echo "Starting Flutter app on macOS..."

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

# 切换到项目根目录
cd "$PROJECT_DIR" || {
    echo "Error: Failed to change to project directory: $PROJECT_DIR"
    exit 1
}

echo "Working in directory: $(pwd)"

# 清理函数
clean_build() {
    echo "Cleaning Flutter build cache..."
    flutter clean > /dev/null 2>&1 || echo "Warning: Flutter clean failed"
    
    echo "Cleaning macOS build artifacts..."
    rm -rf build/macos > /dev/null 2>&1 || true
    rm -rf macos/build > /dev/null 2>&1 || true
    
    echo "Cleaning Xcode derived data..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-* > /dev/null 2>&1 || true
    
    echo "Getting Flutter dependencies..."
    flutter pub get || {
        echo "Error: Failed to get Flutter dependencies"
        exit 1
    }
}

# 检查 Flutter 是否已安装
if ! command -v flutter &> /dev/null; then
    echo "Error: Flutter is not installed or not in PATH"
    exit 1
fi

# 检查 macOS 桌面平台是否可用
echo "Checking for macOS platform..."
if ! flutter devices 2>/dev/null | grep -q "macos"; then
    echo "Error: macOS platform not found."
    echo "Enabling macOS desktop support..."
    flutter config --enable-macos-desktop || {
        echo "Error: Failed to enable macOS desktop support"
        exit 1
    }
    echo "macOS desktop support enabled. Please restart this script."
    exit 0
fi

echo "macOS platform found."

# 检查是否需要清理构建缓存
if [[ "$1" == "--clean" || "$1" == "-c" ]]; then
    clean_build
fi

# 尝试运行应用
echo "Running Flutter app on macOS..."
if ! flutter run -d macos --debug; then
    echo ""
    echo "Build failed. Attempting to clean and rebuild..."
    clean_build
    echo ""
    echo "Retrying flutter run..."
    flutter run -d macos --debug || {
        echo ""
        echo "Error: Failed to run the app even after cleaning."
        echo "You may need to:"
        echo "1. Check your Xcode installation"
        echo "2. Run 'xcode-select --install' to install command line tools"
        echo "3. Open Xcode and accept any license agreements"
        echo "4. Try running: flutter doctor -v"
        exit 1
    }
fi
