@echo off
setlocal enabledelayedexpansion

:: Alouette TTS 快速启动脚本 (Windows)
:: Quick start script for Alouette TTS

echo 🚀 Starting Alouette TTS

:: 切换到脚本所在目录
cd /d "%~dp0"

:: 检查pubspec.yaml
if not exist "pubspec.yaml" (
    echo ❌ Error: pubspec.yaml not found in %cd%
    pause
    exit /b 1
)

echo 📂 Running from: %cd%

:: 默认在Windows上运行，如果有参数则使用参数指定的平台
set PLATFORM=%1
if "%PLATFORM%"=="" set PLATFORM=windows

echo 🎯 Platform: %PLATFORM%

:: 获取依赖并运行应用
echo 📦 Getting dependencies...
flutter pub get

echo 🚀 Launching Flutter app...
flutter run -d %PLATFORM% --debug

pause