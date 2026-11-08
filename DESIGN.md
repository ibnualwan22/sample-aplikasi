---
name: Markaz Arabiyah
method: RYUX Design Intelligence
basis: TypeUI Clean, disesuaikan untuk Markaz
colors:
  primary: "#FFCF40"
  secondary: "#FFF8DF"
  surface: "#FFFFFF"
  neutral: "#FFFCF3"
  text: "#292A26"
  muted: "#676862"
  divider: "#E8E6DF"
  success: "#346446"
  warning: "#785218"
  danger: "#A1342C"
typography:
  display: "Serif untuk nama Markaz dan jam"
  body-md: "Roboto, sans-serif"
  sourceScale: "12/14/16/20/24/32"
rounded:
  small: 4dp
  control: 12dp
  featureCard: 14dp
  overlay: 20dp
spacing:
  sm: 8px
  md: 16px
  sourceScale: "8pt baseline grid"
---

# Desain mobile Markaz Arabiyah

Panduan ini menerjemahkan permintaan putih–emas ke aplikasi publik dan SIAKAD santri. Pratinjau Beranda dan Perizinan terdahulu mendokumentasikan eksplorasi tema sebelumnya. Tema maskot dan susunan Beranda telah diterima pemilik. Penerapan menyeluruh mengikuti [rencana implementasi](docs/rencana-tema-konsisten.md), termasuk seluruh menu SIAKAD dan modal. Untuk pekerjaan UI, baca panduan ini dari root proyek sebelum membuat atau menyesuaikan layar. Untuk proyek baru, sertakan file ini di root templatnya, lalu sesuaikan nama produk, katalog fitur, dan istilah pengguna.

<!-- ryux-context -->
**Produk dan pengguna.** Aplikasi Flutter Markaz Arabiyah untuk pengunjung yang mencari layanan ibadah dan santri yang menggunakan SIAKAD di ponsel. Bahasa antarmuka Indonesia. Gunakan teks Arab sesuai isi sumber.

**Tugas utama.** Dari Beranda, baca jam dan salat berikutnya sekilas, lalu buka fitur yang dituju dengan sekali sentuh. Dari SIAKAD, temukan layanan sesuai hak akun, selesaikan tindakan, dan periksa hasilnya. Perizinan menjadi contoh alur dari kartu ke riwayat, formulir, tinjauan, dan status.

**Arah yang dipilih.** Maskot dari gambar pemilik menyambut pengguna dan menemani keadaan seperti halaman yang belum tersedia. Antarmuka menggunakan bidang warna solid, dengan dasar putih dan aksen emas utama #FFCF40 sesuai pilihan pemilik. Berikan ruang kosong di sekitar maskot. Sampel Beranda memakai latar gading dengan satu bidang lengkung emas muda di sisi kanan. Tampilkan nama di bawah setiap ikon fitur dan tab navigasi bawah.
<!-- /ryux-context -->

## Dasar keputusan

| Sumber | Yang dapat digunakan |
| --- | --- |
| Foto dan arahan pemilik | Gambar maskot berjempol menjadi acuan wajah, ikat kepala bermotif, pin, busana, dan tulisan Arab. Arahan terbaru menetapkan tema putih–emas solid. |
| [Katalog SIAKAD](lib/siakad/catalog.dart) dan [alur layanan](lib/siakad/services.dart) | Dasar label, hak akses, jenis izin dan tindakan yang tersedia. Data transaksi di contoh visual diberi penanda simulasi. |
| [Panduan RYUX Design Intelligence](https://github.com/ryuxdsgn/design-intelligence/blob/main/GUIDE.md#project-setup-designmd) | Susun keputusan dari tugas pengguna sampai cara mengujinya. Bedakan arahan pemilik, keputusan desain sementara, dan fakta produk. |
| [TypeUI Clean](https://github.com/bergside/awesome-design-skills/blob/main/skills/clean/DESIGN.md) | Pertahankan ritme jarak, skala teks, permukaan putih, dan atribusi dari versi awal. |

## Maskot, warna dan navigasi

Pertahankan tampilan karakter pada gambar pemilik. Pakai putih sebagai bidang baca. Pada [sampel Beranda](docs/beranda-maskot-emas.png), latar sapaan berwarna gading solid (#FFFCF3) dan aksen di belakang maskot berwarna emas muda (#FFCF40). Ikon layanan memakai siluet arang (#292A26) tepat di tengah bidang emas solid (#FFCF40) berukuran 44 × 44 dp dengan radius 12 dp. Jangan menggeser bidang emas ke sudut ikon. Ikon navigasi memakai bentuk yang sama dalam satu warna dengan label di bawahnya. Tempatkan maskot melambai di samping teks “Selamat datang di portal Markaz Arabiyah” dan “Semua layanan dalam genggaman Anda.” Sediakan nama aksesibel dan keterangan tekan lama bagi ikon fitur dan ikon navigasi bawah. Penanda tab aktif memakai bidang emas #FFCF40 dengan ikon dan label arang. Teks di atas bidang emas menggunakan arang #292A26 agar terbaca. Gunakan #FFF8DF sebagai tint emas untuk permukaan pendukung. Sasaran sentuh minimal 48 × 48 dp.

Sampel emas merupakan pratinjau bitmap hasil ImageGen. Saat implementasi gunakan token warna di atas dan aset maskot asli dari pemilik.

### Aset maskot yang disiapkan

Pemilik telah menyediakan 10 pose dalam lima gambar tunggal dan satu lembar lima pose tambahan. Sampel Beranda terakhir memakai pose melambai dari lembar tambahan. Gunakan pemetaan berikut sebagai dasar keadaan utama, lalu catat nama masing-masing aset setelah pemisahan dan pemeriksaan visual.

| Keadaan | Arahan gambar | Konteks di layar |
| --- | --- | --- |
| Selamat datang | Melambaikan satu tangan, wajah tersenyum menghadap pengguna. | Sapaan di Beranda. |
| Fitur belum tersedia | Memegang papan kecil polos di samping badan dengan ekspresi ramah. | Beri keterangan ketersediaan dan jalan kembali. |
| Data kosong | Menengok ke dalam map terbuka yang masih kosong, ekspresi penasaran. | Misalnya riwayat izin pertama. Tawarkan tindakan berikut bila tersedia. |
| Gagal memuat | Telapak tangan terbuka ke arah tindakan, alis sedikit terangkat. | Jelaskan kendala dan tampilkan “Coba lagi” bila sesuai. |
| Berhasil | Gunakan gambar berjempol dari pemilik. | Konfirmasi setelah pengajuan diterima server. |

Siapkan satu aset transparan per pose dengan skala dan posisi dasar yang seragam. Simpan sumber asli dan periksa tepi karakter saat menyiapkan versi runtime. Tempatkan pesan sebagai teks antarmuka agar dapat dibaca pembaca layar. Pertahankan arah tulisan Arab pada baju ketika menyusun komposisi. Saat implementasi, muat aset sesuai layar dan ukuran tampil. Gerak singkat sekali saat muncul bersifat opsional dan mengikuti pengaturan kurangi gerakan.

## Penerapan bersama pada halaman dan modal

Seluruh halaman publik, 19 menu katalog SIAKAD, Akun, ujian, dokumen, serta overlay mengambil warna dan gaya kontrol dari satu tema. Radius kontrol 12 dp, kartu fitur 14 dp dan overlay 20 dp merupakan usulan teknis awal untuk dicocokkan dengan render Flutter. Daftar lengkap, urutan kerja, pemilik komponen dan bukti penerimaan tercantum dalam [rencana tema konsisten](docs/rencana-tema-konsisten.md).

Dialog, bottom sheet, pemilih tanggal/jam, dropdown dan pesan umpan balik memakai permukaan putih, teks arang, serta tombol utama emas berteks arang. Konfirmasi dan input SIAKAD menggunakan `MarkazDialogTitle` dengan penanda ikon emas. Jadwal salat memakai `PrayerScheduleSheet`: lokasi, ringkasan salat berikutnya, navigasi/pemilih tanggal, kembali ke hari ini, baris salat berikutnya berwarna emas, dan bagian waktu pendukung yang dapat dibuka. Pertahankan scrolling pada layar kecil/teks besar; hindari ornamen yang mengganggu pembacaan waktu. Ikon dan label navigasi memiliki gaya yang sama di ruang publik maupun santri. Maskot terutama hadir pada sapaan dan keadaan kosong, pengembangan, gagal atau hasil penting. Formulir panjang diberi ruang vertikal dan tetap dapat diselesaikan saat keyboard terbuka. Gunakan gerakan singkat yang menghormati pengaturan aksesibilitas dan kelancaran HP.

## Implementasi Flutter

Tema produksi berada di `lib/theme/markaz_theme.dart`. Gunakan `MarkazColors` untuk warna, `markazTheme()` untuk Material, serta `FeatureCard`, `FeatureGrid`, `MarkazNavigation`, `WelcomePanel` dan `MarkazState` dari `lib/widgets/markaz_components.dart`. Katalog SIAKAD tetap mengikuti `lib/siakad/catalog.dart` dan hak akses server. Jangan menambah palet per layar atau mengembalikan warna gelap lama.

Font STIX Two Text, Roboto dan Amiri dibundel beserta lisensi di `assets/fonts/`; bacaan tidak perlu mengunduh font. Aset maskot runtime WebP sekitar 780 KB berada di `assets/mascot/`, sementara PNG asli di `docs/mascot-sources/` tidak dimasukkan ke aplikasi. Pose sapaan diambil dari lembar transparan melalui ClipPath; hindari memantulkan tulisan Arab. Pose tunggal yang memiliki latar putih ditempatkan pada permukaan putih.

Kartu memiliki respons tekan 100 ms, transisi halaman 180 ms, serta dukungan kurangi gerakan. Grid menyesuaikan jumlah kolom ketika teks membesar. Pembaruan detik menggunakan `ValueNotifier` pada panel waktu. Formulir Perizinan dan Lapor Mukholif menggunakan satu draf di `ServiceRequestForm`, dengan tinjauan sebelum kirim dan isian dipertahankan saat gagal.

Lihat [bukti penerapan dan batas pengujian](docs/theme-verification/README.md). Gambar dalam folder tersebut adalah render widget Flutter dengan data uji; bukan data santri nyata atau bukti transaksi produksi.

## Suara dan nada

Sebut aksi dan objek langsung, misalnya “Ajukan izin”, “Tinjau pengajuan”, dan “Konfirmasi kembali”. Bedakan “Belum ada izin” dari “Izin gagal dimuat”. Teks “Menunggu persetujuan” baru muncul sesudah server mengakui pengajuan. Sebut data contoh pada pratinjau.

## Isi fitur dan akhir setiap alur

### Arahan SIAKAD terbaru — 8 November 2026

Untuk menu selain Absensi, Nilai dan Riwayat, gunakan tampilan website SIAKAD sebagai acuan utama: susunan informasi, ringkasan, tab, filter, formulir, detail, modal, status dan tindakan. Adaptasikan ke Flutter dan layar HP dengan tema putih–emas solid #FFCF40, tipografi, ikon berlabel dan sasaran sentuh aplikasi. Pertahankan karakter masing-masing fitur; jangan menyederhanakan semuanya menjadi daftar kartu ekspansi yang sama. Arahan ini menggantikan usulan susunan baru untuk menu lain pada diskusi sebelumnya.

Absensi, Nilai dan Riwayat tetap menjadi fokus perbaikan informatif: Absensi menampilkan akumulasi Hadir/Alpa/Izin/Sakit per jenis dan periode, dengan akses ke catatan pembentuk angka; Nilai mendahulukan laporan periode terpilih dan nilai per mata pelajaran; Riwayat menggunakan perjalanan akademik per periode dengan ringkasan yang langsung terlihat. Bedakan sesi dari hari, data belum tercatat dari alpa, dan nilai belum terbit dari nol. Perhitungan, kelulusan dan hak dokumen mengikuti sumber resmi SIAKAD.

Acuan kode website berada pada proyek `ijazah-sample`, terutama `src/app/santri/(portal)` dan `src/components/santri`. Contoh yang telah ditinjau: Perizinan memiliki Riwayat Izin/Buat Izin, pemilih duf’ah dan ringkasan; Tasmi’ memiliki total sesi, juz terakhir dan penilaian per sesi; Daftar ulang menyesuaikan isi dengan status pengajuan/tagihan. Periksa halaman dan komponen terkait sebelum mengadaptasi setiap menu. Peninjauan kode lokal belum merupakan verifikasi tampilan website produksi atau hasil implementasi Flutter.

Urutan pembenahan: Absensi → Nilai → Riwayat, lalu adaptasi menu lainnya dari website termasuk keadaan kosong, gagal, detail dan modalnya. Ketentuan di bagian ini mencatat arah desain, bukan klaim bahwa semua layar telah diperbarui.

| Area | Yang harus bisa dibaca atau dilakukan |
| --- | --- |
| Al-Qur’an, Mushaf, Tafsir | Temukan surah atau halaman, baca teks dan harakat dengan nyaman, kembali ke posisi baca. Beri pemulihan saat halaman gagal dimuat. |
| Jadwal salat, Kiblat, Kalender | Tampilkan lokasi dan hari yang digunakan. Sediakan lokasi bawaan saat izin lokasi ditolak. Bedakan kendala sensor arah dari kendala jaringan. |
| Konten, galeri, Denah Sakan | Tampilkan pratinjau yang membuka konten, lokasi atau rute yang sesuai. Tunjukkan tujuan saat beralih ke layanan eksternal. |
| Login, Akun, kartu santri | Label NIS tetap terlihat saat mengetik. Bedakan kembali ke halaman umum dari keluar akun. Sajikan detail sesuai sesi dan hak akses. |
| Nilai, Hasil Tes, Riwayat, Absensi | Mulai dari periode, kelas, atau jenis absensi yang relevan. Buka rincian dari baris yang dipilih. Bedakan nol dari data yang belum tersedia. Sediakan dokumen bagi santri yang berhak. |
| Ujian dan Tauzi’ Fushul | Bedakan mulai, lanjut, jawaban tersimpan, dan pengiriman akhir. Tampilkan sisa waktu, jawaban yang masih lokal, dan cara melanjutkan sesudah koneksi pulih. |
| QR Saya | Letakkan kode pada bidang putih dengan ruang tepi. Tampilkan mode dan hasil pemindaian yang dapat dikonfirmasi. |
| Perizinan | Urutkan izin yang perlu ditindaklanjuti dan riwayat menurut tanggal. Buka detail untuk alasan, periode, nomor tasrih dan status. Formulir menyatukan jenis, pemohon, alasan dan tanggal. Minta akhir periode untuk izin berhari-hari. Tinjau sebelum kirim. Izin aktif keluar Pare/berhari-hari yang belum memiliki selfie memberi akses konfirmasi kembali. |
| Daftar ulang, Check out, WhatsApp AI | Sajikan satu langkah berikut sesuai status transaksi, pengajuan, atau verifikasi nomor. Pertahankan isian saat gagal. Setelah timeout, periksa status sebelum mengulangi transaksi. |
| Nadi Hufadz, Tasmi’, Pemilihan | Tampilkan sesi, kelayakan, hasil atau dokumen sesuai fase dan hak akun. Minta konfirmasi sebelum mengirim pilihan. |
| Berita Acara, Lapor Mukholif, Eksekusi Iqob, laporan | Tunjukkan objek tindakan, keterangan yang dibutuhkan, dan hasil kiriman. Gunakan hak peran dari server. |

## Pemeriksaan sebelum layar dianggap siap

1. Buka melalui navigasi normal, selesaikan tugas utama, lalu kembali. Periksa tujuan pintasan, tombol kembali, serta urutan fokus.
2. Periksa keadaan memuat, kosong, berisi, gagal, dan coba lagi. Saat relevan, periksa akses ditolak, sesi habis, pengiriman ganda, serta pemulihan setelah kamera atau jaringan gagal. Pesan berhasil mengikuti konfirmasi server.
3. Tinjau pada ponsel selebar 320–430 dp, teks besar, dan keyboard terbuka. Sasaran sentuh, angka, harakat, serta tombol kirim harus dapat dijangkau. Target kontras teks isi 4,5:1 terhadap bidangnya.
4. Gunakan data contoh yang ditandai untuk tinjauan. Simpan identitas, dokumen dan status santri di ruang akun yang berhak. Muat detail saat dibuka. Render latar maskot sebagai bidang solid dan batasi pembaruan jam ke bagian yang berubah.
5. Saat menambah fitur, perbarui tabel alur dan uji tampilan dengan data kosong serta data nyata yang diizinkan. Panduan ini menjadi rujukan visual putih–emas untuk pekerjaan baru, termasuk ketika membaca konsep tema arang yang lebih lama.

## Keputusan sementara dan hal yang perlu diuji

Emas utama telah ditetapkan #FFCF40. Penempatan maskot dan susunan Beranda telah diterima pemilik. Pengenalan ikon oleh santri serta kelancaran pada ponsel sasaran perlu diuji saat implementasi.

<details>
<summary>Atribusi dan lisensi dasar TypeUI Clean</summary>

MIT License

Copyright (c) 2026 Bergside

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

</details>

### Al-Qur’an dan Tafsir

Daftar Al-Qur’an mendahulukan pencarian nama/nomor dan pilihan Surah/Juz. Kartu memakai nomor pada bidang emas, nama Latin, metadata dan nama Arab yang dapat membungkus di layar sempit. Unduhan 604 halaman mushaf memerlukan konfirmasi, dapat dihentikan, dan dapat dicoba ulang dengan melewati halaman yang sudah tersimpan.

Tafsir menyediakan pencarian lokal kata/nama/rujukan `surah:ayat`, pemilih surah–ayat dengan validasi, serta navigasi ayat. Pisahkan ayat Arab lengkap, terjemahan dan tafsir dalam tiga bagian; cuplikan indeks hanya untuk hasil pencarian. Tafsir Kemenag berasal dari endpoint `/tafsir/{surah}`, bukan terjemahan `/surat/{surah}`. Sumber Arab memakai arah kanan-ke-kiri dan font Amiri. Berikan indikator memuat, retry dan perlindungan hasil permintaan lama ketika pilihan berubah. Bacaan Al-Qur’an menampilkan akses Tafsir per ayat dan pemilih surah yang berfungsi. Modal tafsir menggunakan komponen halaman yang sama agar perilaku konsisten.

Kriteria pemeriksaan: pencarian Juz menyaring daftar, rujukan ayat tepat, batas nomor ayat divalidasi, ganti sumber tidak menampilkan respons lama, teks/aksi tetap dapat dibaca dan digulir pada lebar 320 dp dan skala teks 200%. Gunakan warna solid dan kontrol Material, tanpa aset atau efek berat tambahan.
