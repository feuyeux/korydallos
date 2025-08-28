#!/bin/bash
echo "Starting Flutter app on iOS..."

# 检查是否有 iOS 设备或模拟器在运行
echo "Checking for iOS devices..."
IOS_DEVICES=$(flutter devices 2>/dev/null | grep -i ios || true)

if [ -z "$IOS_DEVICES" ]; then
    echo "No iOS devices found. Starting iOS Simulator..."
    
    # 获取第一个可用的 iOS 模拟器
    IOS_SIMULATOR=$(flutter emulators 2>/dev/null | grep ios | head -n 1 | awk '{print $1}' || true)
    
    if [ -z "$IOS_SIMULATOR" ]; then
        echo "Error: No iOS simulators found. Please install Xcode and iOS Simulator."
        echo "You can also try running: flutter emulators --create"
        exit 1
    fi
    
    echo "Launching iOS Simulator: $IOS_SIMULATOR"
    flutter emulators --launch "$IOS_SIMULATOR" 2>/dev/null || {
        echo "Failed to launch simulator. Trying to open iOS Simulator directly..."
        open -a Simulator
        sleep 3
    }
    
    # 等待模拟器启动
    echo "Waiting for simulator to start..."
    sleep 10
    
    # 再次检查设备
    echo "Checking devices again..."
    flutter devices 2>/dev/null || echo "Device check failed, continuing anyway..."
fi

# 运行应用
echo "Running Flutter app on iOS..."
flutter run --debug 2>/dev/null || {
    echo "Failed to run app. Trying with verbose output..."
    flutter run --debug --verbose
}
