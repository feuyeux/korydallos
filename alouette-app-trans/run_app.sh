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

# 默认在macOS上运行，如果有参数则使用参数指定的平台
PLATFORM=${1:-macos}
echo -e "${GREEN}🎯 Platform: $PLATFORM${NC}"

# 运行应用
echo -e "${GREEN}🚀 Launching Flutter app...${NC}"
flutter run -d "$PLATFORM" --debug
