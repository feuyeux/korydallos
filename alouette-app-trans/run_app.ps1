# Alouette Translation 快速启动脚本 (PowerShell)
# Quick start script for Alouette Translation

param(
    [string]$Platform = "windows"
)

Write-Host "🚀 Starting Alouette Translation" -ForegroundColor Blue

# 切换到脚本所在目录
Set-Location -Path $PSScriptRoot

# 检查pubspec.yaml
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "❌ Error: pubspec.yaml not found in $(Get-Location)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "📂 Running from: $(Get-Location)" -ForegroundColor Green
Write-Host "🎯 Platform: $Platform" -ForegroundColor Green

# Platform-specific setup (if needed in the future)
if ($Platform.ToLower() -eq "windows") {
    Write-Host "🖥️  Preparing Windows environment..." -ForegroundColor Yellow
}

# 获取依赖并运行应用
Write-Host "📦 Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "🚀 Launching Flutter app..." -ForegroundColor Green
flutter run -d $Platform --debug
