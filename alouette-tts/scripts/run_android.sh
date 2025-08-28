#!/bin/bash
echo "Starting Flutter app on Android..."

# 检查是否有 Android 设备或模拟器在运行
echo "Checking for Android devices..."
ANDROID_DEVICES=$(flutter devices 2>/dev/null | grep -i android || true)

if [ -z "$ANDROID_DEVICES" ]; then
    echo "No Android devices found. Starting Android emulator..."
    
    # 获取第一个可用的 Android 模拟器
    ANDROID_EMULATOR=$(flutter emulators 2>/dev/null | grep android | head -n 1 | awk '{print $1}' || true)
    
    if [ -z "$ANDROID_EMULATOR" ]; then
        echo "Error: No Android emulators found. Please create one using Android Studio or run:"
        echo "flutter emulators --create"
        exit 1
    fi
    
    echo "Launching Android emulator: $ANDROID_EMULATOR"
    flutter emulators --launch "$ANDROID_EMULATOR" 2>/dev/null || {
        echo "Failed to launch emulator directly. Please start it manually from Android Studio."
        exit 1
    }
    
    # 等待模拟器启动
    echo "Waiting for emulator to start..."
    sleep 15
    
    # 再次检查设备
    echo "Checking devices again..."
    flutter devices 2>/dev/null || echo "Device check failed, continuing anyway..."
fi

# 运行应用
echo "Running Flutter app on Android..."
flutter run --debug 2>/dev/null || {
    echo "Failed to run app. Trying with verbose output..."
    flutter run --debug --verbose
}
