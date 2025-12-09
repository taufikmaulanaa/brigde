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

# Prepare build directory
Write-Host "📁 Preparing build directory..." -ForegroundColor Cyan
if (-not (Test-Path bin)) {
    New-Item -ItemType Directory -Path bin | Out-Null
    Write-Host "   ✅ Folder 'bin' dibuat" -ForegroundColor Gray
}
# Remove old executable if exists (to avoid lock issues)
if (Test-Path bin/bridge.exe) {
    Remove-Item bin/bridge.exe -Force -ErrorAction SilentlyContinue
    Write-Host "   ✅ File lama dihapus" -ForegroundColor Gray
}
Write-Host ""

# Check Crystal architecture
Write-Host "🔍 Checking Crystal architecture..." -ForegroundColor Cyan
$crystalInfo = crystal env 2>&1 | Out-String
if ($crystalInfo -match "x86_64" -or $crystalInfo -match "amd64") {
    Write-Host "   ✅ Crystal terdeteksi sebagai 64-bit" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Architecture Crystal: $crystalInfo" -ForegroundColor Yellow
}
Write-Host ""

# Build for Windows 64-bit dengan static linking
Write-Host "🔨 Building for Windows 64-bit (static linking)..." -ForegroundColor Cyan
Write-Host "   Target: x86_64-w64-mingw32 (Windows 64-bit)" -ForegroundColor Gray
Write-Host "   Menggunakan static linking untuk menghindari dependency DLL" -ForegroundColor Gray
Write-Host ""

$buildSuccess = $false

# Try static linking first (recommended)
Write-Host "   Mencoba static linking..." -ForegroundColor Gray
crystal build src/bridge.cr --release --static -o bin/bridge.exe 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0 -and (Test-Path bin/bridge.exe)) {
    $buildSuccess = $true
    Write-Host "   ✅ Static linking berhasil!" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Static linking gagal, mencoba tanpa static linking..." -ForegroundColor Yellow
    
    # Fallback: build without static linking
    crystal build src/bridge.cr --release -o bin/bridge.exe 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0 -and (Test-Path bin/bridge.exe)) {
        $buildSuccess = $true
        Write-Host "   ✅ Build tanpa static linking berhasil!" -ForegroundColor Green
        Write-Host "   ⚠️  PERINGATAN: Executable memerlukan DLL dependencies" -ForegroundColor Yellow
        Write-Host "      Pastikan DLL berikut ada di folder yang sama:" -ForegroundColor Yellow
        Write-Host "      - pcre2-8.dll" -ForegroundColor Yellow
        Write-Host "      - libxml2.dll" -ForegroundColor Yellow
        Write-Host "      - libiconv.dll" -ForegroundColor Yellow
    }
}

if ($buildSuccess) {
    Write-Host ""
    
    # Verify executable exists and get info
    if (Test-Path bin/bridge.exe) {
        $fileInfo = Get-Item bin/bridge.exe
        $fileSize = [math]::Round($fileInfo.Length / 1MB, 2)
        
        Write-Host "✅ Build selesai!" -ForegroundColor Green
        Write-Host "   📦 File: bin/bridge.exe" -ForegroundColor Cyan
        Write-Host "   📏 Ukuran: $fileSize MB" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "   🚀 Jalankan dengan:" -ForegroundColor Yellow
        Write-Host "      .\bin\bridge.exe" -ForegroundColor White
        Write-Host "      .\bin\bridge.exe list.xlsx raw_files" -ForegroundColor White
        Write-Host ""
        
        # Try to verify it's 64-bit (if file command or dumpbin available)
        Write-Host "   🔍 Verifikasi architecture..." -ForegroundColor Gray
        try {
            # Check using file command (if available via WSL/Git Bash)
            $archCheck = file bin/bridge.exe 2>&1 | Out-String
            if ($archCheck -match "x86-64" -or $archCheck -match "PE32\+" -or $archCheck -match "64-bit") {
                Write-Host "      ✅ Executable adalah 64-bit" -ForegroundColor Green
            } else {
                Write-Host "      ⚠️  Architecture tidak dapat diverifikasi otomatis" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "      ℹ️  Verifikasi architecture memerlukan tools tambahan" -ForegroundColor Gray
        }
    } else {
        Write-Host "❌ ERROR: File executable tidak ditemukan setelah build!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host ""
    Write-Host "❌ Build gagal!" -ForegroundColor Red
    Write-Host "   Periksa error di atas untuk detail lebih lanjut." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   💡 Tips troubleshooting:" -ForegroundColor Cyan
    Write-Host "      1. Pastikan Crystal terinstall dengan benar" -ForegroundColor White
    Write-Host "      2. Pastikan semua dependencies terinstall (shards install)" -ForegroundColor White
    Write-Host "      3. Coba build tanpa static linking:" -ForegroundColor White
    Write-Host "         crystal build src/bridge.cr --release -o bin/bridge.exe" -ForegroundColor Gray
    exit 1
}

