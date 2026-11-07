# Rencana penerapan tema Markaz Arabiyah

Disusun 7 November 2026 berdasarkan inventaris kode Flutter. Implementasi tema telah diterapkan pada kode Flutter. Status pemeriksaan dicatat di [laporan penerapan](theme-verification/README.md); kotak tahap mencakup seluruh syarat tahap, termasuk pengujian perangkat yang belum dilakukan. Setiap kotak centang di bawah baru ditandai setelah hasilnya diperiksa pada aplikasi yang dirender.

Acuan visual adalah [sampel Beranda yang diterima](beranda-maskot-emas.png) dan [DESIGN.md](../DESIGN.md). Sasaran pekerjaan mencakup seluruh halaman publik, 19 menu katalog SIAKAD, Akun, layar turunannya, modal, pemilih, pesan umpan balik, dan keadaan layar. Tema putih–emas solid memakai #FFCF40, maskot milik pemilik, ikon modern dengan label, serta latar maskot sederhana.

## Temuan awal sebelum migrasi dan batas pekerjaan

- Sebelum migrasi, tema global di `lib/main.dart` masih gelap. Sejumlah halaman memiliki konstanta warna, latar kartu, warna teks, gradient, dan gaya dialog tersendiri. Audit juga mencakup HTML yang dibungkus aplikasi, CustomPainter kompas, QR, dan kontrol paket pihak ketiga.
- Katalog `lib/siakad/catalog.dart` memiliki 19 fitur. `SiakadPortalScreen` mengelola login, Beranda, Akademik, Layanan, Semua fitur, serta Akun. `FeaturePage` dan ekstensi layanan membangun sebagian besar isi secara dinamis. Satu perubahan helper dapat berdampak pada banyak fitur.
- `confirm`, `ask`, dan `choose` di `lib/siakad/features.dart` digunakan ulang pada banyak transaksi. Dialog ujian, kalender/tanggal/jam, tafsir, unduhan mushaf, pembaruan aplikasi, dan bottom sheet layanan masih punya jalur pembukaan tersendiri.
- Notifikasi, Wirid & Doa, Lainnya, Pencarian umum dan cabang Semua Artikel saat ini menuju pemberitahuan pengembangan. Tab Setelan masih berupa teks. Setiap tujuan mendapat keadaan “Belum tersedia” yang jelas dengan maskot, judul fitur, dan tindakan kembali. Catat kesiapan fungsi terpisah dari pemeriksaan tampilan.
- Dokumen dan media memakai sumber yang sudah tersedia. Pembungkus penampil, toolbar, pemilih, serta pesan di aplikasi mengikuti tema. Isi PDF, halaman mushaf, foto, peta, kamera sistem, izin Android, dan dialog simpan/cetak mengikuti format sumber atau penyedia masing-masing. Periksa transisi masuk dan kembali pada semuanya.
- Tindakan layanan mengikuti API, hak akun, dan aturan status saat ini. Rekening, periode, hasil ujian, tanggal, dan klaim berhasil harus menggunakan sumber produk yang sah. Angka pada sampel gambar adalah data contoh.

## Kontrak komponen bersama

| Bagian | Aturan yang digunakan di seluruh aplikasi |
| --- | --- |
| Warna | Putih #FFFFFF untuk bidang utama, gading #FFFCF3 untuk sapaan, tint #FFF8DF untuk pendukung, emas #FFCF40 untuk bidang pilihan dan aksen. Teks utama #292A26, sekunder #676862, pemisah #E8E6DF. Status sukses, peringatan dan gagal memakai token semantik beserta label. |
| Kontras | Teks dan ikon di atas emas berwarna arang. Tautan dan tombol teks pada putih menggunakan tinta yang cukup gelap. Periksa outline input, fokus, indikator pilihan, progres dan kontrol nonteks pada rasio 3:1. Target teks biasa 4,5:1. |
| Huruf | Usulan teknis adalah STIX Two Text untuk identitas, judul besar dan jam, Roboto untuk navigasi, formulir serta data. Cocokkan secara visual dengan sampel sebelum menyebarkan. Bundel font beserta lisensi untuk penggunaan offline. Pertahankan dukungan font Arab, harakat dan arah RTL yang dipakai pembaca. |
| Ukuran | Margin HP 16–24 dp, ritme 4/8 dp. Isi 14–16 sp, judul layar 22–26 sp, label kecil minimal 12 sp sebagai titik awal. Teks sistem dapat membesar sampai 200%. Jam memakai angka tabular. |
| Permukaan | Kartu fitur putih hangat dengan batas tipis netral, ikon dan nama. Usulan radius kartu 14 dp, input/tombol 12 dp, dialog/sheet 20 dp. Daftar data memakai baris dengan hierarki yang jelas. |
| Ikon | Satu katalog ikon yang memetakan nama fitur ke simbol. Siluet arang, detail emas secukupnya, ukuran 24–28 dp. Tab aktif memiliki bidang emas serta label tegas. Uji Al-Qur’an, Tafsir, Jadwal Salat, Kalender, dan SIAKAD agar masing-masing mudah dikenali. |
| Navigasi | Publik memakai Beranda, Al-Qur’an, SIAKAD, Kalender, Setelan. Ruang santri memakai Beranda, Akademik, Layanan, Akun. Satu bilah aktif sesuai ruang. Tombol kembali dan Halaman umum mengikuti tujuan serta sesi pengguna. |
| Kontrol | Atur app bar, tab, tombol utama/sekunder, input, dropdown, chip, checkbox, radio, switch, slider, indikator progres, ekspansi detail, tooltip dan menu konteks dari tema yang sama. Sertakan enabled, disabled, pressed, focused, selected dan error. |
| Bahasa | Label fitur dan tindakan memakai Indonesia yang konsisten. Pesan gagal menyebut tindakan pemulihan. Pesan berhasil mengikuti respons server. Error teknis dapat dicatat untuk diagnosis, sedangkan pesan pengguna disesuaikan konteks. |
| Gerak | Usulan respons sentuh 90–120 ms dan transisi buka 160–200 ms. Umpan balik input langsung. Hormati pengaturan kurangi gerakan. Matikan animasi dekorasi saat layar ditutup atau aplikasi di latar. |

Implementasi awal menggunakan `ThemeData` dan token semantik pada satu lokasi. `ColorScheme` harus memetakan emas secara eksplisit agar komponen otomatis tetap mengikuti #FFCF40. Periksa surface tint dan state overlay pada versi Flutter yang terpasang. Audit warna lama berdasarkan fungsinya, termasuk warna hasil benar/salah, tanda pencarian, dan garis peta.

Usulan lokasi kode baru adalah `lib/theme/` untuk tema, token dan katalog ikon, serta `lib/widgets/` untuk komponen yang memang digunakan berulang. Pertahankan API publik komponen lama atau sediakan pengalihan sementara saat migrasi. Mulai dengan tema, kartu fitur, tampilan status, serta pembungkus dialog/sheet. Tambah abstraksi hanya ketika ada kebutuhan bersama yang nyata.

## Maskot dan aset

Pemilik sudah menyiapkan 10 pose dalam lima gambar tunggal dan satu lembar berisi lima pose. Sumber yang ditemukan berada di folder Temp Windows, sehingga tahap aset perlu menyalin sumber ke lokasi proyek yang awet sebelum konversi.

| Pemakaian | Pose utama | Cara tampil |
| --- | --- | --- |
| Sapaan Beranda | Melambai, versi lembar tambahan sesuai sampel terakhir | Di sisi kanan sapaan dengan satu bidang lengkung emas. |
| Fitur belum tersedia | Membawa papan | Judul fitur, penjelasan pendek dan Tutup/Kembali. |
| Data kosong | Melihat map kosong | Sesuaikan dengan objek, misalnya “Belum ada riwayat izin”. Tawarkan aksi yang tersedia. |
| Gagal memuat | Tangan terbuka membantu | Pesan kegagalan dan Coba lagi. Pertahankan isi formulir bila ada. |
| Kiriman berhasil | Jempol atau tanda centang | Setelah server mengakui tindakan, gunakan pada hasil yang perlu ditinjau. |
| Petunjuk singkat | Pose berpikir dari lembar tambahan | Penjelasan pertama penggunaan jika langkahnya membutuhkan konteks. |
| Perayaan | Pose gembira tambahan | Gunakan sesuai hasil yang pantas dirayakan dan telah dikonfirmasi. |

Pose tambahan boleh menjadi varian pada keadaan yang sama. Buat pemetaan nama aset berdasarkan isi yang diperiksa. Siapkan PNG sumber serta WebP berukuran tampil untuk Flutter. Periksa transparansi, tepi tubuh, tulisan Arab, arah wajah, dan pemisahan antarkarakter pada lembar pose. Detail dengan angka padat, bacaan Al-Qur’an, QR, dan pengerjaan ujian memakai ruang fokus penuh. Sapaan dan keadaan kosong merupakan tempat utama maskot.

Target awal aset runtime seluruh pose sekitar 1 MB atau kurang, lalu ukur hasil kualitas dan decode. Muat pose yang dibutuhkan layar. Pencahayaan karakter berasal dari gambar statis. Indikator memuat memakai komponen progres ringan dan teks, dengan jeda tampilan yang menghindari kedipan maskot ketika respons cepat.

## Cakupan halaman publik

| ID | Halaman dan jalur | Pekerjaan dan bukti selesai |
| --- | --- | --- |
| P01 | Beranda · `home_screen.dart` | Sapaan lengkap, maskot, tanggal, jam, lokasi, waktu salat berikutnya, jadwal, seluruh pintasan, banner serta konten Instagram mengikuti tema. Cek tanggal pergantian hari, sumber Hijriah, lokasi bawaan dan izin ditolak. |
| P02 | Navigasi publik · `main_layout.dart` | Ikon berlabel, pilihan aktif, status bar dan area gesture Android. Periksa pergantian tab serta tujuan Hasil Tes setelah login. |
| P03 | Al-Qur’an · `quran_screen.dart` | Daftar Surah/Juz, pencarian, jumlah ayat, Arab, tab aktif, hasil kosong dan unduhan offline. |
| P04 | Baca surah · `surah_detail_screen.dart` | Ayat, terjemah, nomor ayat, ubah ukuran teks, salin, tafsir dan pintasan mushaf. Periksa harakat serta panjang teks. |
| P05 | Mushaf · `mushaf_viewer_screen.dart` | Toolbar, pindah halaman, lompat halaman, cache, kegagalan gambar serta coba lagi. Halaman mushaf ditampilkan utuh sesuai sumber. |
| P06 | Tafsir · `tafsir_screen.dart` | Pencarian, saran ayat, chip kitab, hasil, salin, keadaan awal/kosong/gagal, bacaan Arab. |
| P07 | Kiblat · `kiblat_screen.dart` | Kompas dan CustomPainter, status sensor, lokasi, izin dan instruksi kalibrasi yang tersedia. Ukur animasi arah pada HP. |
| P08 | Kalender · `calendar_screen.dart` | Bulan, hari terpilih, hari ini, agenda serta pergantian bulan. Cek kosong dan gagal mengambil agenda. |
| P09 | Denah Sakan publik · `denah_sakan_screen.dart` | Peta, filter umum/banin/banat, marker, rute, tombol lokasi, izin dan kegagalan rute. |
| P10 | Instagram · `instagram_grid_screen.dart` dan pembungkus Beranda | Grid, loading gambar, kegagalan, buka aplikasi eksternal, dan pembungkus HTML/WebView. Periksa pembungkus yang masih memberi latar gelap. |
| P11 | Setelan dan fitur pengembangan | Beri tujuan yang jelas bagi Setelan, Notifikasi, Wirid & Doa, Lainnya, Pencarian umum, dan Semua Artikel. Gunakan keadaan belum tersedia untuk tujuan yang belum punya alur. Verifikasi jalur yang benar-benar dapat dicapai. |
| P12 | Rute lama · `hasil_tes_screen.dart`, `sigma_laporan_screen.dart` | Ikuti portal yang sama. Periksa pembukaan langsung dan tombol kembali. |

Sampel terbaru menampilkan delapan pintasan Al-Qur’an, Jadwal Salat, Kiblat, Tafsir, Denah Sakan, Hasil Tes, Kalender dan SIAKAD. Saat menyamakan Beranda dengan sampel, catat perpindahan akses menu lama dan beri jalur Lainnya yang dapat ditemukan. Daftar fitur pengembangan tetap dapat diakses beserta statusnya.

## Ruang SIAKAD dan semua menunya

Kerjakan shell `lib/screens/siakad_portal_screen.dart` lebih dahulu. Cakup login NIS, pemeriksaan/pemulihan sesi, kegagalan login, Beranda santri, Semua fitur, Akademik, Layanan, Akun, identitas santri, tugas yang menunggu, dan tombol Halaman umum. Nilai NIS tetap berupa teks termasuk nol di awal. Beranda publik dan santri menggunakan data waktu/lokasi yang sama melalui `lib/siakad/prayer.dart`.

Untuk setiap baris di bawah, periksa daftar → detail → pemilih/formulir → konfirmasi → hasil tindakan → kembali. Isi yang memang hanya dapat dibaca diuji sampai detail dan navigasi kembali.

| ID | Menu | Cakupan detail dan tindakan |
| --- | --- | --- |
| S01 | Nilai | Periode, kelas, rata-rata, nilai per mapel/usbu/nihai, kelulusan, transkrip gabungan, transkrip dan syahadah sesuai hak. |
| S02 | Absensi | Rekap dan rincian Kelas, Sakan, Kegiatan, Tabirot, tanggal, keterangan serta status hadir. |
| S03 | Ujian | Paket, status, kode akses, mulai/lanjut, skor, review jawaban serta halaman pengerjaan. |
| S04 | QR Saya | Identitas, QR bersih, kategori kehadiran, mode scan, menunggu dan absensi tercatat. |
| S05 | Perizinan | Riwayat, jenis izin, individu/kelompok, pencarian anggota, alasan, tanggal, tinjauan, tasrih, selfie kembali dan status akhir. |
| S06 | Daftar ulang | Program, harga dan durasi, atribut, konfirmasi, tagihan aktif, instruksi transfer, status verifikasi dan pembatalan. |
| S07 | Hasil Tes | Periode aktif, rata-rata per usbu, nilai mapel, nihai, data kosong dan hasil yang gagal dimuat. |
| S08 | Riwayat | Program/kelas terdahulu, nilai, kelulusan dan dokumen sesuai hak. |
| S09 | Tauzi’ Fushul | Pilih program tujuan, masuk tes, pengerjaan, hasil tahriri, rincian benar/salah dan jalur kembali. |
| S10 | Nadi Hufadz | Kelayakan/status pendaftaran, konfirmasi daftar, periode, kehadiran, setoran, hasil Tasmi’ dan syahadah. |
| S11 | Tasmi’ | Daftar juz dan tanggal, rentang ayat, catatan, tahfidz/tahsin/tartil/adab dan rata-rata. |
| S12 | Check out | Alasan, tinjau, kirim, status pengajuan, persetujuan dan catatan tiap peran. |
| S13 | WhatsApp AI | Status nomor, nomor tersamarkan, permintaan kode, verifikasi, kesalahan input dan hasil. |
| S14 | Denah Sakan | Lokasi dari API, daftar, keterangan, marker, rute dan izin lokasi. Selaraskan kontrol dengan denah publik. |
| S15 | Galeri | Pemilih periode, daftar album, tanggal, keadaan kosong dan membuka media. |
| S16 | Pemilihan | Lajnah/OSIM sesuai program, sesi dan fase, kandidat, visi/misi, konfirmasi pilihan, suara tercatat dan hasil yang tersedia. |
| S17 | Berita Acara | Pengajar/pertemuan, konfirmasi kehadiran, menit terlambat, catatan dan hasil simpan. |
| S18 | Lapor Mukholif | Cari santri, beberapa pelanggar, pelapor sesuai hak, tanggal/jam, tempat, perkataan, tinjau, kirim serta riwayat. |
| S19 | Eksekusi Iqob | Santri, tugas Sounding/Jawal/Penyetoran yang tersedia, konfirmasi penyelesaian dan status. |
| S20 | Akun | Identitas, NIS, sakan/kamar/lemari, masa belajar, ubah bulan belajar, kartu santri serta logout. |
| S21 | Dokumen · `file_view.dart` | Toolbar PDF/gambar, zoom, simpan salinan/PNG, progres, hasil simpan dan gagal menyimpan. |
| S22 | Pengerjaan · `exam.dart` | Seluruh tipe soal yang sudah didukung, media, rich text, pilihan tunggal/jamak, menjodohkan/kategori, urutan/huruf, isian rumpang, tabel tasrif, identifikasi kesalahan, stabilo syntax, jaring relasi dan jawaban teks. Sertakan waktu, ragu-ragu, antrean jawaban, coba simpan, konfirmasi kirim dan hasil. |

Menu bersyarat mengikuti `allowed` dan hak server. Periksa santri biasa, santri nonaktif, Hufadz, Turats, ketua kelas, Jasus dan Lajnah. Gunakan akun atau fixture yang sah untuk tiap cabang. Verifikasi keadaan akses ditolak serta sesi habis ketika detail atau modal sedang terbuka.

## Semua modal, pemilih dan pesan

| ID | Jenis dan pemanggil | Penerapan |
| --- | --- | --- |
| M01 | Pemberitahuan pengembangan · `coming_soon_dialog.dart` | Dialog putih, pose papan, nama fitur, keterangan pendek dan Tutup. |
| M02 | Pembaruan aplikasi · `home_screen.dart` | Tersedia, mengunduh, gagal dan siap dimuat ulang. Satu pola judul, isi, progres serta tindakan. |
| M03 | Lokasi dan jadwal salat · `home_screen.dart` | Pencarian kota, hasil, kosong, gunakan GPS, izin, tombol batal serta jadwal. Pastikan keyboard memberi ruang hasil. |
| M04 | Unduh Mushaf · `quran_screen.dart` | Memuat/progres, batal, gagal, coba lagi dan selesai mengikuti keadaan proses sebenarnya. |
| M05 | Lompat halaman · `mushaf_viewer_screen.dart` | Input angka, batas halaman, error, Batal dan Pergi. |
| M06 | Ukuran font dan aksi ayat · `surah_detail_screen.dart` | Menu ukuran font, bottom sheet Salin Ayat/Lihat Tafsir, identitas ayat. |
| M07 | Tafsir ayat · `surah_detail_screen.dart` | Sheet panjang, Arab/terjemah, pilih kitab, memuat/gagal, salin dan tutup. |
| M08 | Konfirmasi bersama · `features.dart` | Logout, izin, daftar ulang, pembatalan tagihan, check out, pemilihan, Nadi dan Iqob. Teks tombol menyebut aksi yang akan dilakukan. |
| M09 | Input singkat bersama · `features.dart` | Kode akses ujian, bulan belajar, nomor WA, kode OTP, alasan dan catatan. Keyboard dan validasi sesuai tipe data. |
| M10 | Pemilih bersama · `features.dart` | Jenis izin, individu/kelompok, program, atribut, periode, santri, pengajar serta pilihan lain dari `choose`. |
| M11 | Kelompok izin dan tasrih · `services.dart` | Cari anggota, centang, jumlah pilihan, hasil kosong, detail tasrih dan anggota. |
| M12 | Tanggal dan waktu · `services.dart` | Date picker dan time picker berbahasa Indonesia, header, pilihan, tombol dan mode input sesuai tema. |
| M13 | Hasil Tauzi dan review ujian | Sheet hasil dan breakdown, mapel/soal, benar/salah/belum dinilai, rich text dan scrolling panjang. |
| M14 | Kirim ujian · `exam.dart` | Konfirmasi konsekuensi, Periksa lagi, Kirim ujian, pengiriman berlangsung dan pemulihan gagal. |
| M15 | Ekspor dokumen · `file_view.dart` | Menu salinan/PNG dan semua pesan hasil. Periksa juga toolbar dari paket penampil. |
| M16 | Umpan balik lintas halaman | SnackBar, error input, tooltip, dropdown, hasil salin, permintaan kamera/lokasi, gagal membuka tautan/media, memuat ulang dan hasil simpan. |

Dialog untuk keputusan singkat. Bottom sheet untuk pilihan atau detail ringkas yang dapat digulir. Formulir Perizinan dan Lapor Mukholif yang banyak bidang akan disusun sebagai satu alur formulir dengan pemilih bertingkat yang kembali ke draf. Data dan prasyarat mengikuti kontrak yang ada. Validasi tampil di dekat bidang. Tombol utama mengikuti status pengiriman dan mencegah kirim berulang.

Setiap overlay memakai permukaan putih, tinta gelap, tombol emas berteks arang, fokus yang jelas dan padding aman. Periksa layar 320 dp, teks 200%, keyboard terbuka, tombol kembali, sentuh di luar, drag sheet, dan pemulihan fokus. Saat transaksi berjalan, kebijakan tutup mengikuti kemampuan membatalkan atau melanjutkan proses. Hindari menutup dialog sukses sebelum server memastikan hasilnya. Tampilkan pose maskot hanya ketika membantu menjelaskan keadaan.

## Urutan pelaksanaan dan hasil tiap tahap

Urutan berikut berlaku untuk satu cakupan penuh. Pemeriksaan tiap tahap memberi bukti bahwa komponen siap dipakai tahap berikutnya.

- [x] **Tahap 1 — Aset, inventaris dan baseline.** Salin sumber 10 pose ke aset proyek, catat pemetaan, siapkan gambar runtime dan font. Rekam kondisi awal, versi Flutter, hasil analyze/test, serta semua rute dan titik pembukaan overlay. Periksa status fungsi menu publik. Hasilnya adalah daftar P/S/M yang dapat ditelusuri dan bahan desain yang tersedia secara lokal.
- [x] **Tahap 2 — Fondasi tema.** Terapkan token, ThemeData terang, tipografi, katalog ikon dan gaya kontrol. Bangun komponen yang dipakai ulang untuk kartu fitur, maskot/status, dialog, sheet serta pesan. Hubungkan dulu Beranda, login, Perizinan dan contoh modal ke komponen tersebut. Periksa render empat permukaan itu dan perbaiki kontras, overflow, keyboard serta fokus sebelum melanjutkan.
- [ ] **Tahap 3 — Seluruh area publik.** Selesaikan P01–P12 serta M01–M07. Cocokkan Beranda dengan sampel yang diterima, pastikan pintasan benar, dan periksa cache bacaan, sensor serta media. Gunakan data jadwal dan tanggal nyata pada runtime.
- [ ] **Tahap 4 — Shell dan isi akademik SIAKAD.** Selesaikan login/beranda/tab/katalog/Akun, S01/S02/S07/S08/S10/S11/S20/S21 dan pemilih terkait. Periksa daftar panjang, hak dokumen, riwayat, teks Arab serta perubahan akun.
- [ ] **Tahap 5 — Layanan dan amanah.** Selesaikan S04/S05/S06/S12–S19, semua formulir, tasrih, scan dan M08–M12/M15–M16. Periksa pilih anggota, kamera, status pengajuan, verifikasi, pemilihan dan tugas berbasis peran sampai hasilnya tampak.
- [ ] **Tahap 6 — Ujian akademik dan Tauzi.** Selesaikan S03/S09/S22 serta M13–M14. Uji semua tipe soal, pergantian soal, draf jawaban, sesi aplikasi di latar, putus jaringan, waktu habis, review dan ketentuan hasil. Bandingkan sebelum/sesudah pada data uji yang sama.
- [ ] **Tahap 7 — Audit menyeluruh dan kandidat APK.** Jalankan lint, tes, build dan pemeriksaan perangkat. Ambil bukti tampilan tiap P/S/M sesuai keadaan yang berlaku. Audit warna lama, rich text, keyboard, sheet, tooltip, status bar, kontrol paket serta layar yang jarang dibuka. Perbaiki temuan sampai daftar penerimaan lengkap. Hasil akhirnya kandidat APK untuk pengujian pemilik beserta daftar verifikasi.

## Cara memverifikasi dan menandai selesai

Untuk tiap ID halaman dan overlay, catat status pekerjaan, keadaan yang diuji, peran akun, ukuran layar, hasil, serta lokasi screenshot atau rekaman. Gunakan daftar inventaris dalam dokumen ini sebagai dasar agar menu yang hanya muncul untuk akun tertentu tetap teruji.

- [ ] Periksa memuat, kosong, berisi, gagal dan coba lagi untuk semua halaman berdata. Tambahkan sukses, menunggu, ditolak, sesi habis dan akses ditolak sesuai layanan. Data kosong dan gagal memuat harus menghasilkan pesan serta tindakan yang tepat.
- [ ] Uji lebar 320/360/390/430 dp, perangkat Android nyata, teks 100/150/200%, TalkBack, keyboard, cutout, serta gesture sistem. Periksa kontrol 48 dp dan kontras teks/input/fokus di atas putih maupun emas.
- [ ] Periksa alur publik → login → SIAKAD → Halaman umum → SIAKAD, lalu ulangi setelah logout dan sesi habis. Tes yang sudah ada mencakup NIS berawalan nol, izin menu dan pintasan hasil tes, sehingga semuanya wajib tetap lulus.
- [ ] Periksa jam/lokasi dan lima waktu pada dua beranda, pergantian hari, lokasi bawaan dan izin GPS ditolak. Audit nilai tanggal Hijriah yang saat ini diinisialisasi secara tetap sebelum menampilkannya sebagai tanggal saat ini.
- [ ] Tambahkan tes terarah untuk regresi yang belum dicakup, terutama modal dengan keyboard/teks besar, Formulir Perizinan yang digabung, keadaan status, dan navigasi setelah sesi habis. Pakai fixture untuk uji visual dan akun uji sah untuk verifikasi API. Setiap transaksi pengujian menggunakan data uji.
- [ ] Jalankan `flutter analyze`, `flutter test`, dan build APK melalui toolchain proyek. Bedakan kegagalan baseline dari kegagalan perubahan. Catat langkah yang belum dapat dijalankan beserta sebabnya.
- [ ] Ukur dalam Flutter profile mode pada HP sasaran. Periksa frame build/raster, scroll daftar, buka modal, decode maskot dan ujian. Target panel 60 Hz sekitar 16,7 ms per bingkai. Pembaruan jam dan animasi dekoratif dibatasi pada widget yang perlu berubah. Aset sumber besar disimpan untuk pemeliharaan dan gambar runtime dipilih sesuai kebutuhan tampil.
- [ ] Tinjau semua literal warna/gaya yang tersisa beserta alasan pemakaiannya. Periksa `ColorScheme.primary` yang mungkin dipakai sebagai warna teks pada putih. Semua komponen baru memakai token yang sama.

Pekerjaan tema selesai ketika seluruh halaman, menu yang dapat dicapai, overlay dan keadaan relevan sudah memakai komponen yang disepakati serta memiliki bukti pemeriksaan. Fitur yang belum tersedia memiliki tampilan status yang selesai dan tetap dicatat sebagai pekerjaan fungsi yang terpisah. Hasil akhir mencantumkan bagian yang berhasil diuji, kendala yang masih terbuka dan keputusan teknis yang dibuat selama penerapan.
