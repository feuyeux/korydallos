#!/usr/bin/env pwsh
# Quick start script for Alouette TTS
# Alouette TTS PowerShell Launch Script

Write-Host "[START] Starting Alouette TTS" -ForegroundColor Blue

# Change to script directory
Set-Location -Path $PSScriptRoot

# Check pubspec.yaml
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "[ERROR] pubspec.yaml not found in $(Get-Location)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[INFO] Running from: $(Get-Location)" -ForegroundColor Green

Write-Host "[INFO] Platform: $Platform" -ForegroundColor Green

# Platform-specific setup (if needed in the future)
if ($Platform.ToLower() -eq "windows") {
    Write-Host "[SETUP] Preparing Windows environment..." -ForegroundColor Yellow
}

# Get dependencies and run application
Write-Host "[DEPS] Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "[LAUNCH] Launching Flutter app..." -ForegroundColor Green
flutter run -d $Platform --debug