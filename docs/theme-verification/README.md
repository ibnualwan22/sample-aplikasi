# Penerapan tema putih–emas

7 November 2026 · Flutter 3.41.5 · warna utama **#FFCF40**.

Tema telah diterapkan pada kode seluruh layar publik, katalog SIAKAD, Akun, penampil dokumen, QR, ujian dan overlay. Laporan ini membedakan penerapan kode, render fixture, dan pengujian pada perangkat.

## Perubahan

- Satu `ThemeData` terang dan token bersama; warna gelap lama serta gradient dekoratif di `lib/` sudah dihapus. Dialog, sheet, input, pemilih tanggal/waktu, menu, tombol, notifikasi singkat dan navigasi memakai gaya yang sama.
- Beranda mengikuti sampel: sapaan lengkap, maskot, bidang emas solid, jam, salat dan delapan kartu berlabel. Hasil Tes, SIAKAD, Kalender dan Al-Qur’an memiliki tujuan masing-masing. Lainnya tetap memberi akses ke fitur yang sedang disiapkan.
- Ikon Material Rounded di tengah bidang emas; bottom bar selalu berlabel. Grid dan sapaan menyesuaikan teks besar. Di layar sempit dengan teks besar, tombol Halaman umum menjadi ikon dengan tooltip.
- Perizinan dan Lapor Mukholif memakai formulir tunggal, pemilih santri, tanggal, tinjauan dan penanganan gagal kirim yang mempertahankan draf. Request dan aturan hak akses tetap menggunakan kontrak API sebelumnya.
- Nilai, Absensi, Riwayat dan layanan lain menggunakan baris/ekspansi/tombol bersama. Keadaan kosong, gagal dan fitur belum tersedia menggunakan maskot pada konteks yang sesuai. QR tetap hitam di atas putih.
- Kalender dapat digulir dan membedakan gagal memuat dari agenda kosong. Pencarian lokasi menangani hasil kosong, kegagalan, timeout serta respons lama. Dialog Mushaf memvalidasi rentang halaman.
- Font STIX Two Text, Roboto dan Amiri tersedia offline. WebP maskot sekitar 780 KB; PNG asli disimpan untuk pemeliharaan di luar bundel aplikasi. Gambar didekode sesuai ukuran tampil, tanpa renderer 3D.
- Tanggal Hijriah yang sebelumnya ditulis tetap dihapus. Tanggal lokal diperbarui saat pergantian hari. Perhitungan jadwal menggunakan data lokasi runtime dan waktu lokal perangkat, termasuk salat Subuh berikutnya setelah Isya. Detik hanya memperbarui panel waktu melalui notifier.

## Bukti render

Gambar dibuat dari widget aplikasi dengan font asli dan fixture akun. Waktu/tanggal berasal dari lingkungan pengujian; jangan gunakan screenshot sebagai rujukan jadwal salat untuk lokasi atau zona waktu lainnya.

| Tampilan | Bukti |
| --- | --- |
| Panel jadwal salat interaktif | [jadwal-salat.png](jadwal-salat.png) |
| Beranda publik | [beranda.png](beranda.png) |
| Login NIS | [login.png](login.png) |
| Beranda SIAKAD | [siakad.png](siakad.png) |
| Katalog layanan | [layanan.png](layanan.png) |
| Riwayat izin kosong | [perizinan-kosong.png](perizinan-kosong.png) |
| Formulir izin | [perizinan-form.png](perizinan-form.png) |
| Tinjauan sebelum kirim | [perizinan-konfirmasi.png](perizinan-konfirmasi.png) |

## Penyempurnaan modal dan ikon

Aksen emas setiap menu sekarang terpusat di belakang ikon. Jadwal salat berubah menjadi bottom sheet yang dapat digulir: ringkasan dan penanda salat berikutnya, navigasi harian, kalender pemilih tanggal, kembali ke hari ini, serta ekspansi Imsak/Terbit/Dhuha. Sesudah Isya, ringkasan menunjuk Subuh besok dan tidak menandai Subuh hari ini. Hitung mundur diperbarui setiap 30 detik hanya selama panel dibuka. Konfirmasi/input SIAKAD dan konfirmasi ujian juga memakai judul berikon emas.

`prayer_schedule_test.dart` menguji navigasi tanggal, pembukaan date picker, reset hari ini, ekspansi waktu pendukung, penanda sesudah Isya, dan layout 320 dp pada teks 200%.

## Pemeriksaan otomatis

- Baseline: 8 tes lulus; analyzer melaporkan 107 temuan termasuk warning lama.
- Sesudah perubahan: 19 tes, mencakup regresi yang lama serta tambahan tema/formulir. Katalog sempat mengalami target sentuh tes yang belum terlihat penuh; tes diperbaiki agar memastikan halaman katalog benar-benar terbuka.
- Render Beranda pada 320, 390 dan 430 dp; render dasar semua 19 menu katalog dan Akun pada 320 dp dengan teks 200%; pemulihan dari error; login NIS berawalan nol; filter menu sesuai peran dan tujuan Hasil Tes.
- Uji Perizinan memastikan tidak mengirim sebelum konfirmasi dan mempertahankan draf setelah request gagal. Pemilih anggota diuji pada 320 dp, teks 200%, dan inset keyboard 280 dp.
- Render kontrol 13 varian soal: PG, PG_MULTI, MENJODOHKAN, DRAG_KATEGORI, MENGURUTKAN, SUSUN_HURUF, DRAG_TO_BLANK, PARAGRAF_RUMPANG, TABEL_TASRIF, IDENTIFIKASI_KESALAHAN, STABILO_SYNTAX, JARING_RELASI dan ESSAY. Ini pemeriksaan layout, bukan pembuktian lengkap protokol autosave dan penilaian server.
- `flutter analyze`: tidak ada error atau warning; 90 catatan tingkat info, terutama aturan penulisan dan kode lama. Catatan ini tidak disembunyikan melalui konfigurasi analyzer.
- Konfigurasi tanda tangan rilis (`android/key.properties`) belum tersedia; kandidat yang dibuat adalah debug, bukan rilis produksi.
- APK debug dibangun melalui toolchain Android proyek. Lokasi: `build/app/outputs/flutter-apk/app-debug.apk`. APK debug memuat sarana debugging dan bukan ukuran/performa rilis produksi. Build Flutter biasa juga tidak mengaktifkan mesin pembaruan Shorebird.
- `git diff --check` digunakan untuk memeriksa whitespace.

Jalankan ulang dengan `flutter test`. Untuk memperbarui gambar: `flutter test --dart-define=CAPTURE_THEME=true test/theme_flow_test.dart`. Tes menggunakan fixture dan tidak mengirim transaksi ke SIAKAD produksi.

## Pemeriksaan yang masih memerlukan perangkat dan akun uji

- Android fisik: frame profile, scroll, TalkBack, cutout, gesture sistem, kamera/selfie, GPS dan sensor kiblat.
- Transaksi API nyata setiap peran, verifikasi WA, pemilihan, pendaftaran, perubahan akun, akses dokumen dan session-expiry saat modal/formulir terbuka.
- Seluruh status soal, autosave saat putus jaringan, batas waktu ujian, serta perilaku saat aplikasi berada di latar.
- Bacaan dan cache Mushaf, peta/rute, konten Instagram pihak ketiga, PDF/cetak/simpan, serta semua overlay pada data panjang dari server.

Permukaan aplikasi mengikuti tema; isi PDF, foto, peta dan halaman eksternal tetap mengikuti sumbernya. Kotak tahap 3–7 pada rencana belum ditandai penuh karena tahap tersebut juga mensyaratkan pemeriksaan perangkat dan alur produksi di atas. Hal ini tidak berarti layar tersebut masih menggunakan tema lama.
