#!/bin/bash
echo "Starting Flutter app on macOS..."

# 检查 macOS 桌面平台是否可用
echo "Checking for macOS platform..."
if flutter devices 2>/dev/null | grep -q "macos"; then
    echo "macOS platform found. Running Flutter app..."
    flutter run -d macos --debug 2>/dev/null || {
        echo "Failed to run app. Trying with verbose output..."
        flutter run -d macos --debug --verbose
    }
else
    echo "Error: macOS platform not found. Please make sure Flutter desktop support is enabled:"
    echo "flutter config --enable-macos-desktop"
    echo "Checking Flutter configuration..."
    flutter config 2>/dev/null || echo "Flutter config check failed"
    exit 1
fi
