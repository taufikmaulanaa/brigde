#!/usr/bin/env pwsh
# Build script untuk Windows (PowerShell)
# Script ini HANYA untuk Windows - JANGAN jalankan di Linux/macOS
# Untuk Linux/macOS, gunakan: ./build-windows.sh
#
# Cara menjalankan di Windows:
#   .\build-windows.ps1
# Atau:
#   powershell -ExecutionPolicy Bypass -File .\build-windows.ps1

# Check if running on Windows (PowerShell Core atau Windows PowerShell)
if (-not $IsWindows -and ($PSVersionTable.Platform -ne "Win32NT")) {
    Write-Host "❌ ERROR: Script ini hanya untuk Windows!" -ForegroundColor Red
    Write-Host "   Jika Anda di Linux/macOS, gunakan: ./build-windows.sh" -ForegroundColor Yellow
    exit 1
}

Write-Host "🔨 Building BRIDGE for Windows..." -ForegroundColor Cyan
Write-Host "══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check if Crystal is installed
try {
    $crystalVersion = crystal --version 2>&1 | Select-Object -First 1
    Write-Host "✅ Crystal version: $crystalVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ ERROR: Crystal tidak terinstall!" -ForegroundColor Red
    Write-Host "   Install Crystal dari: https://crystal-lang.org/install/" -ForegroundColor Yellow
    Write-Host "   Atau gunakan: scoop install crystal" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Install dependencies
Write-Host "📦 Installing dependencies..." -ForegroundColor Cyan
shards install
Write-Host ""

# Build for Windows
Write-Host "🔨 Building for Windows..." -ForegroundColor Cyan
crystal build src/bridge.cr --release -o bin/bridge.exe

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Build selesai! Executable ada di: bin/bridge.exe" -ForegroundColor Green
    Write-Host "   Jalankan dengan: .\bin\bridge.exe" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "❌ Build gagal!" -ForegroundColor Red
    exit 1
}

