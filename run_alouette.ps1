# Alouette Project Launcher (PowerShell)
# Simple script to launch any Alouette application

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("app", "trans", "tts")]
    [string]$App = "app",
    
    [Parameter(Mandatory=$false)]
    [string]$Platform = "windows"
)

# Set UTF-8 encoding for console
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "[LAUNCHER] Alouette Application Launcher" -ForegroundColor Blue
Write-Host "========================================" -ForegroundColor Blue

# Determine target directory
$targetDir = switch ($App) {
    "app"   { "alouette-app" }
    "trans" { "alouette-app-trans" }
    "tts"   { "alouette-app-tts" }
}

Write-Host "[TARGET] Launching: $targetDir" -ForegroundColor Green
Write-Host "[PLATFORM] Platform: $Platform" -ForegroundColor Green

# Check if directory exists
if (-not (Test-Path $targetDir)) {
    Write-Host "[ERROR] Directory not found: $targetDir" -ForegroundColor Red
    Write-Host "[INFO] Available directories:" -ForegroundColor Yellow
    Get-ChildItem -Directory | Where-Object { $_.Name -like "alouette-app*" } | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Yellow }
    exit 1
}

# Change to target directory
Set-Location $targetDir

# Check pubspec.yaml
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "[ERROR] pubspec.yaml not found in $targetDir" -ForegroundColor Red
    exit 1
}

# Get dependencies
Write-Host "[DEPS] Getting dependencies..." -ForegroundColor Yellow
try {
    flutter pub get | Out-Null
    Write-Host "[SUCCESS] Dependencies updated" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to get dependencies: $_" -ForegroundColor Red
    exit 1
}

# Launch application
Write-Host "[LAUNCH] Starting Flutter application..." -ForegroundColor Green
try {
    if ($Platform -eq "windows") {
        flutter run -d windows
    } else {
        flutter run -d $Platform
    }
} catch {
    Write-Host "[ERROR] Failed to start application: $_" -ForegroundColor Red
    exit 1
}