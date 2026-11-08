# Pembenahan UI/UX SIAKAD — 8 November 2026

Perubahan ini membenahi isi layar, ringkasan, pilihan, detail dan formulir. Acuan adalah kode website di proyek `ijazah-sample`, khususnya `src/app/santri/(portal)` dan `src/components/santri`. Adaptasi memakai Flutter dan palet putih–emas #FFCF40. Bukan hanya penambahan ikon/pengantar.

| Halaman | Perubahan pada UI/UX | Render Flutter |
| --- | --- | --- |
| Absensi | Pilih periode, kategori, akumulasi Hadir/Alpa/Izin/Sakit dari rekap server; ketuk angka untuk menyaring catatan tanggal. Data tidak tersedia tetap “—”. | [Screenshot](siakad-absensi.png) |
| Nilai | Satu periode terpilih, ringkasan hasil belajar, nilai Usbu/Nihai per mapel, dokumen dan transkrip gabungan. | [Screenshot](siakad-nilai.png) |
| Riwayat | Linimasa program/kelas, rata-rata/status terlihat langsung, detail periode dan dokumen dalam panel. | [Screenshot](siakad-riwayat.png) |
| Perizinan | Pilihan periode, total/aktif, filter status, kartu izin dengan tindakan terlihat; tasrih dalam panel detail. | [Screenshot](siakad-perizinan.png) |
| Ujian | Filter tersedia/lainnya, status, jumlah soal/durasi, tombol Mulai/Lanjut langsung terlihat; review tetap mengikuti hak server. | [Screenshot](siakad-ujian.png) |
| Hasil Tes | Ringkasan per tahap dan daftar hasil per mapel. | [Screenshot](siakad-hasil-tes.png) |
| QR Saya | Bidang QR menyesuaikan lebar HP, identitas, tombol mode scan, daftar kehadiran terkonfirmasi. | [Screenshot](siakad-qr-saya.png) |
| Tasmi’ | Total sesi dan juz terakhir, kartu penilaian Tahfidz/Tahsin/Tartil/Adab, rata-rata dan catatan penguji. | [Screenshot](siakad-tasmi.png) |
| Nadi Hufadz | Status pendaftaran, catatan setoran per periode, hasil dan dokumen. | [Screenshot](siakad-nadi-hufadz.png) |
| Daftar ulang | Masa aktif/program langsung terlihat; tagihan menggunakan ringkasan nominal/nomor, tindakan salin dan konfirmasi. | [Screenshot](siakad-daftar-ulang.png) |
| Check out | Pengajuan dan tahapan persetujuan terlihat, alasan dapat ditulis beberapa baris. | [Screenshot](siakad-check-out.png) |
| Galeri | Kartu album dengan periode/tanggal dan tombol Buka di Google Drive, pilihan periode tetap tersedia. | [Screenshot](siakad-galeri.png) |
| Denah Sakan | Pencarian lokasi, ketuk nama memusatkan peta, tombol rute terpisah dan berlabel. | Keadaan tanpa data tercakup pengujian; peta/rute nyata perlu perangkat dan jaringan. |
| Pemilihan | Kartu kandidat terlihat langsung, foto bila tersedia, visi/misi, status sesi dan tindakan memilih. | [Screenshot](siakad-pemilihan.png) |
| Berita Acara | Ringkasan belum/sudah diisi, filter, kartu sesi dan satu formulir kehadiran/keterlambatan/catatan dengan validasi dan pemulihan gagal. | [Halaman](siakad-berita-acara.png), [Modal saat gagal](siakad-berita-acara-modal.png) |
| Lapor Mukholif | Tombol laporan utama, jumlah laporan, kartu kejadian/tanggal; formulir pengajuan bersama tetap tersedia. | [Screenshot](siakad-lapor-mukholif.png) |
| Eksekusi Iqob | Daftar tugas per santri dengan konteks kelas/sakan, tanggal laporan dan penanda tugas selesai. | [Screenshot](siakad-eksekusi-iqob.png) |
| Tauzi’ Fushul | Bagian program, pengerjaan, dan hasil terpisah; hasil dalam panel detail bergulir. | [Screenshot](siakad-tauzi-fushul.png) |
| Akun | Identitas/status, tempat tinggal, masa belajar/kartu dikelompokkan. | [Screenshot](siakad-akun.png) |
| WhatsApp AI | Status hubungan nomor dan tombol verifikasi yang jelas. | [Screenshot](siakad-whatsapp-ai.png) |

## Bukti dan batas pengujian

- Screenshot berasal dari widget Flutter produksi menggunakan fixture `test/siakad_preview_test.dart`, ukuran 390 × 844 dp. Angka, nama, laporan dan status pada gambar adalah **data contoh**, bukan data akun nyata.
- 19 halaman dengan isi diuji pada 320 dp dan skala teks 200%; Denah Sakan diuji melalui keadaan tanpa data pada cakupan katalog.
- Pengujian interaksi memeriksa filter Alpa, penggantian periode, validasi keterlambatan, dan draf Berita Acara yang tetap ada saat pengiriman gagal.
- Analisis Flutter tidak menemukan error atau warning. Masih ada catatan gaya/info di proyek.
- Uji widget tidak menggantikan pengujian login/transaksi nyata, kamera, lokasi/rute, penyimpanan dokumen, atau pemilihan dengan server produksi. Screenshot juga tidak mengukur performa pada HP fisik.
- Helper screenshot memperbarui lapisan render sebelum mengambil gambar agar pergantian halaman pada pengujian tidak menghasilkan gambar sebagian.
