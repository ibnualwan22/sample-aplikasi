import fitz  # PyMuPDF
import os
import sys

# ==========================================
# KONFIGURASI
# ==========================================
PDF_PATH = "/home/ibnualwan/quran.pdf"
OUTPUT_DIR = "/home/ibnualwan/quran-images"
PDF_START_PAGE = 10   # Halaman PDF tempat Al-Fatihah dimulai (1-indexed)
PDF_END_PAGE = 617    # Halaman PDF terakhir yang dikonversi (1-indexed)
DPI = 150             # Resolusi (150 DPI = kualitas bagus, ukuran sedang)
FORMAT = "jpg"        # Format output (jpg lebih kompatibel)
# ==========================================

def convert_pdf_to_images():
    # Buat folder output jika belum ada
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print(f"📖 Membuka PDF: {PDF_PATH}")
    
    try:
        doc = fitz.open(PDF_PATH)
    except Exception as e:
        print(f"❌ Gagal membuka PDF: {e}")
        sys.exit(1)

    total_pages_pdf = doc.page_count
    print(f"📄 Total halaman di PDF: {total_pages_pdf}")

    # Validasi range
    if PDF_START_PAGE < 1 or PDF_END_PAGE > total_pages_pdf:
        print(f"❌ Range halaman tidak valid! PDF hanya punya {total_pages_pdf} halaman.")
        doc.close()
        sys.exit(1)

    start_idx = PDF_START_PAGE - 1  # Convert ke 0-indexed
    end_idx = PDF_END_PAGE - 1      # Convert ke 0-indexed
    total_to_convert = end_idx - start_idx + 1

    print(f"✅ Akan mengkonversi halaman PDF {PDF_START_PAGE} s/d {PDF_END_PAGE}")
    print(f"✅ Total gambar yang akan dibuat: {total_to_convert}")
    print(f"✅ Output folder: {OUTPUT_DIR}")
    print(f"✅ Resolusi: {DPI} DPI")
    print("")
    print("⏳ Mulai konversi... (ini mungkin butuh 5-15 menit)")
    print("=" * 50)

    zoom = DPI / 72  # PDF default 72 DPI
    mat = fitz.Matrix(zoom, zoom)

    for i, page_idx in enumerate(range(start_idx, end_idx + 1)):
        quran_page_num = i + 1  # Nomor halaman Quran (1-indexed)
        filename = f"halaman-{quran_page_num:03d}.{FORMAT}"
        output_path = os.path.join(OUTPUT_DIR, filename)

        # Skip jika file sudah ada (untuk resume jika terhenti)
        if os.path.exists(output_path):
            print(f"⏭️  [{quran_page_num:3d}/{total_to_convert}] Sudah ada, dilewati: {filename}")
            continue

        try:
            page = doc[page_idx]
            pix = page.get_pixmap(matrix=mat)
            pix.save(output_path, jpg_quality=90)  # Simpan sebagai JPEG kualitas 90
            
            # Progress indicator
            progress = (i + 1) / total_to_convert * 100
            print(f"✅ [{quran_page_num:3d}/{total_to_convert}] {progress:5.1f}% - {filename} ({os.path.getsize(output_path) // 1024} KB)")
        
        except Exception as e:
            print(f"❌ Gagal konversi halaman {page_idx + 1}: {e}")

    doc.close()

    # Hitung total ukuran output
    total_size = sum(
        os.path.getsize(os.path.join(OUTPUT_DIR, f))
        for f in os.listdir(OUTPUT_DIR)
        if f.endswith(f'.{FORMAT}')
    )

    print("=" * 50)
    print(f"🎉 SELESAI!")
    print(f"📁 Gambar tersimpan di: {OUTPUT_DIR}")
    print(f"🖼️  Total file: {total_to_convert} gambar")
    print(f"💾 Total ukuran: {total_size / (1024*1024):.1f} MB")
    print("")
    print("➡️  Langkah selanjutnya: Upload folder quran-images ke Cloudinary!")

if __name__ == "__main__":
    convert_pdf_to_images()
