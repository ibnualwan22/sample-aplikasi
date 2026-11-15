# Verifikasi ujian mobile — 15 November 2026

## Hasil

| Pemeriksaan | Hasil |
| --- | --- |
| Suite Flutter keseluruhan | 67 lulus, 2 gagal pada halaman Tentang karena aset foto tidak tersedia |
| Suite terfokus ujian + cakupan tema | 15 lulus; termasuk 22 tipe (21 tipe web dan ESSAY lama), layar 320 dp, pembesaran teks |
| Alur jawaban offline | Lulus: tersegel lokal, dibuka kembali, dikirim dengan snapshot yang sama |
| Pemulihan proses terhenti | Lulus: penanda ujian berjalan menyebabkan seal LOCK_LOST, tanpa membuka ulang penyuntingan |
| Keyboard | Lulus: urutan karakter, harakat, hapus Unicode, tekan lama lam-alif, lanskap |
| Sesi login habis | Lulus: token dihapus, draf lama dan snapshot baru tetap ada |
| Kontrak endpoint backend | Lulus: kepemilikan, satu client, revisi, duplikasi, konflik, seal, arsip terlambat |
| Finalisasi backend | Lulus: semua operasi memakai koneksi transaksi yang sama, retry idempoten, rollback, LOCK_LOST tidak dihitung sebagai bukti kecurangan |
| Analisis Dart pada perubahan | Tidak ada error/warning; masih ada info lint gaya dan deprecation yang dicatat analyzer |
| Prisma schema validate | Lulus |
| TypeScript backend | Pemeriksaan keseluruhan gagal pada berkas di luar perubahan ini; tidak ada diagnostik pada endpoint mobile, jawab, atau helper finalisasi |
| Kotlin MainActivity | Kompilasi langsung dengan Android SDK + Flutter embedding lulus |
| APK/Gradle lengkap | Belum berhasil: konfigurasi Firebase android/app/google-services.json tidak tersedia |
| Build iOS | Belum diuji: membutuhkan Mac/Xcode dan provisioning AAC |
| PostgreSQL staging dan penguncian perangkat fisik | Belum dijalankan |

## Lingkungan dan batas

Flutter 3.41.5. Tes memakai salinan lib/test yang sama di `/tmp/markaz-exam-tests`. Deklarasi satu aset `assets/images/aksara-ksu-batch10.jpg` dikecualikan dari pubspec salinan agar bundling tes lain dapat berjalan; berkas ini memang tidak tersedia di repo. Dua tes Tentang tetap dijalankan dan gagal saat memuat foto tersebut. Pubspec dan lockfile repo tidak diubah untuk mengakali masalah aset/dependency.

Tes backend menguji kode nyata dengan database tiruan. Tes ini tidak membuktikan perilaku konkurensi PostgreSQL, DPC Android, ataupun AAC Apple. Migrasi/deploy produksi belum dijalankan. Penguncian yang gagal mencegah soal dibuka.

Retry dilakukan selama halaman ujian aktif dan saat daftar ujian terbuka kembali untuk akun yang sama. Tidak ada klaim unggah tetap berjalan saat sistem mematikan aplikasi. Jawaban terlambat tetap diarsipkan tetapi memerlukan peninjauan pengawas; tidak otomatis mengganti nilai yang sudah final.

## Preview

Screenshot dari widget Flutter, data soal contoh dan bridge penguncian tiruan. Diperiksa secara visual: tidak ada overflow; tabel dibuka dari sisi kanan dan dapat digeser; keyboard tetap berada di bawah.

- [Jawaban Arab dan keyboard](ujian-keyboard-mobile.png)
- [Tabel tasrif](ujian-tasrif-mobile.png)

Petunjuk aktivasi tersedia di [panduan backend dan platform](../backend-ujian-mobile/README.md).
