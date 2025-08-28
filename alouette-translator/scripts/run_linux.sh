#!/bin/bash
echo "Starting Flutter app on Linux..."

# 检查 Linux 桌面平台是否可用
echo "Checking for Linux platform..."
if flutter devices 2>/dev/null | grep -q "linux"; then
    echo "Linux platform found. Running Flutter app..."
    flutter run -d linux --debug 2>/dev/null || {
        echo "Failed to run app. Trying with verbose output..."
        flutter run -d linux --debug --verbose
    }
else
    echo "Error: Linux platform not found. Please make sure Flutter desktop support is enabled:"
    echo "flutter config --enable-linux-desktop"
    echo "Checking Flutter configuration..."
    flutter config 2>/dev/null || echo "Flutter config check failed"
    exit 1
fi
