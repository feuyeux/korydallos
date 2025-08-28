# Alouette TTS Windows Release Builder PowerShell Script
param(
    [string]$Platform = "windows"
)

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "   Alouette TTS Release Builder" -ForegroundColor Cyan  
Write-Host "===========================================" -ForegroundColor Cyan

# Get version from pubspec.yaml
$pubspec = Get-Content "pubspec.yaml"
$versionLine = $pubspec | Where-Object { $_ -match "^version:" }
$version = ($versionLine -split " ")[1] -split "\+" | Select-Object -First 1

Write-Host "Version: $version" -ForegroundColor Green
Write-Host ""

# Create output directory
$timestamp = Get-Date -Format "yyyyMMdd_HHmm"
$outputDir = "dist\release_$($version)_$timestamp"

Write-Host "Creating output directory: $outputDir" -ForegroundColor Yellow
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

# Check Flutter
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Flutter not found. Please install Flutter and add to PATH" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-Host "Flutter found" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Flutter not found" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check project
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "ERROR: Please run this script from Flutter project root directory" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Building Windows Release..." -ForegroundColor Yellow
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Flutter build failed" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Build successful, packaging files..." -ForegroundColor Green

# Check if exe exists
$exePath = "build\windows\x64\runner\Release\alouette-tts.exe"
if (-not (Test-Path $exePath)) {
    Write-Host "ERROR: Could not find alouette-tts.exe in Release folder" -ForegroundColor Red
    Write-Host "Looking for available files:" -ForegroundColor Yellow
    Get-ChildItem "build\windows\x64\runner\" -Recurse -Name
    Read-Host "Press Enter to exit"
    exit 1
}

# Create windows folder in output
$windowsOutputDir = "$outputDir\windows"
New-Item -ItemType Directory -Path $windowsOutputDir -Force | Out-Null

# Copy all Release files
Write-Host "Copying Windows release files..." -ForegroundColor Yellow
try {
    Copy-Item "build\windows\x64\runner\Release\*" -Destination $windowsOutputDir -Recurse -Force
    Write-Host "Files copied successfully!" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to copy files: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Verify exe was copied
if (Test-Path "$windowsOutputDir\alouette-tts.exe") {
    Write-Host "SUCCESS: alouette-tts.exe found in output directory" -ForegroundColor Green
} else {
    Write-Host "ERROR: alouette-tts.exe not found in output directory" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Try to create ZIP if available
Write-Host "Checking for compression tools..." -ForegroundColor Yellow
$zipCreated = $false

# Try PowerShell Compress-Archive (Windows 10+)
try {
    $zipPath = "$outputDir\alouette-tts-windows-$version.zip"
    Compress-Archive -Path "$windowsOutputDir\*" -DestinationPath $zipPath -Force
    Write-Host "ZIP archive created successfully using PowerShell" -ForegroundColor Green
    $zipCreated = $true
} catch {
    Write-Host "PowerShell compression not available, trying 7z..." -ForegroundColor Yellow
    
    # Try 7z
    try {
        $7zPath = Get-Command "7z" -ErrorAction Stop
        Set-Location $outputDir
        & 7z a "alouette-tts-windows-$version.zip" "windows\" | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "ZIP archive created successfully using 7z" -ForegroundColor Green
            $zipCreated = $true
        }
        Set-Location ..
    } catch {
        Write-Host "7z not found, skipping ZIP creation" -ForegroundColor Yellow
    }
}

# Create info file
$infoContent = @"
Alouette TTS v$version Windows Release

Build date: $(Get-Date)

Files included:
- windows/alouette-tts.exe (Main executable)
- windows/data/ (Flutter assets and resources)
- windows/*.dll (Required libraries)
"@

if ($zipCreated) {
    $infoContent += "`n- alouette-tts-windows-$version.zip (Compressed package)"
}

$infoContent | Out-File "$outputDir\README.txt" -Encoding UTF8

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "         BUILD COMPLETE" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "Output directory: $outputDir" -ForegroundColor Green
Write-Host ""
Write-Host "Files created:" -ForegroundColor Yellow
Get-ChildItem $outputDir | ForEach-Object { Write-Host "  $($_.Name)" }
Write-Host ""
Write-Host "Windows executable: $outputDir\windows\alouette-tts.exe" -ForegroundColor Green

if ($zipCreated) {
    Write-Host "ZIP package: $outputDir\alouette-tts-windows-$version.zip" -ForegroundColor Green
}

Write-Host ""
Read-Host "Press Enter to exit"
