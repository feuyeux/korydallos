#!/bin/bash

# 进入项目目录
cd /Users/han/coding/alouette-ai/alouette-translator

# 检查文件是否存在
if [ ! -f "pubspec.yaml" ]; then
    echo "Error: pubspec.yaml not found in $(pwd)"
    exit 1
fi

echo "Running Flutter app from $(pwd)"
echo "Pubspec.yaml exists: $(ls -la pubspec.yaml)"

# 运行Flutter应用
flutter run -d macos --debug
