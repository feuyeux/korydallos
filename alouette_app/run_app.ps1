# Quick start script for Alouette Base App (PowerShell Version)
# Alouette Base App PowerShell Launch Script

param(
    [string]$Platform = "windows"
)

# Set error handling
$ErrorActionPreference = "Stop"

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Color output function
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput "[START] Starting Alouette Base App" "Blue"

# Change to application directory
Set-Location $ScriptDir

# Check pubspec.yaml
if (!(Test-Path "pubspec.yaml")) {
    Write-ColorOutput "[ERROR] pubspec.yaml not found in $(Get-Location)" "Red"
    exit 1
}

Write-ColorOutput "[INFO] Running from: $(Get-Location)" "Green"
Write-ColorOutput "[INFO] Platform: $Platform" "Green"

# Platform-specific setup (if needed in the future)
if ($Platform.ToLower() -eq "windows") {
    Write-ColorOutput "[SETUP] Preparing Windows environment..." "Yellow"
}

# Clean and get dependencies
Write-ColorOutput "[CLEAN] Cleaning project..." "Yellow"
try {
    flutter clean | Out-Null
    Write-ColorOutput "[SUCCESS] Project cleaned" "Green"
} catch {
    Write-ColorOutput "[WARNING] Clean failed, continuing..." "Yellow"
}

Write-ColorOutput "[DEPS] Getting dependencies..." "Yellow"
try {
    flutter pub get | Out-Null
    Write-ColorOutput "[SUCCESS] Dependencies updated" "Green"
} catch {
    Write-ColorOutput "[ERROR] Failed to get dependencies" "Red"
    exit 1
}

# Run application
Write-ColorOutput "[LAUNCH] Launching Flutter app..." "Green"
try {
    switch ($Platform.ToLower()) {
        "windows" { 
            Write-ColorOutput "[PLATFORM] Starting Windows desktop app..." "Cyan"
            flutter run -d windows --debug
        }
        "chrome" { 
            Write-ColorOutput "[PLATFORM] Starting in Chrome browser..." "Cyan"
            flutter run -d chrome --debug
        }
        "edge" { 
            Write-ColorOutput "[PLATFORM] Starting in Edge browser..." "Cyan"
            flutter run -d edge --debug
        }
        default { 
            Write-ColorOutput "[PLATFORM] Starting on platform: $Platform..." "Cyan"
            flutter run -d $Platform --debug
        }
    }
} catch {
    Write-ColorOutput "[ERROR] Failed to start application: $_" "Red"
    exit 1
}
