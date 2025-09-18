# Alouette Base App 快速启动脚本 (PowerShell版本)
# Quick start script for Alouette Base App (PowerShell Version)

param(
    [string]$Platform = "windows"
)

# 设置错误处理
$ErrorActionPreference = "Stop"

# 获取脚本目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 颜色输出函数
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput "🚀 Starting Alouette Base App" "Blue"

# 切换到应用目录
Set-Location $ScriptDir

# 检查pubspec.yaml
if (!(Test-Path "pubspec.yaml")) {
    Write-ColorOutput "❌ Error: pubspec.yaml not found in $(Get-Location)" "Red"
    exit 1
}

Write-ColorOutput "📂 Running from: $(Get-Location)" "Green"
Write-ColorOutput "🎯 Platform: $Platform" "Green"

# Platform-specific setup (if needed in the future)
if ($Platform.ToLower() -eq "windows") {
    Write-ColorOutput "🖥️  Preparing Windows environment..." "Yellow"
}

# 清理并获取依赖
Write-ColorOutput "🧹 Cleaning project..." "Yellow"
try {
    flutter clean | Out-Null
    Write-ColorOutput "✅ Project cleaned" "Green"
} catch {
    Write-ColorOutput "⚠️  Clean failed, continuing..." "Yellow"
}

Write-ColorOutput "📦 Getting dependencies..." "Yellow"
try {
    flutter pub get | Out-Null
    Write-ColorOutput "✅ Dependencies updated" "Green"
} catch {
    Write-ColorOutput "❌ Failed to get dependencies" "Red"
    exit 1
}

# 运行应用
Write-ColorOutput "🚀 Launching Flutter app..." "Green"
try {
    switch ($Platform.ToLower()) {
        "windows" { 
            Write-ColorOutput "🖥️  Starting Windows desktop app..." "Cyan"
            flutter run -d windows --debug
        }
        "chrome" { 
            Write-ColorOutput "🌐 Starting in Chrome browser..." "Cyan"
            flutter run -d chrome --debug
        }
        "edge" { 
            Write-ColorOutput "🌐 Starting in Edge browser..." "Cyan"
            flutter run -d edge --debug
        }
        default { 
            Write-ColorOutput "🎯 Starting on platform: $Platform..." "Cyan"
            flutter run -d $Platform --debug
        }
    }
} catch {
    Write-ColorOutput "❌ Failed to start application: $_" "Red"
    exit 1
}
