#!/usr/bin/env pwsh

# Alouette Integration Test Runner
# This script runs integration tests for all Alouette applications

param(
    [string]$Platform = "auto",  # auto, windows, android, web, etc.
    [string]$App = "all",        # all, main, trans, tts
    [switch]$Verbose,
    [switch]$Coverage,
    [string]$OutputDir = "test_results"
)

Write-Host "🚀 Alouette Integration Test Runner" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Create output directory
if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

# Function to run tests for a specific app
function Run-AppTests {
    param(
        [string]$AppName,
        [string]$AppPath,
        [string]$TestPlatform
    )
    
    Write-Host "`n📱 Testing $AppName Application" -ForegroundColor Yellow
    Write-Host "Path: $AppPath" -ForegroundColor Gray
    Write-Host "Platform: $TestPlatform" -ForegroundColor Gray
    
    Push-Location $AppPath
    
    try {
        # Get dependencies
        Write-Host "📦 Getting dependencies..." -ForegroundColor Blue
        flutter pub get
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Failed to get dependencies for $AppName" -ForegroundColor Red
            return $false
        }
        
        # Build test command
        $testCmd = "flutter test integration_test/test_runner.dart"
        
        if ($TestPlatform -ne "auto") {
            $testCmd += " -d $TestPlatform"
        }
        
        if ($Verbose) {
            $testCmd += " --verbose"
        }
        
        if ($Coverage) {
            $testCmd += " --coverage"
        }
        
        # Add output file
        $outputFile = Join-Path $PSScriptRoot $OutputDir "${AppName}_test_results.json"
        $testCmd += " --reporter=json"
        
        Write-Host "🧪 Running integration tests..." -ForegroundColor Blue
        Write-Host "Command: $testCmd" -ForegroundColor Gray
        
        # Run tests and capture output
        $testOutput = Invoke-Expression $testCmd 2>&1
        $testOutput | Out-File -FilePath $outputFile -Encoding UTF8
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ $AppName tests passed!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ $AppName tests failed!" -ForegroundColor Red
            Write-Host "Output saved to: $outputFile" -ForegroundColor Gray
            return $false
        }
    }
    catch {
        Write-Host "❌ Error running tests for $AppName`: $_" -ForegroundColor Red
        return $false
    }
    finally {
        Pop-Location
    }
}

# Function to detect available platforms
function Get-AvailablePlatforms {
    Write-Host "🔍 Detecting available platforms..." -ForegroundColor Blue
    
    $platforms = @()
    
    # Check for connected devices
    $devices = flutter devices --machine | ConvertFrom-Json
    
    foreach ($device in $devices) {
        $platforms += $device.id
        Write-Host "  📱 Found: $($device.name) ($($device.id))" -ForegroundColor Gray
    }
    
    return $platforms
}

# Main execution
$startTime = Get-Date

# Detect platform if auto
if ($Platform -eq "auto") {
    $availablePlatforms = Get-AvailablePlatforms
    
    if ($availablePlatforms.Count -eq 0) {
        Write-Host "❌ No platforms detected. Please ensure Flutter is installed and devices are connected." -ForegroundColor Red
        exit 1
    }
    
    # Use first available platform
    $Platform = $availablePlatforms[0]
    Write-Host "🎯 Auto-selected platform: $Platform" -ForegroundColor Green
}

# Define applications to test
$applications = @()

if ($App -eq "all" -or $App -eq "main") {
    $applications += @{
        Name = "Main"
        Path = "alouette-app"
        Description = "Combined Translation and TTS Application"
    }
}

if ($App -eq "all" -or $App -eq "trans") {
    $applications += @{
        Name = "Translation"
        Path = "alouette-app-trans"
        Description = "Specialized Translation Application"
    }
}

if ($App -eq "all" -or $App -eq "tts") {
    $applications += @{
        Name = "TTS"
        Path = "alouette-app-tts"
        Description = "Specialized Text-to-Speech Application"
    }
}

# Run tests for each application
$results = @{}
$totalTests = $applications.Count
$passedTests = 0

foreach ($app in $applications) {
    Write-Host "`n" + "="*50 -ForegroundColor Cyan
    Write-Host "Testing: $($app.Description)" -ForegroundColor Cyan
    Write-Host "="*50 -ForegroundColor Cyan
    
    $success = Run-AppTests -AppName $app.Name -AppPath $app.Path -TestPlatform $Platform
    $results[$app.Name] = $success
    
    if ($success) {
        $passedTests++
    }
}

# Generate summary report
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n" + "="*50 -ForegroundColor Cyan
Write-Host "📊 TEST SUMMARY" -ForegroundColor Cyan
Write-Host "="*50 -ForegroundColor Cyan

Write-Host "Platform: $Platform" -ForegroundColor Gray
Write-Host "Duration: $($duration.ToString('mm\:ss'))" -ForegroundColor Gray
Write-Host "Results Directory: $OutputDir" -ForegroundColor Gray

Write-Host "`nResults:" -ForegroundColor White
foreach ($result in $results.GetEnumerator()) {
    $status = if ($result.Value) { "✅ PASSED" } else { "❌ FAILED" }
    $color = if ($result.Value) { "Green" } else { "Red" }
    Write-Host "  $($result.Key): $status" -ForegroundColor $color
}

Write-Host "`nOverall: $passedTests/$totalTests tests passed" -ForegroundColor White

if ($passedTests -eq $totalTests) {
    Write-Host "🎉 All integration tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "💥 Some integration tests failed!" -ForegroundColor Red
    exit 1
}

# Generate HTML report
$htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Alouette Integration Test Results</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        .summary { margin: 20px 0; }
        .passed { color: green; }
        .failed { color: red; }
        .details { margin-top: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Alouette Integration Test Results</h1>
        <p><strong>Platform:</strong> $Platform</p>
        <p><strong>Duration:</strong> $($duration.ToString('mm\:ss'))</p>
        <p><strong>Timestamp:</strong> $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))</p>
    </div>
    
    <div class="summary">
        <h2>Summary</h2>
        <p><strong>Overall Result:</strong> $passedTests/$totalTests tests passed</p>
    </div>
    
    <div class="details">
        <h2>Detailed Results</h2>
        <table>
            <tr><th>Application</th><th>Status</th><th>Details</th></tr>
"@

foreach ($result in $results.GetEnumerator()) {
    $status = if ($result.Value) { "PASSED" } else { "FAILED" }
    $class = if ($result.Value) { "passed" } else { "failed" }
    $detailsFile = "${$result.Key}_test_results.json"
    
    $htmlReport += @"
            <tr>
                <td>$($result.Key)</td>
                <td class="$class">$status</td>
                <td><a href="$detailsFile">View Details</a></td>
            </tr>
"@
}

$htmlReport += @"
        </table>
    </div>
</body>
</html>
"@

$htmlReportPath = Join-Path $OutputDir "test_report.html"
$htmlReport | Out-File -FilePath $htmlReportPath -Encoding UTF8

Write-Host "`n📄 HTML report generated: $htmlReportPath" -ForegroundColor Blue