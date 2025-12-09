#!/bin/bash

# Build script untuk Windows (Cross-compile dari Linux/macOS)
# Script ini untuk build executable Windows dari Linux atau macOS
# 
# Catatan: Cross-compile memerlukan library Windows yang kompleks.
# Untuk hasil terbaik, build langsung di Windows menggunakan build-windows.ps1
# atau gunakan GitHub Actions yang otomatis build di Windows.

set -e

echo "🔨 Building BRIDGE for Windows..."
echo "══════════════════════════════════════════════════"

# Check if Crystal is installed
if ! command -v crystal &> /dev/null; then
    echo "❌ ERROR: Crystal tidak terinstall!"
    echo "   Install Crystal dari: https://crystal-lang.org/install/"
    exit 1
fi

echo "✅ Crystal version: $(crystal --version | head -n 1)"
echo

# Install dependencies
echo "📦 Installing dependencies..."
shards install
echo

# Check if we have the cross-compiler
if ! command -v x86_64-w64-mingw32-gcc &> /dev/null; then
    echo "⚠️  WARNING: x86_64-w64-mingw32-gcc tidak ditemukan!"
    echo "   Install MinGW-w64 untuk cross-compilation:"
    echo "   - Ubuntu/Debian: sudo apt-get install gcc-mingw-w64-x86-64"
    echo "   - macOS: brew install mingw-w64"
    echo "   - Atau build langsung di Windows dengan: crystal build src/bridge.cr --release -o bin/bridge.exe"
    exit 1
fi

# Build for Windows (64-bit) using cross-compilation
echo "🔨 Building for Windows x64 (cross-compile)..."
echo "⚠️  Catatan: Cross-compile dari Linux ke Windows memerlukan library Windows."
echo "   Jika linking gagal, ini normal. Gunakan build di Windows atau GitHub Actions."
echo ""

BUILD_LOG=$(mktemp)
crystal build src/bridge.cr \
    --cross-compile \
    --target x86_64-w64-mingw32 \
    --release \
    -o bin/bridge 2>&1 | tee "$BUILD_LOG" || true

# Tunggu sebentar untuk file system sync
sleep 2

# Cek apakah executable sudah dibuat oleh Crystal
if [ -f "bin/bridge" ]; then
    # Crystal sudah melakukan linking, tinggal rename ke .exe
    echo "✅ Executable sudah dibuat oleh Crystal, mengganti nama ke .exe..."
    mv bin/bridge bin/bridge.exe
    rm -f "$BUILD_LOG"
elif [ -f "bin/bridge.obj" ]; then
    # Crystal hanya menghasilkan object file
    echo ""
    echo "⚠️  Crystal hanya menghasilkan object file (bin/bridge.obj)."
    echo "   Linking manual memerlukan library Windows yang kompleks."
    echo ""
    echo "✅ Object file sudah dibuat: bin/bridge.obj"
    echo ""
    echo "📋 Untuk mendapatkan executable Windows lengkap, gunakan salah satu opsi:"
    echo ""
    echo "   1. 🪟 Build langsung di Windows (Recommended):"
    echo "      .\\build-windows.ps1"
    echo ""
    echo "   2. 🚀 GitHub Actions (Otomatis):"
    echo "      Push ke GitHub, workflow akan otomatis build di Windows"
    echo ""
    echo "   3. 🔧 Cross-compile manual (Advanced):"
    echo "      Memerlukan install library Windows untuk MinGW:"
    echo "      - libgc (Boehm GC)"
    echo "      - libxml2"
    echo "      - libiconv"
    echo "      - libpcre2-8"
    echo "      - libz"
    echo ""
    rm -f "$BUILD_LOG"
    exit 0  # Exit dengan success karena object file sudah dibuat
else
    echo "❌ ERROR: Tidak ada file bin/bridge atau bin/bridge.obj yang dihasilkan!"
    echo "   Periksa error di atas untuk detail lebih lanjut."
    rm -f "$BUILD_LOG"
    exit 1
fi

echo
echo "✅ Build selesai! Executable ada di: bin/bridge.exe"
echo "   File ini bisa dijalankan di Windows."

