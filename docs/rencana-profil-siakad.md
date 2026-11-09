# Rencana UI/UX profil SIAKAD

Tanggal: 10 November 2026. **Status: kode profil dan format tanggal telah diimplementasikan; verifikasi render masih terhambat SDK lokal.**

## Tujuan dan acuan

Rapikan tab Akun berdasarkan screenshot pemilik dan implementasi `FeaturePage` saat ini. Pengguna harus dapat mengenali identitasnya, membaca data pribadi/tempat tinggal/masa belajar, serta menemukan kartu santri dan keluar akun dengan mudah. Tema tetap putih–emas solid #FFCF40 dari DESIGN.md. Gunakan ikon Material yang konsisten, tanpa emoji.

Masalah yang teramati: informasi tersebar dengan jarak vertikal berlebihan; label dan isi belum memiliki hierarki yang cukup jelas; tempat/tanggal lahir masih digabung dan tanggal tampil sebagai timestamp ISO; belum ada wadah foto. Pengantar generik “Informasi akun” berulang dengan identitas di bawahnya.

## Susunan layar yang direncanakan

1. **Judul halaman Profil.** Tab bawah tetap berlabel Akun. Pertahankan akses Halaman umum dan navigasi yang sudah berfungsi. Hindari pengulangan judul/pengantar di dalam isi.
2. **Identitas utama.** Wadah foto berbentuk lingkaran 88 × 88 dp, nama lengkap, NIS, dan label status aktif dari server. Pada ukuran normal, foto di kiri dan identitas di kanan; pada layar sempit/teks besar, susun vertikal agar nama tetap lengkap.
3. **Data pribadi.** Tempat lahir, tanggal lahir, dan alamat dalam satu kelompok baris yang rapi.
4. **Tempat tinggal.** Sakan, kamar, dan nomor lemari pada baris terpisah agar mudah ditemukan.
5. **Masa belajar.** Bulan belajar saat ini dan masa aktif/akhir periode berdasarkan data yang tersedia. Aksi Ubah bulan belajar berada di kelompok ini.
6. **Kartu santri.** Baris tindakan dengan ikon kartu, label jelas dan chevron. Gunakan aksi penampil dokumen yang sudah tersedia.
7. **Keluar akun.** Baris tindakan terpisah paling bawah, ikon keluar dan teks warna bahaya yang tenang. Pertahankan dialog konfirmasi dan pembersihan sesi/token yang sudah ada.

## Wadah foto sementara

- Bentuk 1:1, isi gading solid, garis tepi netral tipis, tanpa foto, inisial, maskot, atau ikon orang di dalamnya.
- Belum memiliki tombol kamera, tanda tambah, efek tekan, atau aksi unggah. Wadah ini tidak boleh terlihat seperti tombol yang bisa dipakai sekarang.
- Kelak gambar profil dapat mengisi wadah dengan pemotongan lingkaran tanpa menggeser identitas. Integrasi foto/unggahan/backend berada di tahap berikutnya.
- Tempat kosong bersifat dekoratif pada pembaca layar; nama/NIS tetap dibacakan dari teks identitas.

## Detail visual

- Putih sebagai permukaan utama; emas #FFCF40 digunakan secukupnya pada tindakan/penanda. Teks utama #292A26, label #676862 dan pemisah #E8E6DF.
- Header identitas sederhana dengan ruang yang cukup; tidak memakai gradasi, ilustrasi latar, efek kaca atau bayangan besar.
- Kelompok data berupa permukaan putih dengan batas tipis/radius sekitar 14 dp. Setiap kelompok memuat beberapa baris, bukan satu kartu untuk setiap nilai.
- Margin layar 20 dp, padding kelompok 16 dp, jarak kelompok 16–20 dp. Label 12–13 sp, isi 14–16 sp dan nama 20–24 sp sebagai awal penyesuaian render.
- Label berada di atas nilai agar alamat panjang dan teks besar dapat membungkus secara alami. Pemisah tipis memisahkan baris; jarak internal tidak sebesar jarak antar-kelompok.
- Ikon outline hanya pada judul kelompok dan tindakan: `badge_outlined` untuk data pribadi, `home_outlined` untuk tempat tinggal, `school_outlined` untuk masa belajar, `credit_card_outlined` untuk kartu santri, `logout` untuk keluar. Tidak menambahkan ikon dekoratif pada setiap nilai.
- Tidak menampilkan persentase kelengkapan profil, statistik, atau progres buatan.

## Pemetaan data dan interaksi

| Elemen | Sumber yang sudah digunakan | Perlakuan |
| --- | --- | --- |
| Nama dan NIS | `profile.santri.nama`, `profile.santri.id` | Nama membungkus; NIS tetap string agar nol awal tidak hilang. |
| Status | `profile.santri.isAktif` | Label Aktif/Tidak aktif berdasarkan boolean, dengan teks; nilai tidak tersedia tidak diasumsikan nonaktif. |
| Tempat lahir | `profile.santri.tempatLahir` | Baris tersendiri. |
| Tanggal lahir | `profile.santri.tanggalLahir` | Format `dd-MM-yyyy` (contoh `10-11-2026`); pertahankan tanggal kalender asal tanpa pergeseran zona waktu. Jangan tampilkan timestamp mentah. |
| Alamat | `profile.santri.alamat` | Beberapa baris tanpa pemotongan elipsis. |
| Sakan/kamar/lemari | `profile.santri.sakan`, `kamar`, `nomorLemari` | Tiga label terpisah; data kosong diberi keterangan Belum diisi. |
| Bulan belajar | `profile.santri.bulanKe` | Nilai asli dari server; perubahan memakai endpoint dan hak yang sudah tersedia. |
| Masa aktif | `data.data.masaAktif.berakhirPadaDufahNama` | Tetap mengikuti pemetaan nama periode yang sudah dipakai aplikasi. |
| Kartu santri | Alur pengambilan dan penampil kartu yang ada | Status memuat, gagal dan coba lagi jelas; tidak mengubah sumber atau hak dokumen. |

Data pribadi tetap berupa informasi baca. Hanya tindakan yang memang tersedia memiliki affordance tekan. Dialog Ubah bulan belajar mempertahankan isian, memakai label tetap, validasi angka dan status menyimpan. Sesudah berhasil, nilai di profil dimuat ulang tanpa perlu pindah tab. Dialog keluar menyebut keluar dari akun, terpisah dari navigasi Halaman umum.

## Keadaan dan ukuran layar

- Memuat: indikator singkat dan konsisten; jangan memperlihatkan identitas buatan.
- Data sebagian kosong: masing-masing nilai kosong jelas, sedangkan data lain tetap terlihat.
- Gagal memuat: pesan dan Coba lagi; kegagalan dokumen tidak mengosongkan seluruh profil.
- Layar 320–430 dp dan teks sampai 200%: nama/alamat membungkus, header menumpuk bila perlu, tanpa tinggi kartu tetap yang memotong isi.
- Formulir dan konfirmasi bisa digulir saat keyboard terbuka; sasaran sentuh sedikitnya 48 × 48 dp; aksi terakhir aman dari bilah bawah.
- Gunakan widget/font/ikon lokal; belum ada pemuatan foto atau animasi dekoratif tambahan.

## Urutan implementasi

1. Pisahkan penyusunan halaman Akun ke komponen/view profil khusus; tetap gunakan API, tema dan alur logout yang ada. Titik integrasi saat ini: `lib/siakad/features.dart`, `lib/siakad/feature_views.dart`, dan `lib/screens/siakad_portal_screen.dart`.
2. Ganti pengantar generik dan panel identitas dengan header profil serta wadah foto kosong.
3. Susun baris data per kelompok dan terapkan format tanggal/nilai kosong.
4. Rapikan posisi Kartu santri, Ubah bulan belajar, dan Keluar akun beserta dialognya.
5. Periksa render dengan data contoh: nama panjang, alamat panjang, NIS berawalan nol, tanggal ISO, status/data kosong, serta teks besar. Periksa perubahan bulan dan dialog keluar tanpa melakukan transaksi pada akun nyata.
6. Simpan screenshot profil normal dan teks besar serta dialog terkait. Perbarui status dokumen setelah implementasi dan pemeriksaan selesai.

## Kriteria selesai

- Wadah foto kosong terlihat dan tidak memberi kesan unggah sudah tersedia.
- Data akun tetap lengkap, terkelompok dan mudah dipindai.
- Tidak ada emoji atau tanggal ISO mentah pada layar profil.
- Tidak ada nama/alamat terpotong atau luapan layout pada 320 dp/200% teks.
- Kartu santri, ubah bulan belajar, konfirmasi keluar, dan navigasi Halaman umum tetap berfungsi sesuai alur sebelumnya.
- Screenshot berasal dari UI Flutter dengan data contoh; laporan membedakan implementasi, pengujian widget, dan pengujian perangkat nyata.

## Hasil implementasi 10 November 2026

- View khusus `lib/siakad/profile_view.dart`: wadah foto kosong, identitas responsif, tiga kelompok data, tindakan kartu/keluar, serta dialog bulan belajar dengan validasi, status menyimpan dan isian bertahan saat gagal.
- Format tanggal SIAKAD dan formulir menjadi `dd-MM-yyyy`. Tulisan permintaan `dd-y-mm-yyyy` ditafsirkan sebagai format tanggal tersebut; format transport API tetap ISO. Tanggal kalender pada timestamp dipertahankan tanpa pergeseran zona waktu.
- Pengujian unit formatter lulus (tanggal biasa, timestamp dengan zona waktu, tahun kabisat, data kosong/tidak valid). Analisis berkas implementasi tidak menemukan error/warning, hanya lint info.
- Tes widget profil ditambahkan untuk wadah foto kosong, NIS berawalan nol, tanggal lahir, validasi bulan, kegagalan simpan dan retry; suite responsif yang ada mencakup tab Akun pada 320 dp/200% teks.
- Tes widget/render belum dapat dijalankan: SDK lokal Flutter 3.41.5, sedangkan dependency proyek `paper_curl` membutuhkan >=3.44.0. Mode `--no-pub` juga terhambat dependency Firebase/notifikasi/paper_curl yang belum terpasang. Tidak mengubah dependency untuk melewati kendala ini. Screenshot lama bukan bukti tampilan profil baru. Build APK dan pemeriksaan perangkat belum dilakukan.

### Preview komponen profil

Screenshot terbaru di `docs/theme-verification/profil-preview-{atas,bawah,dialog}.png` berasal dari render Flutter pada 390 × 844 dp dengan data contoh. Komponen `FeaturePage`, `profile_view.dart`, tema, dan dialog disalin tanpa perubahan UI ke harness `/tmp/markaz-profile-preview`. Shell navigasi contoh mengikuti halaman Profil; layanan notifikasi diganti stub di harness saja, tanpa koneksi backend. Pengujian render serta gulir pada 320 dp/200% teks lulus. Ini memverifikasi komponen profil secara terisolasi, bukan build APK atau integrasi seluruh aplikasi. Dependency repo tidak diubah.
