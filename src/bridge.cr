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

  print "🔤 Masukkan huruf kolom untuk grouping/folder (kosongkan jika tidak perlu): "
  group_column_input = gets.try(&.strip.upcase)
  group_column = group_column_input && !group_column_input.empty? ? group_column_input : nil

  puts "✅ Menggunakan kolom #{no_doc_column} untuk nomor dokumen"
  puts "✅ Menggunakan kolom #{name_column} untuk nama file"
  if group_column
    puts "✅ Menggunakan kolom #{group_column} untuk grouping folder"
  else
    puts "ℹ️  Tidak menggunakan grouping (semua file masuk ke folder outputs)"
  end

  puts

  rows = sheet.rows.to_a
  puts "📊 Memproses #{rows.size} baris data..."
  puts

  # Mapping: no_doc => {new_name, group_folder}
  mapping = {} of String => Tuple(String, String?)
  processed_count = 0

  # Proses semua row data
  rows.each_with_index do |row, index|
    next if row.empty?

    # Cari cell yang dimulai dengan kolom yang dipilih
    no_doc = nil
    fname = nil
    group_folder = nil

    row.each do |cell_ref, value|
      if cell_ref.starts_with?(no_doc_column)
        no_doc = value.to_s.strip
      elsif cell_ref.starts_with?(name_column)
        fname = value.to_s.strip
      elsif group_column && cell_ref.starts_with?(group_column)
        group_value = value.to_s.strip
        # Hanya gunakan jika tidak kosong
        group_folder = group_value.empty? ? nil : group_value
      end
    end

    next if no_doc.nil? || fname.nil? || no_doc.empty? || fname.empty?

    processed_count += 1
    mapping[no_doc] = {fname, group_folder}

    # Progress indicator
    print "\r🔄 Progress: #{processed_count}/#{rows.size} rows processed"
  end

  puts # New line after progress

  {mapping, group_column}
end


# --- Rename berdasarkan mapping ---
def rename_files(dir : String, mapping : Hash(String, Tuple(String, String?)))
  puts "🔍 Scanning folder: #{dir}"

  # Clear folder outputs terlebih dahulu
  output_dir = "./outputs"
  if Dir.exists?(output_dir)
    puts "🧹 Membersihkan folder outputs..."
    clear_directory(output_dir)
    puts "✅ Folder outputs sudah dibersihkan"
    puts
  end

  # Hitung total files dulu
  all_files = Dir.glob("#{dir}/**/*").select { |f| File.file?(f) }
  total_files = all_files.size
  processed_files = 0
  renamed_files = 0
  found_docs = Set(String).new
  created_folders = Set(String).new

  puts "📁 Ditemukan #{total_files} file untuk diproses..."
  puts

  all_files.each do |filepath|
    next unless File.file?(filepath)

    filename = File.basename(filepath)
    processed_files += 1

    # Progress indicator
    print "\r🔄 Processing: #{processed_files}/#{total_files} files"

    # cek apakah mengandung no_doc
    mapping.each do |no_doc, file_info|
      new_name, group_folder = file_info
      
      if filename.downcase.includes?(no_doc.downcase)
        # Buat folder "outputs" jika belum ada
        base_output_dir = "./outputs"
        Dir.mkdir_p(base_output_dir) unless Dir.exists?(base_output_dir)

        # Tentukan folder tujuan (dengan atau tanpa grouping)
        output_dir = if group_folder && !group_folder.empty?
          # Buat folder grouping jika belum ada
          group_path = File.join(base_output_dir, sanitize_folder_name(group_folder))
          Dir.mkdir_p(group_path) unless Dir.exists?(group_path)
          created_folders.add(group_path) unless created_folders.includes?(group_path)
          group_path
        else
          base_output_dir
        end

        # Ambil extension dari file asli
        original_ext = File.extname(filename)
        
        # Jika new_name sudah punya extension, gunakan itu
        # Jika tidak, tambahkan extension dari file asli
        final_name = if new_name.includes?('.')
          new_name
        else
          new_name + original_ext
        end

        new_path = File.join(output_dir, final_name)
        renamed_files += 1
        found_docs.add(no_doc)

        # Tampilkan path relatif untuk output
        relative_path = new_path.gsub(/^\.\//, "")
        puts "\r✅ Copy & Rename (##{renamed_files}):"
        puts "   #{filename} -> #{relative_path}"

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
  if created_folders.size > 0
    puts "   Folders created: #{created_folders.size}"
    created_folders.each do |folder|
      puts "      📁 #{folder.gsub(/^\.\//, "")}"
    end
  end

  if missing_docs.size > 0
    puts
    puts "⚠️  Dokumen yang tidak ditemukan filenya (#{missing_docs.size}):"
    missing_docs.each do |doc|
      file_info = mapping[doc]
      new_name, group_folder = file_info
      group_info = group_folder ? " (folder: #{group_folder})" : ""
      puts "   ❌ #{doc} -> #{new_name}#{group_info}"
    end
  else
    puts "✅ Semua dokumen berhasil ditemukan dan diproses!"
  end
end

# Helper untuk membersihkan isi directory
def clear_directory(dir_path : String)
  return unless Dir.exists?(dir_path)
  
  Dir.each_child(dir_path) do |entry|
    entry_path = File.join(dir_path, entry)
    if Dir.exists?(entry_path)
      # Hapus folder dan isinya secara recursive
      FileUtils.rm_rf(entry_path)
    else
      # Hapus file
      File.delete(entry_path) if File.exists?(entry_path)
    end
  end
end

# Helper untuk sanitize nama folder (menghapus karakter yang tidak valid)
def sanitize_folder_name(name : String) : String
  # Hapus karakter yang tidak valid untuk nama folder di Windows/Linux
  # Ganti dengan underscore
  # Karakter yang tidak valid: < > : " / \ | ? *
  invalid_chars = ['<', '>', ':', '"', '/', '\\', '|', '?', '*']
  result = name
  invalid_chars.each do |char|
    result = result.gsub(char, "_")
  end
  result.strip
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

mapping_result = load_mapping(excel_path)
mapping, group_column = mapping_result
puts "Loaded #{mapping.size} rows."
if group_column
  puts "📁 Grouping aktif menggunakan kolom #{group_column}"
end
puts

rename_files(folder_path, mapping)

puts "Selesai!"
