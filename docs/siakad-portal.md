# SIAKAD Markaz Arabiyah di aplikasi Flutter

## Implementasi native Android
Halaman umum tetap terbuka. Tab SIAKAD memakai login NIS akun website, menyimpan sesi di penyimpanan aman, lalu mengganti bilah bawah ke Beranda, Akademik, Layanan, dan Akun. Halaman umum dapat dibuka tanpa logout. Beranda memakai sumber jam dan jadwal salat yang sama dengan Home. Layar SIAKAD membaca API, tanpa membuka portal melalui WebView.

Lihat [rencana dan daftar alur untuk pengujian](rencana-siakad-native.md). Jaringan diperlukan untuk fitur akademik. Kode akses ujian, OTP nomor WA, verifikasi PPDB dan izin program mengikuti backend. URL portal dapat disetel lewat SIAKAD_PORTAL_URL; gunakan HTTPS untuk rilis. Dokumen resmi diperoleh lewat API yang memeriksa sesi dan kepemilikan, lalu dibuka sebagai PDF. Kartu digital PPDB dibaca tanpa cookie SIAKAD dan ditampilkan di aplikasi. Android dapat menyimpan PDF, gambar kartu, dan PNG syahadah Nadi melalui pemilih berkas sistem; album Drive dibuka atas tindakan pengguna.

Sebelum menguji fitur khusus di HP, deploy perubahan backend dari ijazah-sample (termasuk menu di /api/santri/me dan /api/mobile/dokumen). Gunakan akun uji yang memiliki peran dan data yang sesuai. Build debug dan tes dengan data ilustrasi tidak menggantikan pengujian transaksi di staging atau jalur internal Play.

## Membuat AAB untuk Google Play
1. Untuk aplikasi yang sudah terdaftar, gunakan application ID dan upload key
   dari listing yang sama. Untuk listing baru, tentukan ID permanen dan simpan
   upload keystore beserta cadangannya di tempat privat milik Markaz.
2. Salin `android/key.properties.example` ke `android/key.properties`.
   Isi ID, path absolut ke keystore, alias, dan password secara lokal.
   File berisi password dan file keystore tidak boleh di-commit.
3. Dari direktori aplikasi, jalankan `flutter build appbundle --release`.
   Untuk pembaruan, gunakan build number lebih tinggi dari rilis sebelumnya.
   Hasilnya: `build/app/outputs/bundle/release/app-release.aab`.
4. Uji AAB di jalur pengujian internal Play Console menggunakan akun santri uji.
   APK debug yang disediakan untuk uji HP tidak digunakan untuk publikasi.

[Panduan rilis Android Flutter](https://docs.flutter.dev/deployment/android)
