# Luvco App -- Integrated Runner Script
# This script starts the backend server in a new window, establishes the ADB reverse tunnel, and launches the Flutter application.

$ErrorActionPreference = "Stop"

# Get absolute paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrEmpty($ScriptDir)) {
    $ScriptDir = Get-Location
}
$BackendDir = "$ScriptDir\..\Luvco-App-backend\luvco-backend"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Luvco App + Backend Runner" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Start the Node.js backend server in a new terminal window
Write-Host ">>> Starting Node.js backend in a separate terminal window..." -ForegroundColor Yellow
if (Test-Path $BackendDir) {
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$BackendDir'; Write-Host '--- Node.js Backend Server Logs ---' -ForegroundColor Yellow; npm run dev"
} else {
    Write-Host "[ERROR] Backend directory not found at: $BackendDir" -ForegroundColor Red
    Exit 1
}

# 2. Setup ADB reverse port forwarding (for physical Android devices)
Write-Host ">>> Checking for connected Android devices & setting up ADB tunnel..." -ForegroundColor Yellow
try {
    # Check if adb is available
    if (Get-Command adb -ErrorAction SilentlyContinue) {
        $devices = adb devices
        # Check if any physical or emulator device is listed
        if ($devices -match "\bdevice\b") {
            Write-Host "[OK] Found connected Android device. Reversing port 3000..." -ForegroundColor Green
            adb reverse tcp:3000 tcp:3000
            Write-Host "[OK] ADB reverse tunnel set up successfully." -ForegroundColor Green
        } else {
            Write-Host "[WARN] No active Android devices detected. Skipping ADB reverse." -ForegroundColor Gray
        }
    } else {
        Write-Host "[WARN] ADB command not found. Skipping ADB reverse (Android SDK may not be in PATH)." -ForegroundColor Gray
    }
} catch {
    Write-Host "[WARN] Failed to set up ADB reverse: $_. Continuing..." -ForegroundColor Yellow
}

# 3. Run Flutter Application
Write-Host ">>> Running Flutter App..." -ForegroundColor Yellow
cd $ScriptDir
flutter run
