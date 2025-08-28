@echo off
echo Starting Flutter app on Windows...

echo Checking for Windows platform...
flutter devices | findstr "windows" >nul
if %errorlevel% equ 0 (
    echo Windows platform found. Running Flutter app...
    flutter run -d windows
) else (
    echo Error: Windows platform not found. Please make sure Flutter desktop support is enabled:
    echo flutter config --enable-windows-desktop
    exit /b 1
)
