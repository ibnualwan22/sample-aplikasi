# Ujian mobile — keputusan implementasi

Disetujui 15 November 2026: renderer per jenis soal, keyboard mengikuti web, penguncian resmi dan jawaban lokal persisten sebelum sinkronisasi. Tema putih–emas, tanpa emoji. Teks Arab/Latin dan harakat utuh; tabel dapat digeser, kontrol tetap dapat digunakan pada 320 dp dan orientasi lanskap.

- Keyboard bersumber dari `ijazah-sample/src/lib/exam-keyboard.ts`; urutan dan variasi tidak diubah.
- Penguncian ketat menjadi prasyarat ujian Usbu. Android memerlukan DPC allowlist; iOS memerlukan entitlement AAC yang disetujui Apple. Kegagalan penguncian menghentikan pembukaan soal, tidak menurunkan perlindungan diam-diam. Tauzi tidak menggunakan kebijakan penguncian Usbu.
- Snapshot jawaban memakai penyimpanan aman persisten yang sudah tersedia, antrean penulisan serial dan nomor revisi. Tidak menghapus draf saat logout/kedaluwarsa sesi. Pemulihan hanya ditampilkan untuk akun dan origin yang sama.
- Jawaban offline tersegel saat selesai; unggahan tertunda dicoba ulang. Server mengonfirmasi snapshot lengkap/revisi sebelum klien menganggap sinkron. Paket terlambat disimpan sebagai bukti untuk ditinjau pengawas, bukan dipercaya sebagai bukti waktu pengerjaan dan otomatis mengganti nilai. Jam klien tidak membuktikan jawaban dibuat sebelum tenggat.
- Backend perlu endpoint mobile-sync dan tabel snapshot. Perubahan disiapkan bersama aplikasi; migrasi/deploy produksi tidak dilakukan otomatis.
- Perangkat bebas setelah jawaban tersegel lokal; jaringan putus tidak mengunci perangkat tanpa batas. Draf tetap bisa disinkronkan setelah login kembali. Menutup paksa sebelum penulisan storage selesai tetap merupakan batas platform; status simpan lokal harus jujur dan kegagalan penyimpanan memblokir penyuntingan berikutnya.

Verifikasi: unit test persist/revisi/retry/seal, keyboard Unicode, widget setiap jenis soal/320 dp, analisis Dart dan build Android jika SDK mendukung. Pengujian AAC memerlukan Mac, profil entitlement sah dan perangkat Apple; pengujian Lock Task memerlukan perangkat Android terkelola.
