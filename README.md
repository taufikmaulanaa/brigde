# 🌉 BRIDGE - File Renamer Tool

Aplikasi untuk mengganti nama file secara batch berdasarkan mapping dari file Excel.

## 📋 Deskripsi

BRIDGE adalah tool yang membantu Anda mengganti nama file secara massal berdasarkan data yang ada di file Excel. Aplikasi akan mencocokkan nomor dokumen yang ada di nama file dengan mapping di Excel, kemudian mengganti nama file sesuai dengan nama yang diinginkan.

## ✨ Fitur

- ✅ Membaca mapping dari file Excel (.xlsx)
- ✅ Input manual untuk memilih kolom Excel yang akan digunakan
- ✅ Progress indicator untuk proses yang lebih smooth
- ✅ Summary report hasil rename
- ✅ Support command line arguments
- ✅ Copy file ke folder `outputs` dengan nama baru
- ✅ Validasi file dan folder sebelum memproses

## 🚀 Cara Penggunaan

### 1. Persiapan File Excel

Buat file Excel yang berisi mapping dengan struktur seperti ini:

| no. doc | file name        |
|---------|------------------|
| DOC001  | Invoice-Jan.pdf  |
| DOC002  | Report-Feb.pdf   |
| DOC003  | Notes-March.pdf  |

### 2. Struktur File

Pastikan struktur folder seperti ini:
```
├── list.xlsx           # File Excel mapping (default)
├── raw_files/          # Folder berisi file yang akan direname (default)
├── outputs/            # Folder hasil rename (dibuat otomatis)
└── bridge              # Executable program
```

### 3. Menjalankan Program

#### Cara 1: Menggunakan default path
```bash
./bridge
```

#### Cara 2: Menentukan path Excel dan folder sendiri
```bash
./bridge sample_mapping.xlsx files
```

#### Cara 3: Menggunakan Crystal shards (untuk development)
```bash
shards run
```

### 4. Proses Interactive

Setelah program berjalan, Anda akan diminta untuk:

1. **Memilih kolom nomor dokumen**: Masukkan huruf kolom (A, B, C, dll) yang berisi nomor dokumen
2. **Memilih kolom nama file**: Masukkan huruf kolom (A, B, C, dll) yang berisi nama file baru

Program akan menampilkan header Excel untuk membantu Anda memilih kolom yang tepat.

## 📊 Output

Program akan menampilkan:
- ✅ Progress real-time saat memproses file
- ✅ Informasi setiap file yang berhasil direname
- ✅ Summary lengkap di akhir proses

Contoh output:
```
🌉 BRIDGE - File Renamer Tool v1.0
══════════════════════════════════════════════════
📄 Excel file: ./list.xlsx
📁 Source folder: ./raw_files

📋 Informasi Header Excel:
   A1: 'no. doc'
   B1: 'file name'

🔤 Masukkan huruf kolom untuk nomor dokumen (A, B, C, dst): A
🔤 Masukkan huruf kolom untuk nama file (A, B, C, dst): B

✅ Copy & Rename (#1):
   client_DOC001_original.pdf -> outputs/Invoice-Jan.pdf

📊 Summary:
   Total files scanned: 10
   Files renamed: 3
   Files skipped: 7
```

## ⚙️ Cara Kerja

1. Program membaca file Excel yang berisi mapping nomor dokumen ke nama file baru
2. Scan semua file di folder source
3. Untuk setiap file, cek apakah nama file mengandung nomor dokumen dari Excel
4. Jika cocok, copy file ke folder `outputs` dengan nama file baru
5. File asli tetap tidak berubah (hanya copy, tidak move)

## Installation

### Linux / macOS

```bash
# Clone repository
git clone <repository-url>
cd bridge

# Install dependencies
shards install

# Build executable
shards build

# Run
./bin/bridge
```

### Windows

#### Cara 1: Build langsung di Windows (Recommended)

1. **Install Crystal untuk Windows:**
   - Download dari: https://crystal-lang.org/install/
   - Atau gunakan package manager:
     ```powershell
     # Menggunakan Scoop
     scoop install crystal
     
     # Menggunakan Chocolatey
     choco install crystal
     ```

2. **Build executable:**
   ```powershell
   # Install dependencies
   shards install
   
   # Build untuk Windows (HANYA di Windows!)
   .\build-windows.ps1
   
   # Atau manual
   crystal build src/bridge.cr --release -o bin/bridge.exe
   ```
   
   ⚠️ **PENTING**: File `build-windows.ps1` adalah PowerShell script dan **HANYA bisa dijalankan di Windows**.
   Jika Anda di Linux/macOS, gunakan `./build-windows.sh` untuk cross-compile (atau gunakan GitHub Actions).

3. **Jalankan:**
   ```powershell
   .\bin\bridge.exe
   ```

#### Cara 2: Cross-compile dari Linux/macOS

Jika Anda ingin build untuk Windows dari Linux atau macOS:

1. **Install MinGW-w64:**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install gcc-mingw-w64-x86-64
   
   # macOS
   brew install mingw-w64
   ```

2. **Build menggunakan script:**
   ```bash
   chmod +x build-windows.sh
   ./build-windows.sh
   ```

3. **File executable akan ada di `bin/bridge.exe`**

## Usage

Untuk penggunaan sehari-hari, gunakan executable yang sudah di-build:

**Linux/macOS:**
```bash
./bridge [excel_file] [source_folder]
```

**Windows:**
```powershell
.\bin\bridge.exe [excel_file] [source_folder]
```

## ❓ Troubleshooting

### File Excel tidak ditemukan
```
❌ ERROR: File ./list.xlsx tidak ditemukan!
```
**Solusi**: Pastikan file Excel ada di lokasi yang benar atau gunakan path yang tepat.

### Folder source tidak ditemukan
```
❌ ERROR: Folder ./raw_files tidak ditemukan!
```
**Solusi**: Pastikan folder yang berisi file-file yang akan direname sudah ada.

### Kolom tidak valid
```
❌ Input kolom nomor dokumen tidak valid!
```
**Solusi**: Masukkan hanya satu huruf kolom (A, B, C, dll).

## Development

Untuk development:

**Linux/macOS:**
```bash
# Run tanpa build
shards run

# Run dengan arguments
shards run -- sample.xlsx files

# Build untuk production
shards build --release
```

**Windows:**
```powershell
# Run tanpa build
shards run

# Run dengan arguments
shards run -- sample.xlsx files

# Build untuk production
crystal build src/bridge.cr --release -o bin/bridge.exe
```

## Contributing

1. Fork it (<https://github.com/taufikmaulanaa/bridge/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## 🚀 Build Otomatis (CI/CD)

Proyek ini menggunakan GitHub Actions untuk build otomatis untuk Windows. Setiap push ke branch `main` atau `master` akan otomatis build executable Windows.

- **Workflow file**: `.github/workflows/build-windows.yml`
- **Artifact**: Executable Windows akan tersedia sebagai artifact di GitHub Actions
- **Release**: Saat membuat release, executable akan otomatis di-attach ke release

## Contributors

- [taufikmaulanaa](https://github.com/taufikmaulanaa) - creator and maintainer
