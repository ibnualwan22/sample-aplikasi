# Rencana rilis pertama · SIAKAD Markaz Arabiyah

**Acuan visual terkini.** Tema putih–emas #FFCF40, maskot dan ikon berlabel mengikuti [DESIGN.md](../DESIGN.md) serta [rencana penerapan tema](rencana-tema-konsisten.md). Konsep arang di bawah merupakan catatan rancangan awal.

**Status: rancangan, belum diimplementasikan.** Dokumen ini menggantikan pendekatan WebView dalam rencana pengembangan. APK uji dan `siakad-portal.md` yang lama masih menggambarkan implementasi sebelumnya.

**Keputusan:** lanjutkan proyek Flutter `sample-aplikasi`. Beranda publik, Al-Qur'an, kalender dan layanan umum tetap dapat dipakai tanpa akun. SIAKAD adalah ruang santri di dalam aplikasi. Seluruh fitur yang dapat diakses santri di website masuk satu rilis Android, termasuk fitur khusus program dan amanah. Panel petugas/admin tidak termasuk. Urutan kerja di bawah ini adalah urutan pembangunan, bukan pemotongan fitur rilis.

## Pengalaman santri

Dari tab **SIAKAD**, santri yang belum masuk melihat judul **SIAKAD Markaz Arabiyah**, satu kolom **Nomor Induk Santri** dan tombol **Masuk**. Akun dan NIS sama dengan website. Pertahankan NIS sebagai teks (termasuk nol di depan). Tidak ada kolom password, pendaftaran akun baru, atau pemulihan password pada tahap ini. NIS adalah pengenal yang bisa diketahui orang lain; penguatan dengan password ditunda sesuai keputusan pemilik.

Pada halaman login, navigasi bawah masih milik halaman umum. Setelah login berhasil atau saat tab SIAKAD dibuka dengan sesi yang masih berlaku, aplikasi menggantinya dengan **Beranda · Akademik · Layanan · Akun**. Hanya satu bilah bawah yang tampil. **Hasil Tes** dari beranda publik tetap mengingat tujuannya: setelah login langsung ke detail hasil di tab Akademik.

**Kembali ke halaman umum.** Tombol **Halaman umum** (ikon rumah + teks) terlihat di kanan atas beranda SIAKAD. Menekannya membuka Home dengan navigasi publik, tanpa logout. Ketuk tab SIAKAD lagi untuk kembali ke beranda santri selama sesi berlaku. **Keluar akun** terpisah di tab Akun; logout atau sesi habis membersihkan riwayat privat sehingga tombol kembali tidak bisa membuka data santri.

**Beranda setelah login, dari atas ke bawah:**

1. Judul **SIAKAD Markaz Arabiyah**, tombol **Halaman umum**, serta identitas singkat santri.
2. Jam sekarang, lokasi, nama dan waktu salat berikutnya serta hitung mundur. Ketuk ringkasan untuk membuka jadwal lima waktu. Gunakan sumber jam, pilihan lokasi dan perhitungan jadwal yang sama dengan beranda umum; pindah mode tidak meminta izin GPS ulang. Saat GPS ditolak, tampilkan lokasi pilihan atau lokasi bawaan Tulungrejo, Pare dengan keterangan.
3. **Fitur santri** berupa kartu kecil dengan ikon garis dan label singkat. Contoh baris pertama **Nilai · Absensi · Ujian**, disusul **QR Saya · Perizinan · Daftar ulang**. Seluruh fitur lain yang menjadi hak akun dapat dijangkau dari **Semua fitur**, dikelompokkan menurut Akademik, Layanan santri, serta Program dan amanah. Kartu dan tab menuju layar yang sama.
4. Jika ada tindakan yang menunggu, misalnya konfirmasi kembali dari izin, tampilkan satu baris di bawah kartu; tanpa data tidak perlu ruang kosong. Di layar kecil, beranda dapat digulir.

## Kontrak desain

[Lembar desain: Masuk, Beranda dan Perizinan](siakad-native-konsep.svg). Ini contoh komposisi dengan data ilustratif, bukan tangkapan aplikasi yang sudah jadi.

| Keputusan | Aturan penerapan |
|---|---|
| Identitas | Lanjutkan tema Markaz yang sudah ada: latar arang (#121212), permukaan (#1E1E1E), teks terang, aksen emas (#D4AF37). Emas menandai pilihan aktif, fokus dan aksi utama. Kontras isi di atas tombol emas menggunakan teks gelap. |
| Tipografi | Pertahankan Poppins untuk Latin. Pastikan font Arab mendukung harakat dan tersedia saat koneksi putus. Paragraf Arab mengalir kanan ke kiri; nomor, NIS dan tanggal tetap terbaca dalam konteks Indonesia. Judul layar 22–26 sp, isi 15–16 sp sebagai titik awal, mendukung ukuran teks sistem. |
| Ikon | Pakai satu keluarga Material Icons bergaya outline; ikon terisi untuk tab aktif. Contoh: Login → badge, Nilai → description, Absensi → event_available, QR Saya → qr_code, Perizinan → assignment, Pemilihan → how_to_vote. Ikon navigasi disertai teks, tombol ikon saja memiliki label pembaca layar. Tidak memakai emoji/emotikon. |
| Tata letak | Margin HP 20 dp, ritme jarak 4/8 dp, area sentuh minimal 48 dp. Daftar nilai dan riwayat menggunakan baris dan garis pemisah; formulir memakai label tetap di atas kolom. Gunakan satu tombol utama per langkah. Hindari deretan kartu statistik, ornamen kubah berulang, gradasi emas, dan tombol mengambang yang menutup isi. |
| Kartu fitur | Tiga kolom pada HP bila label muat; turunkan ke dua atau satu kolom untuk layar sempit atau teks besar. Seluruh kartu dapat ditekan; gunakan ikon konsisten, label tanpa emoji, dan jarak antarkartu 8 dp. |
| Navigasi | Bilah publik sebelum login dan di mode umum; bilah SIAKAD saat berada di ruang santri. Beranda membuka kartu, Akademik membuka studi/ujian, Layanan memuat administrasi dan amanah, Akun memuat profil dan logout. Perizinan menandai Layanan aktif. Kamera dan pengerjaan ujian dapat memakai layar penuh. |
| Keadaan layar | Bedakan memuat, belum ada data, gagal memuat, sesi habis, akses ditolak, menunggu verifikasi, dan selesai. Contoh: “Belum ada nilai pada periode ini” berbeda dari “Nilai gagal dimuat · Coba lagi”. Status punya teks dan ikon, bukan warna saja. |
| Ukuran perangkat | Uji pada 320–430 dp, teks 200%, keyboard terbuka dan TalkBack. Di tablet, batasi lebar formulir; daftar dan detail boleh berdampingan. Jangan memotong judul Arab atau tombol kirim ketika teks membesar. |

## Peta fitur dan bukti selesai

Cek tindakan di halaman portal, komponen yang dipanggilnya, dan hasil di backend. Nama menu saja tidak cukup untuk menandai fitur selesai.

| Modul | Alur native yang wajib ada | Bukti diterima |
|---|---|---|
| Akun, status dan beranda | Login NIS, profil, kelas/sakan, status aktif, masa belajar, pilih/ubah program dan bulan ke-, kartu digital, logout. | Sesi dapat dipulihkan; akun kedua tidak melihat data akun pertama; kartu milik sendiri dapat dibuka/disimpan. |
| Nilai, Hasil Tes dan Riwayat | Nilai per mapel/periode, hasil per usbu, kelulusan, riwayat, transkrip termasuk gabungan Akbarnas, syahadah saat berhak. | Hasil sesuai website untuk akun dan periode yang sama, termasuk nilai kosong vs nol; dokumen dapat dibaca/disimpan dan mengikuti hak cetak. |
| Absensi dan QR Saya | Rekap dan detail kelas, sakan, kegiatan, ta'birot. Tampilkan QR untuk dipindai petugas, mode scan dan konfirmasi hasil. | Satu pemindaian nyata terlihat di HP; status masih diperbarui bila kanal langsung terputus. Rute lama absen kegiatan mengarah ke QR Saya. |
| Ujian akademik | Paket yang tersedia, mulai/lanjut, seluruh tipe soal dan media yang didukung portal, navigasi soal, waktu server, simpan jawaban, rekap, kirim otomatis/manual, hasil dan review menurut jadwal. | Simulasikan putus koneksi, aplikasi masuk latar, proses ditutup, waktu habis dan respons kirim hilang. Status “tersimpan/terkirim” hanya setelah dikonfirmasi server; aturan skor/pembahasan sama dengan web. |
| Tauzi' Fushul | Dari program tujuan masuk ke sesi tes penempatan, kerjakan soal, simpan sementara, submit dan lihat hasil sesuai aturan Tauzi. | Sesi serta prasyarat Tauzi diuji tersendiri; tombol mengerjakan tidak membuka halaman login website. |
| Perizinan dan tasrih | Pilih jenis izin, alasan dan tanggal; individu/kelompok sesuai kewenangan server. Kirim, lihat tasrih dan riwayat, konfirmasi kembali dengan selfie untuk izin aktif Keluar Pare atau Berhari-hari sesuai aturan website. | Tasrih dan status sesuai server; penolakan izin kamera dapat dipulihkan tanpa mengulang pengajuan. |
| Daftar ulang dan check out | Pilih program/perpanjangan, buat atau lihat tagihan aktif, instruksi transfer, verifikasi, opsi batal/ganti sesuai status. Check out: ajukan dan pantau hasil. | Setelah timeout, cek status sebelum mengulang transaksi. Tagihan dan pengajuan tidak terduplikasi. |
| WhatsApp AI, denah dan galeri | Hubungkan nomor, minta/verifikasi kode. Cari lokasi sakan, lihat denah dan rute. Jelajahi arsip galeri dan buka media. | Kode ini untuk nomor WA, bukan login. Denah tetap bisa dijelajahi jika GPS ditolak. URL Drive/media dan tombol percakapan ditangani sesuai jenis dan hak akses. |
| Nadi Hufadz dan Tasmi' | Pendaftaran Nadi sesuai kelayakan, riwayat setoran, hasil dan dokumen cetak. Riwayat/hasil Tasmi' bagi santri yang berhak. | Status pendaftaran yang sama di web/HP, tulisan Arab benar, hasil/dokumen tidak terbuka lintas akun. |
| Pemilihan Lajnah/OSIM | Sesi, kandidat, surat suara, konfirmasi, kirim dan perkembangan hasil sesuai fase. Menu OSIM untuk Turats mengikuti portal. | Satu hak suara tidak dapat dipakai dua kali, termasuk jika tombol ditekan ulang setelah koneksi terputus. |
| Tugas khusus | Ketua kelas: Berita Acara. Jasus/Lajnah: cari dan laporkan Mukholif sesuai hak. Lajnah: lihat dan selesaikan tugas Eksekusi Iqob. | Akun uji setiap peran menuntaskan tugasnya. Membuka alamat fitur secara langsung tetap ditolak server untuk akun lain. |

**Batas integrasi:** semua langkah milik SIAKAD mempunyai layar Flutter. Untuk dokumen yang saat ini hanya berupa halaman cetak HTML, sediakan data/dokumen terotorisasi dan penampil atau cetak dari HP. Album Drive dengan izin penyedia, penyimpanan berkas oleh Android dan percakapan WhatsApp adalah tindakan eksplisit pengguna. Periksa dukungan pratinjau media/kartu dari penyedia sebelum menjanjikan seluruh isi dapat ditanam. Tidak ada menu SIAKAD yang diam-diam diganti tautan ke website.

## Data, sesi dan bagian yang perlu disiapkan

- Gunakan satu klien API Flutter untuk server SIAKAD. Login memanggil `/api/santri/auth/login`; terima sesi website, simpan rahasia sesi dalam penyimpanan aman perangkat, dan kirim hanya ke server yang ditentukan. Jangan meneruskan cookie ke host media atau PPDB. Tangani 401 (login lagi) terpisah dari 403 (tidak berhak). Kanal sesi Tauzi ikut dibersihkan saat keluar. Pisahkan kontrak login dari layar fitur agar penambahan password nanti cukup mengubah alur masuk dan backend.
- Gunakan kembali `/api/santri/me`, status, perizinan, ujian, QR, pemilihan, dan API modul yang sudah ada. Backend tetap menghitung nilai dan menentukan hak akses. Tata aturan menu dan peran yang sekarang dihitung di layout web menjadi layanan bersama untuk website dan aplikasi; validasi juga pada setiap endpoint. Jangan memberi akses hanya karena tombol tampil.
- Audit bagian yang belum siap dipakai langsung oleh Flutter: hasil ujian yang dibaca halaman server, dokumen cetak, kartu digital dari PPDB, anggota kelompok izin, hak program/peran dan data tindakan di dashboard. Pakai layanan yang sama dan tambah respons JSON/berkas seperlunya. Tidak mengambil data dengan mengurai HTML.
- Periksa biaya `/me` yang membawa banyak riwayat. Muat ringkasan lebih dulu, detail saat dibuka; jangan memanggil data privat dari beranda umum. Asumsi awal: akademik memerlukan internet, sementara jawaban ujian yang belum diterima server ditahan secara aman per akun dan sesi. Hapus antrean setelah konfirmasi atau logout. Tidak ada mode transaksi offline untuk memilih, mengajukan izin atau membuat tagihan.
- Untuk QR, pakai kanal privat dan pemeriksaan status cadangan. Untuk pemilihan, sambungkan pembaruan selama layar aktif. Tutup langganan saat keluar. Uji beban dengan jumlah peserta serentak sebenarnya sebelum rilis; jumlah pengguna dan perangkat terendah belum ditetapkan. Tim SIAKAD memelihara aturan/kontrak server; perubahan kontrak diuji terhadap versi Android yang masih dipakai.

## Urutan pengerjaan dan keputusan rilis

| Tahap | Hasil yang dapat ditinjau |
|---|---|
| 1 · Inventaris dan kontrak | Cocokkan semua rute dan tindakan dengan tabel di atas; catat peran, format respons, aturan dokumen/hasil, dan layanan eksternal. Siapkan akun serta data uji terpisah untuk santri biasa, nonaktif, ketua kelas, Jasus, Lajnah, Hufadz dan Turats. |
| 2 · Fondasi dan desain nyata | Login, sesi, navigasi bawah untuk masing-masing mode, tombol Halaman umum, kartu fitur berbasis peran, jam/jadwal salat bersama, logout dan pintasan Hasil Tes. Periksa tampilan login, beranda dan satu detail di HP dengan data uji sebelum menggandakan pola ke modul lain. |
| 3 · Akademik dan dokumen | Selesaikan profil, program, nilai, absensi, riwayat, dokumen, Tasmi' dan Nadi. Bandingkan angka serta hak cetak dengan portal. |
| 4 · Layanan dan amanah | Perizinan/selfie, QR, daftar ulang, check out, WA, denah, galeri, Berita Acara dan Mukholif/Iqob; uji tindakan dari HP sampai perubahan terlihat di SIAKAD. |
| 5 · Ujian dan pemilihan | Selesaikan ujian akademik, Tauzi dan kedua pemilihan. Eksperimen pemulihan sesi ujian, penyimpanan jawaban dan pengiriman suara dilakukan sejak tahap 2 supaya kendala diketahui dini. |
| 6 · Uji kesetaraan dan Play Store | Tandai setiap baris fitur dengan bukti pengujian akun yang berhak/tidak berhak, perangkat Android nyata, jaringan lambat, dua akun di satu HP dan tampilan aksesibel. Uji AAB bertanda tangan milik Markaz melalui pengujian internal. Lengkapi akses reviewer dan informasi penggunaan data yang sesuai dengan aplikasi. |

**Gerbang rilis:** tidak ada fitur santri yang hanya membuka portal web, tidak ada transaksi penting yang sekadar menampilkan tombol tanpa hasil, dan semua modul di atas sudah lulus uji. Uji alur umum → login → SIAKAD → Halaman umum → SIAKAD (tanpa login ulang), lalu ulangi setelah logout/sesi habis. Periksa bahwa hanya satu bilah bawah aktif, kartu terlihat pada layar awal, serta jam, salat berikutnya dan jadwal lengkap cocok di dua beranda untuk waktu/lokasi yang sama, termasuk saat waktu salat atau tanggal berganti. Periksa lagi daftar rute website saat membekukan versi rilis supaya perubahan selama pengembangan tidak terlewat. Fitur password menyusul oleh pemilik, terpisah dari cakupan ini.

**Rujukan kode untuk pelaksana:** di `ijazah-sample`, lihat `src/components/santri/santri-nav.tsx`, `src/app/santri/(portal)`, `src/app/santri/transkrip`, `src/app/santri/nadi-hufadz/cetak`, `src/app/tauzi`, `src/app/api/santri`, `src/app/api/mobile/hasil-tes` dan `src/app/api/tauzi`. Di `sample-aplikasi`, lihat `lib/main.dart`, `lib/screens/main_layout.dart`, `lib/screens/home_screen.dart` dan layar WebView lama `lib/screens/siakad_portal_screen.dart` yang akan diganti.
