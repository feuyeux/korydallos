#!/bin/bash

# Alouette Translator 快速启动脚本
# Quick start script for Alouette Translator

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Starting Alouette Translator${NC}"

# 确保Homebrew在PATH中 (修复CocoaPods问题)
if [[ "$OSTYPE" == "darwin"* ]] && [[ -d "/opt/homebrew/bin" ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
    echo -e "${GREEN}✅ Added Homebrew to PATH${NC}"
fi

# 切换到应用目录
cd "$SCRIPT_DIR"

# 检查pubspec.yaml
if [[ ! -f "pubspec.yaml" ]]; then
    echo "❌ Error: pubspec.yaml not found in $(pwd)"
    exit 1
fi

echo -e "${GREEN}📂 Running from: $(pwd)${NC}"

# 解析参数
CLEAN=false
PLATFORM="macos"

for arg in "$@"; do
    case $arg in
        --clean)
            CLEAN=true
            shift
            ;;
        macos|linux|windows|chrome|android|ios)
            PLATFORM=$arg
            shift
            ;;
        *)
            ;;
    esac
done

echo -e "${GREEN}🎯 Platform: $PLATFORM${NC}"

# 清理构建缓存
if [ "$CLEAN" = true ]; then
    echo -e "${BLUE}🧹 Cleaning build cache...${NC}"
    flutter clean
    echo -e "${BLUE}📦 Getting dependencies...${NC}"
    flutter pub get
    echo -e "${GREEN}✅ Clean complete${NC}"
fi

# 运行应用
echo -e "${GREEN}🚀 Launching Flutter app...${NC}"
flutter run -d "$PLATFORM" --debug
