require "xlsx-parser"
require "file_utils"

# ===============================================
#           BRIDGE - File Renamer Tool
# ===============================================
# Aplikasi untuk mengganti nama file berdasarkan
# mapping dari file Excel list.xlsx
# ===============================================

puts "🌉 BRIDGE - File Renamer Tool v1.0"
puts "═" * 50
puts "Memulai proses rename file..."
puts

# --- Helper untuk membaca excel ---
def load_mapping(path : String)
  puts "Membaca Excel: #{path}"

  xlsx = XlsxParser::Book.new(path)
  sheet = xlsx.sheets.first

  header = sheet.rows.first

  puts "📋 Informasi Header Excel:"
  header.each do |cell_ref, value|
    puts "   #{cell_ref}: '#{value}'"
  end
  puts

  # Input manual untuk kolom
  print "🔤 Masukkan huruf kolom untuk nomor dokumen (A, B, C, dst): "
  no_doc_column = gets.try(&.strip.upcase)
  raise "❌ Input kolom nomor dokumen tidak valid!" unless no_doc_column && no_doc_column.size == 1

  print "🔤 Masukkan huruf kolom untuk nama file (A, B, C, dst): "
  name_column = gets.try(&.strip.upcase)
  raise "❌ Input kolom nama file tidak valid!" unless name_column && name_column.size == 1

  puts "✅ Menggunakan kolom #{no_doc_column} untuk nomor dokumen"
  puts "✅ Menggunakan kolom #{name_column} untuk nama file"

  puts

  rows = sheet.rows.to_a
  puts "📊 Memproses #{rows.size} baris data..."
  puts

  mapping = {} of String => String
  processed_count = 0

  # Proses semua row data
  rows.each_with_index do |row, index|
    next if row.empty?

    # Cari cell yang dimulai dengan A (untuk no_doc) dan B (untuk file name)
    no_doc = nil
    fname = nil

    row.each do |cell_ref, value|
      if cell_ref.starts_with?(no_doc_column)
        no_doc = value.to_s.strip
      elsif cell_ref.starts_with?(name_column)
        fname = value.to_s.strip
      end
    end

    next if no_doc.nil? || fname.nil? || no_doc.empty? || fname.empty?

    processed_count += 1
    mapping[no_doc] = fname

    # Progress indicator
    print "\r🔄 Progress: #{processed_count}/#{rows.size} rows processed"
  end

  puts # New line after progress

  mapping
end


# --- Rename berdasarkan mapping ---
def rename_files(dir : String, mapping : Hash(String, String))
  puts "🔍 Scanning folder: #{dir}"

  # Hitung total files dulu
  all_files = Dir.glob("#{dir}/**/*").select { |f| File.file?(f) }
  total_files = all_files.size
  processed_files = 0
  renamed_files = 0
  found_docs = Set(String).new

  puts "📁 Ditemukan #{total_files} file untuk diproses..."
  puts

  all_files.each do |filepath|
    next unless File.file?(filepath)

    filename = File.basename(filepath)
    processed_files += 1

    # Progress indicator
    print "\r🔄 Processing: #{processed_files}/#{total_files} files"

    # cek apakah mengandung no_doc
    mapping.each do |no_doc, new_name|
      if filename.downcase.includes?(no_doc.downcase)
        # Buat folder "replaced" jika belum ada
        replaced_dir = "./outputs"
        Dir.mkdir_p(replaced_dir) unless Dir.exists?(replaced_dir)

        new_path = File.join(replaced_dir, new_name)
        renamed_files += 1
        found_docs.add(no_doc)

        puts "\r✅ Copy & Rename (##{renamed_files}):"
        puts "   #{filename} -> outputs/#{new_name}"

        FileUtils.cp(filepath, new_path)
        break
      end
    end
  end

  puts "\r" + " " * 50 + "\r" # Clear progress line
  
  # Cari no_doc yang tidak ditemukan filenya
  missing_docs = mapping.keys.to_set - found_docs
  
  puts "📊 Summary:"
  puts "   Total files scanned: #{total_files}"
  puts "   Files renamed: #{renamed_files}"
  puts "   Files skipped: #{total_files - renamed_files}"
  
  if missing_docs.size > 0
    puts
    puts "⚠️  Dokumen yang tidak ditemukan filenya (#{missing_docs.size}):"
    missing_docs.each do |doc|
      puts "   ❌ #{doc} -> #{mapping[doc]}"
    end
  else
    puts "✅ Semua dokumen berhasil ditemukan dan diproses!"
  end
end

# Ambil argumen dari command line atau gunakan default
excel_path = ARGV.size >= 1 ? ARGV[0] : "./list.xlsx"
folder_path = ARGV.size >= 2 ? ARGV[1] : "./raw_files"

puts "📄 Excel file: #{excel_path}"
puts "📁 Source folder: #{folder_path}"
puts

# Cek apakah file Excel ada
unless File.exists?(excel_path)
  puts "❌ ERROR: File #{excel_path} tidak ditemukan!"
  puts "   Mohon pastikan file Excel ada atau gunakan:"
  puts "   ./bridge <path_excel> <path_folder>"
  puts "   Contoh: ./bridge sample_mapping.xlsx files"
  exit(1)
end

# Cek apakah folder source ada
unless Dir.exists?(folder_path)
  puts "❌ ERROR: Folder #{folder_path} tidak ditemukan!"
  puts "   Mohon pastikan folder source ada."
  exit(1)
end

mapping = load_mapping(excel_path)
puts "Loaded #{mapping.size} rows."

rename_files(folder_path, mapping)

puts "Selesai!"
