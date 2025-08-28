#!/bin/bash
echo "Starting Flutter app on Web..."

# 检查 web 平台是否可用
echo "Checking for web platform..."
if flutter devices 2>/dev/null | grep -q "web"; then
    echo "Web platform found. Starting web server..."
    echo "App will be available at: http://localhost:8080"
    flutter run -d web-server --web-port=8080 --web-hostname=localhost --debug 2>/dev/null || {
        echo "Failed to start web server. Trying with verbose output..."
        flutter run -d web-server --web-port=8080 --web-hostname=localhost --debug --verbose
    }
else
    echo "Error: Web platform not found. Please make sure Flutter web support is enabled:"
    echo "flutter config --enable-web"
    echo "Checking Flutter configuration..."
    flutter config 2>/dev/null || echo "Flutter config check failed"
    exit 1
fi
