# Alouette TTS 快速启动脚本 (PowerShell)
# Quick start script for Alouette TTS

Write-Host "🚀 Starting Alouette TTS" -ForegroundColor Blue

# 切换到脚本所在目录
Set-Location -Path $PSScriptRoot

# 检查pubspec.yaml
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "❌ Error: pubspec.yaml not found in $(Get-Location)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "📂 Running from: $(Get-Location)" -ForegroundColor Green

# 默认在Windows上运行，如果有参数则使用参数指定的平台
$Platform = if ($args[0]) { $args[0] } else { "windows" }
Write-Host "🎯 Platform: $Platform" -ForegroundColor Green

# 获取依赖并运行应用
Write-Host "📦 Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "🚀 Launching Flutter app..." -ForegroundColor Green
flutter run -d $Platform --debug