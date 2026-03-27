import cloudinary
import cloudinary.uploader
import os
import json
import sys

# ==========================================
# ISI CREDENTIAL CLOUDINARY ANDA DI SINI
# ==========================================
CLOUD_NAME = "devfcmzyj"
API_KEY    = "272226611174238"
API_SECRET = "cJjLilyml64J-os0flGEvrJ_9QA"
# ==========================================

IMAGES_DIR   = "/home/ibnualwan/quran-images"
FOLDER_NAME  = "quran"  # Nama folder di Cloudinary
RESULTS_FILE = "/home/ibnualwan/sample-aplikasi/cloudinary_urls.json"

def upload_images():
    # Konfigurasi Cloudinary
    cloudinary.config(
        cloud_name = CLOUD_NAME,
        api_key    = API_KEY,
        api_secret = API_SECRET,
        secure     = True
    )

    # Ambil semua file jpg dan urutkan
    files = sorted([
        f for f in os.listdir(IMAGES_DIR)
        if f.endswith('.jpg')
    ])

    if not files:
        print("❌ Tidak ada file JPG di folder quran-images!")
        sys.exit(1)

    total = len(files)
    print(f"☁️  Akan upload {total} gambar ke Cloudinary folder '{FOLDER_NAME}'")
    print(f"⚠️  Proses ini bisa memakan waktu 30-60 menit tergantung koneksi")
    print("=" * 55)

    results = {}
    failed  = []

    for i, filename in enumerate(files):
        # Ambil nama tanpa ekstensi sebagai public_id
        public_id   = filename.replace('.jpg', '')
        file_path   = os.path.join(IMAGES_DIR, filename)
        progress    = (i + 1) / total * 100

        # Skip jika sudah ada di results (resume)
        if os.path.exists(RESULTS_FILE):
            with open(RESULTS_FILE, 'r') as f:
                existing = json.load(f)
            if public_id in existing:
                results[public_id] = existing[public_id]
                print(f"⏭️  [{i+1:3d}/{total}] {progress:5.1f}% - Sudah ada: {filename}")
                continue

        try:
            response = cloudinary.uploader.upload(
                file_path,
                folder        = FOLDER_NAME,
                public_id     = public_id,
                resource_type = "image",
                overwrite     = False,
                format        = "jpg"
            )

            url = response['secure_url']
            results[public_id] = url

            print(f"✅ [{i+1:3d}/{total}] {progress:5.1f}% - {filename}")

            # Simpan progress setiap 10 file (untuk resume jika putus)
            if (i + 1) % 10 == 0:
                with open(RESULTS_FILE, 'w') as f:
                    json.dump(results, f, indent=2)

        except Exception as e:
            print(f"❌ [{i+1:3d}/{total}] Gagal upload {filename}: {e}")
            failed.append(filename)

    # Simpan hasil akhir
    with open(RESULTS_FILE, 'w') as f:
        json.dump(results, f, indent=2)

    print("=" * 55)
    print(f"🎉 SELESAI!")
    print(f"✅ Berhasil upload: {len(results)} gambar")
    if failed:
        print(f"❌ Gagal: {len(failed)} gambar → {failed}")
    print(f"📄 URL tersimpan di: {RESULTS_FILE}")
    print("")
    print("📋 Contoh URL gambar pertama:")
    sample_key = list(results.keys())[0] if results else "halaman-001"
    sample_url = results.get(sample_key, f"https://res.cloudinary.com/{CLOUD_NAME}/image/upload/{FOLDER_NAME}/halaman-001.jpg")
    print(f"   {sample_url}")
    print("")
    print("➡️  Simpan Cloud Name ini untuk Next.js:")
    print(f"   NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME={CLOUD_NAME}")

if __name__ == "__main__":
    if "ISI_" in CLOUD_NAME:
        print("❌ Harap isi credential Cloudinary di dalam script dulu!")
        print("   Buka file upload_cloudinary.py dan isi CLOUD_NAME, API_KEY, API_SECRET")
        sys.exit(1)

    upload_images()
